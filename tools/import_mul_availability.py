#!/usr/bin/env python3
"""Sync exact-game variants from the official MUL public static unit/availability index.

The /data/manifest.json bundles are the ones consumed by the official search UI.
Only exact variant names (including known alias suffixes) with identical BV and
tonnage are accepted. Respect origin robots.txt and its 10-second crawl delay.
"""
import datetime as dt
import json
import pathlib
import re
import time
import unicodedata
import urllib.request
import urllib.robotparser
import xml.etree.ElementTree as ET

ROOT=pathlib.Path(__file__).resolve().parents[1]
BASE="https://masterunitlist.battletech.com"
AGENT="BtechMobile-MUL-Snapshot/2.0 (+https://github.com/drag0nblad3/BtechMobile)"
ERAS=["age_of_war","star_league","sw_early","sw_lostech","sw_renaissance",
      "clan_invasion","civil_war","jihad","republic","late_republic","dark_age","ilclan"]
DATA=ROOT/"data/forces/availability.json"
REPORT=ROOT/"docs/mul-import-coverage.json"
ALIASES={
 "wolf-s-dragoons":"wolfs_dragoons",
 "clan-hell-s-horses":"clan_hells_horses",
 "free-worlds-league-duchy-of-andurien":"duchy_of_andurien",
 "free-worlds-league-duchy-of-tamarind-abbey":"duchy_of_tamarind_abbey",
 "free-worlds-league-marik-stewart-commonwealth":"marik_stewart_commonwealth",
 "free-worlds-league-non-aligned-worlds":"non_aligned_worlds",
 "free-worlds-league-oriente-protectorate":"oriente_protectorate",
 "free-worlds-league-regulan-fiefs":"regulan_fiefs",
 "free-worlds-league-rim-commonality":"rim_commonality",
}


def slug(text):
    s=unicodedata.normalize("NFKD",str(text or "")).encode("ascii","ignore").decode("ascii")
    return re.sub("[^a-z0-9]+","-",s.lower().replace("'","")).strip("-")


def catalog():
    results={}
    for folder in ("units","vehicles","battle_armor","assets"):
        for path in (ROOT/"data"/folder).glob("*.json"):
            raw=json.loads(path.read_text())
            for unit in raw.get("configs",[raw]):
                model=str(unit.get("model",raw.get("model","")) or "")
                ident=raw["id"]+"_"+model.lower().replace(" ","_") if "configs" in raw else raw["id"]
                source=unit.get("source",raw.get("source",{}))
                results[ident]={"name":raw["name"],"model":model,
                  "bv":int(unit.get("bv",raw.get("bv",0)) or 0),
                  "ton":float(raw.get("tonnage",0) or 0),"mul_id":source.get("mul_id")}
    return results


def factions_from_source():
    gd=(ROOT/"src/core/forces/era_availability.gd").read_text()
    rows=re.findall(r'\{"id": "([^"]+)", "name": "([^"]+)", "start": \d+, "end": \d+\}',gd)
    if len(rows)!=71:
        raise RuntimeError("Expected 71 registered factions, found %d"%len(rows))
    return {slug(name):ident for ident,name in rows}


class Site:
    def __init__(self):
        self.robots=urllib.robotparser.RobotFileParser()
        self.robots.set_url(BASE+"/robots.txt")
        self.robots.read()
        self.delay=max(10.0,float(self.robots.crawl_delay(AGENT) or
                                  self.robots.crawl_delay("*") or 10.0))
        self.last=None
    def get(self,path,json_mode=True):
        url=BASE+path
        if not self.robots.can_fetch(AGENT,url):
            raise RuntimeError("Robots disallow "+path)
        if self.last is not None:
            time.sleep(max(0.0,self.delay-(time.monotonic()-self.last)))
        self.last=time.monotonic()
        req=urllib.request.Request(url,headers={"User-Agent":AGENT,"Accept":
                     "application/json" if json_mode else "application/xml"})
        with urllib.request.urlopen(req,timeout=65) as r:
            content=r.read(16000000)
        if len(content)>=16000000:
            raise RuntimeError("Truncated source "+path)
        return json.loads(content) if json_mode else content.decode("utf8","replace")


def sitemap(xml):
    tree=ET.fromstring(xml)
    return {e.text.rsplit("/",1)[-1]:e.text
        for e in tree.findall(".//{http://www.sitemaps.org/schemas/sitemap/0.9}loc")
        if e.text and "/units/" in e.text and "?" not in e.text}


def vocab_maps(factions,eras):
    names=factions_from_source()
    fids={}
    missing=[]
    for f in factions:
        ident=ALIASES.get(f["slug"],names.get(f["slug"]))
        if ident is None:missing.append(f["slug"])
        else:fids[int(f["id"])]=ident
    if missing or len(fids)!=71 or len(set(fids.values()))!=71:
        raise RuntimeError("Official faction ids not fully mapped: "+str(missing))
    eids={int(e["id"]):ERAS[int(e["sort"])] for e in eras}
    if len(eids)!=12 or len(set(eids.values()))!=12:
        raise RuntimeError("Official era mapping is incomplete")
    return fids,eids


def find_unit(spec,units):
    expected=slug(spec["name"]+" "+spec["model"])
    candidates=[]
    for u in units:
        title=slug(str(u["n"])+" "+str(u.get("m") or ""))
        score=0 if title==expected else 1 if title.endswith("-"+expected) else 10
        if score>=10:continue
        if spec["bv"] and int(u.get("bv") or 0)!=spec["bv"]:continue
        if spec["ton"] and abs(float(u.get("ton") or 0)-spec["ton"])>0.01:continue
        candidates.append((score,u))
    if not candidates:return None,"no_name_model_bv_tonnage_match"
    best=min(x[0] for x in candidates)
    selected=[u for score,u in candidates if score==best]
    if len(selected)!=1:return None,"ambiguous_%d"%len(selected)
    return selected[0],""


def unit_url(u,urls):
    stem=slug(str(u["n"])+" "+str(u.get("m") or ""))
    if stem in urls:return urls[stem]
    matches=[v for key,v in urls.items() if key.endswith("-"+stem)]
    return matches[0] if len(matches)==1 else None


def matrix(uid,raw,dictionary,known_factions,known_eras):
    entries=raw.get(uid)
    if not entries:return {},"unverified",0
    out={ident:[] for ident in sorted(known_factions.values())}
    positives=0
    for era_id,set_index in entries:
        era=known_eras.get(int(era_id))
        if era is None or set_index<0 or set_index>=len(dictionary):
            raise RuntimeError("Unknown era/dictionary index for "+uid)
        for fac in dictionary[set_index]:
            ident=known_factions.get(int(fac))
            if ident is None:raise RuntimeError("Unknown faction in "+uid)
            if era not in out[ident]:
                out[ident].append(era)
                positives+=1
    for list_ in out.values():list_.sort(key=ERAS.index)
    return out,"published",positives


def main():
    site=Site()
    print("ROBOTS delay",site.delay,flush=True)
    manifest=site.get("/data/manifest.json")
    files=manifest["files"]
    units=site.get("/data/"+files["units"])
    availability=site.get("/data/"+files["availability"])
    factions=site.get("/data/"+files["factions"])
    eras=site.get("/data/"+files["eras"])
    urls=sitemap(site.get("/sitemap.xml",False))
    if min(len(units),len(urls))<8500 or len(availability.get("u",{}))<8000:
        raise RuntimeError("Official source incomplete")
    fids,eids=vocab_maps(factions,eras)
    game=catalog()
    previous=json.loads(DATA.read_text()).get("units",{})
    records={}
    unmatched={}
    positives=0
    published=0
    absent_matrix=[]
    for ident,spec in sorted(game.items()):
        u,why=find_unit(spec,units)
        if u is None:
            unmatched[ident]=why
            continue
        url=unit_url(u,urls)
        if not url:
            unmatched[ident]="canonical_URL_not_in_sitemap"
            continue
        year=int(u.get("iy") or 0)
        if year<=0:
            unmatched[ident]="no_published_intro_year"
            continue
        faction_matrix,status,cells=matrix(str(u["id"]),availability["u"],
                                            availability["d"],fids,eids)
        old=previous.get(ident,{})
        if old.get("verified_at"):
            if int(old["intro_year"])!=year:
                raise RuntimeError("Conflicting page intro year for "+ident)
            for f,eras_prior in old.get("factions",{}).items():
                if set(eras_prior)-set(faction_matrix.get(f,[])):
                    raise RuntimeError("Conflicting official page matrix for "+ident+" "+f)
        if status=="published":published+=1
        else:absent_matrix.append(ident)
        positives+=cells
        records[ident]={"intro_year":year,"mul_id":spec["mul_id"],
              "mul_public_uid":str(u["id"]),"source":url,
              "verified_at":dt.date.today().isoformat(),
              "matrix_status":status,"factions":faction_matrix}
    if len(records)<550 or published<500:
        raise RuntimeError("Unexpectedly low exact-match coverage: %d records, %d matrices"%(
          len(records),published))
    snapshot={"schema":2,"source":BASE+"/",
      "snapshot_date":dt.date.today().isoformat(),
      "manifest_version":manifest.get("version",""),
      "source_files":{k:files[k] for k in ("units","availability","eras","factions")},
      "note":"Official canonical search index, exact variants. Missing cells in a published complete matrix are unavailable; units without a published matrix remain unverified.",
      "units":records}
    report={"date":dt.date.today().isoformat(),
      "source":BASE+"/data/manifest.json",
      "manifest_version":manifest.get("version",""),
      "game_variants":len(game),
      "official_unit_index":len(units),
      "official_available_unit_uids":len(availability["u"]),
      "official_faction_count":len(factions),
      "official_era_count":len(eras),
      "exact_game_variant_matches":len(records),
      "published_matrix_variants":published,
      "matched_with_no_published_matrix":absent_matrix,
      "verified_intro_years":len(records),
      "positive_faction_era_cells":positives,
      "unmatched_variants":unmatched}
    DATA.write_text(json.dumps(snapshot,indent=2,ensure_ascii=False)+"\n")
    REPORT.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    print("RESULT",json.dumps({k:v for k,v in report.items() if k not in
      ("unmatched_variants","matched_with_no_published_matrix")}),flush=True)
    print("UNMATCHED",json.dumps(unmatched)[:3000],flush=True)


if __name__=="__main__":main()
