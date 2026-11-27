#!/usr/bin/env python3
"""Blind-critical chassis-specific resculpt + weapon identity (source and detail).

Reference priorities: current Catalyst plastic miniatures, then official TRO art.
This is a geometry-constrained batch, not a claim of human photographic approval.
All weapon silhouettes are gated against the existing recipe's declared equipment.
"""
import argparse
import json
import math
from pathlib import Path
from pack_voxel_catalog import read_recipe, write_recipe
from vx_blind_identity import paint

REV = "2026-11-22-critical-chassis-identity-geometry-v1"
# name | waist, chest, body depth, head width, snout, shoulder width,
#        left forearm, right forearm, shin mass, toe length | recognition cue.
# Different morphology for every chassis; quads are treated separately.
SPECS = """
akuma|.86 1.19 1.02 .81 .32 1.09 1.14 1.03 .92 1.03|samurai brow; massive torso; broad forward arms
annihilator|.94 1.26 1.13 .80 .10 1.26 1.25 1.27 1.04 1.10|wide quad autocannon towers; compact gunnery head
awesome|.92 1.27 .96 .83 .12 1.24 1.22 1.19 .91 1.04|broad triple PPC fighting chest; small cockpit
banshee|.87 1.14 1.13 1.13 .35 1.14 1.02 1.11 1.11 1.08|forward helmet; broad humanoid shoulders
battleaxe|.88 1.21 .90 .95 .12 1.22 1.23 1.23 .96 1.09|strong paired energy arms; angular shoulders
battlemaster|.81 1.22 1.07 .89 .12 1.18 .91 1.27 1.11 1.09|asymmetric PPC rifle arm; heavy shoulders
black_knight|.86 1.19 .85 .83 .10 1.14 1.05 1.26 .98 1.05|narrow knight helmet; long right PPC
cataphract|.86 1.12 1.13 1.08 .46 1.07 .88 1.28 1.04 1.10|off-center cockpit; mismatched weapons
centurion|.78 1.19 .93 .79 .17 1.10 1.35 1.29 .92 1.10|left shield; massive right autocannon
chameleon|.79 .94 .91 .69 .45 .89 .82 .88 .77 1.07|training scout; narrow head; light jump pack
crab|1.02 1.29 .94 .67 .10 1.33 1.39 1.39 .78 1.14|wide low carapace; paired claw weapons
crockett|.90 1.16 1.03 .84 .25 1.07 1.12 1.16 .96 1.05|shared Crockett Katana family; preserve kinship
crusader|.80 1.12 .94 .70 .30 1.19 1.15 1.13 .90 1.04|LRM-bearing arms; compact central helm
cyclops|.92 1.16 .98 1.10 .38 1.10 .94 1.12 1.07 1.08|large single eye; AC20 torso and LRM
dragon|.82 1.14 1.21 .72 .70 1.13 1.23 .98 .90 1.11|long low sloped cockpit; forward autocannon
falconer|.79 1.07 .83 .76 .72 1.12 .84 1.31 .77 1.02|streamlined cockpit; one large cannon
flashman|.96 1.08 1.28 1.04 .03 1.02 .89 .89 1.18 1.03|domed rounded laser torso
gargoyle|.74 1.32 .89 .62 .71 1.28 1.25 1.11 .71 1.10|wide Clan upper hull; slim fast legs
goliath|1.08 1.39 .92 .56 .21 1.23 .94 .94 1.08 1.18|flat quadrupedal heavy carapace
grasshopper|.74 1.07 .96 .91 .17 1.06 1.08 .98 .79 1.05|tall upright jumper; narrow lower legs
griffin|.82 1.18 .83 .85 .36 1.22 .91 1.23 .84 1.05|off-center shoulder LRM; heavy PPC
guillotine|.79 1.16 .97 .73 .30 1.23 1.10 .93 .83 1.13|compact cockpit; broad jumping shoulders
gunslinger|.87 1.29 .87 .67 .22 1.30 1.21 1.21 .91 1.03|twin long cannon shoulders
hel|.81 1.02 .90 .62 .87 .99 1.39 .78 .81 1.00|forward sensor beak; one long cannon
hellspawn|.78 1.13 1.04 .71 .46 1.15 .83 1.20 .82 1.06|missile-electronics torso; low angular head
hoplite|.91 1.28 .88 .78 .24 1.31 .89 1.37 .93 1.02|heavy asymmetric cannon mount
icarus_ii|.75 1.03 .88 .72 .41 1.04 1.35 .89 .77 1.06|one AC10 arm; slim early medium
javelin|.73 1.04 1.01 .74 .36 1.17 .76 .77 .75 1.12|narrow scout with matched SRM pods
katana|.93 1.16 1.06 .89 .25 1.13 1.12 1.16 .97 1.06|Crockett-related family; do not force difference
kintaro|.89 1.14 1.04 .85 .10 1.25 .99 .97 1.00 1.03|torso SRM racks and flared shoulder blocks
lancelot|.73 1.07 .82 .82 .19 1.02 1.24 1.23 .81 1.08|slender runner; twin laser gun arms
mongoose|.72 .97 .86 .67 .68 .89 .77 .77 .76 1.08|tiny forward scout cockpit
nightstar|.81 1.33 1.13 .74 .38 1.31 1.37 1.37 1.04 1.09|twin long Gauss arms; low head
nova|.68 1.30 .76 .53 .65 1.26 1.36 1.36 .71 1.15|wide Clan PPC arms; narrow legs
orion|.89 1.18 1.09 .93 .15 1.17 1.10 1.19 .94 1.04|stocky chest weapon; offset upper rack
ostwar|.88 1.22 .91 .75 .55 1.36 1.09 1.11 .89 1.08|Ost family cockpit; broad LRM mantle
penetrator|.83 1.21 .84 .68 .31 1.26 1.17 1.17 .74 1.12|wide laser shoulders; slim jumping lower body
pillager|.85 1.28 1.16 .70 .17 1.26 1.38 1.38 1.12 1.10|enormous paired Gauss forearms
quickdraw|.80 1.15 1.08 .89 .27 1.09 .86 1.07 .82 1.02|heavy chest; right asymmetric weapons
sagittaire|.87 1.23 .91 .75 .24 1.25 1.26 1.12 .95 1.07|tall fire-support laser shoulders
scorpion|1.08 1.31 .74 .58 .45 1.24 .88 .88 1.09 1.20|long flat forward quad hull; arthropod legs
sentinel|.79 .92 1.16 .78 .62 .96 .91 1.41 .85 1.05|compact anti-infantry body; one UAC
shogun|.95 1.32 1.12 .78 .14 1.27 1.10 1.14 1.02 1.08|wide assault torso; upper missile rack
spartan|.86 1.08 1.10 1.06 .29 1.08 1.14 .97 1.12 1.05|tall central command canopy
starslayer|.71 1.18 .89 .69 .52 1.15 1.16 .84 .80 1.13|slim jumping torso; offset main gun
stinger|.67 .94 .82 .66 .54 .94 .89 .73 .76 1.16|tiny insectoid scout; one laser arm
stormcrow|.75 1.30 .82 .61 .83 1.29 1.30 1.12 .70 1.08|wide avian Clan prow; thin lower body
tarantula|1.11 1.17 .83 .55 .55 1.20 .83 .83 .78 1.17|compact quad cabin and narrow articulated legs
thanatos|.75 1.35 1.05 .69 .35 1.30 1.40 1.03 .89 1.11|wide low Summoner-derived cockpit; asymmetric gun
thug|.95 1.25 1.15 .86 .28 1.20 1.37 1.37 1.16 1.05|heavy paired PPC forearms; armored legs
trebuchet|.71 1.12 .82 .73 .40 1.17 .83 .83 .75 1.07|two square LRM pods beside narrow cockpit
valkyrie|.68 1.07 .91 .80 .25 1.14 .77 1.13 .77 1.11|light asymmetric missile shoulder and laser arm
victor|.79 1.25 1.08 .92 .31 1.22 .84 1.44 1.12 1.10|one massive right AC20 gun
vindicator|.82 1.05 .90 .66 .33 1.14 .86 1.41 .91 1.04|small helmet; right PPC and left torso LRM
viper|.70 1.26 .77 .62 .78 1.24 1.11 1.09 .69 1.10|narrow fast Clan chassis; broad laser pods
warhawk|.83 1.42 1.04 .57 .38 1.40 1.43 1.43 .92 1.13|very broad four PPC mounts; low helmet
whitworth|.83 1.11 .88 .71 .28 1.26 .88 .88 .84 1.08|paired LRM shoulder pods; narrow arms
ymir|.90 1.11 1.14 .96 .34 1.13 .87 1.29 1.10 1.06|long early assault cockpit; asymmetrical launcher
zeus|.86 1.22 1.12 .93 .41 1.24 1.15 1.32 1.11 1.05|high broad assault chest; one main arm cannon
"""
PROFILES = {}
for line in SPECS.strip().splitlines():
    name, ratios, cue = line.split("|", 2)
    PROFILES[name] = (tuple(float(x) for x in ratios.split()), cue)
assert len(PROFILES) == 59
QUADS = {"goliath", "scorpion", "tarantula"}

# Existing recipe weapon locations only. The installed projectile effects
# follow the new physical barrel mouths. No new rules/loadouts.
SIGNATURES = """
annihilator|barrel la 12 2.2,barrel ra 12 2.2,barrel lt 10 2.1,barrel rt 10 2.1
awesome|barrel lt 8 1.8,barrel rt 8 1.8,barrel ra 10 2.0
banshee|barrel lt 8 2.0
battlemaster|barrel ra 12 2.25
black_knight|barrel ra 10 1.9
cataphract|barrel rt 12 2.1,barrel ra 10 1.8
centurion|barrel ra 15 2.35,shield la 0 0
crusader|rack la 9 2.8,rack ra 9 2.8
cyclops|barrel rt 13 2.6,rack lt 7 3.0
dragon|barrel ra 10 1.85
falconer|barrel ra 13 2.1
gargoyle|barrel la 10 1.8
griffin|rack lt 7 2.8,barrel ra 13 1.9
guillotine|barrel la 10 1.85
hel|barrel la 17 2.3
hoplite|barrel ra 13 2.4
icarus_ii|barrel la 14 2.0
javelin|rack lt 6 2.35,rack rt 6 2.35
kintaro|rack rt 7 2.5
nightstar|barrel la 16 2.35,barrel ra 16 2.35
nova|barrel la 11 2.2,barrel ra 11 2.2
ostwar|rack lt 10 2.7
pillager|barrel la 16 2.25,barrel ra 16 2.25
sagittaire|barrel la 10 1.8
sentinel|barrel la 9 1.75
shogun|rack lt 10 2.5,rack rt 10 2.5
starslayer|barrel ra 10 1.65
stormcrow|barrel la 12 2.1
thanatos|barrel la 13 2.4,rack rt 7 3.0
thug|barrel la 12 2.1,barrel ra 12 2.1
trebuchet|rack la 9 3.0,rack rt 9 3.0
victor|barrel ra 17 2.9
vindicator|barrel ra 16 1.9,rack lt 7 2.8
viper|barrel la 9 1.75
warhawk|barrel la 11 2.1,barrel ra 11 2.1
whitworth|rack lt 8 2.5,rack rt 8 2.5
zeus|barrel la 12 2.0,rack ra 6 3.1
"""
EQUIPMENT = {}
for line in SIGNATURES.strip().splitlines():
    name, value = line.split("|")
    EQUIPMENT[name] = [tuple([a[0], a[1], int(a[2]), float(a[3])])
                       for part in value.split(",") for a in [part.split()]]


def reshape(d, name):
    (waist, chest, depth, head, nose, shoulder, left, right, shin, foot), cue = PROFILES[name]
    changed = 0
    forms = []
    for part in d["parts"]:
        pn = part["name"]
        if part.get("mirror") or pn not in {"ct", "hd", "lt", "rt", "la", "ra", "ll",
                "rl", "ll_shin", "rl_shin", "ll_foot", "rl_foot"}:
            continue
        ct_ys = [float(sec["at"]) for sh in part.get("shapes", [])
                 for sec in sh.get("loft", {}).get("sections", [])
                 if sh["loft"].get("axis", "y") == "y"] if pn == "ct" else []
        ylo = min(ct_ys) if ct_ys else 0.
        yspan = max(1., max(ct_ys) - ylo) if ct_ys else 1.
        for sh in part.get("shapes", []):
            loft = sh.get("loft", {})
            if loft.get("axis", "y") != "y" or not loft.get("sections") or sh.get("mat") in (
                    "glass", "window", "glow", "recess"):
                continue
            sections = loft["sections"]
            lo, span = float(sections[0]["at"]), max(1., float(sections[-1]["at"])-float(sections[0]["at"]))
            for sec in sections:
                yy = float(sec["at"])
                f = (yy-lo)/span
                xx = [v[0] for v in sec["polygon"]]
                zz = [v[1] for v in sec["polygon"]]
                mx, mz = (min(xx)+max(xx))/2, (min(zz)+max(zz))/2
                fx, fz, push = 1., 1., 0.
                if pn == "ct":
                    t = max(0., min(1., ((yy-ylo)/yspan-.28)/.45))
                    fx = waist*(1-t)+chest*t
                    fz = 1+(depth-1)*(.7+.3*math.sin(math.pi*(yy-ylo)/yspan))
                elif pn == "hd":
                    fx, fz, push = head, 1+(depth-1)*.28, nose*(.25+.75*f)
                elif pn in ("lt","rt"):
                    fx, fz = 1+(shoulder-1)*(.32+.68*f), 1+(depth-1)*.28
                elif pn in ("la","ra"):
                    arm = left if pn=="la" else right
                    fx, fz = 1+(arm-1)*(.75-.50*f), 1+(arm-1)*(.22-.08*f)
                elif pn in ("ll","rl","ll_shin","rl_shin"):
                    fx = 1+(shin-1)*(.72 if "shin" in pn else .35)
                    fz = 1+(1-shin)*(.20 if "shin" in pn else .08)
                elif pn in ("ll_foot","rl_foot"):
                    fz=1+(foot-1)*.86
                if name in QUADS and pn not in ("ct","hd","lt","rt"):
                    fx, fz = 1+(fx-1)*.4, 1+(fz-1)*.4
                for v in sec["polygon"]:
                    ox, oz = float(v[0]), float(v[1])
                    nx, nz = mx+(ox-mx)*fx, mz+(oz-mz)*fz
                    if pn=="hd" and oz<mz:
                        nz -= push*min(1., (mz-oz)/max(1., mz-min(zz)))
                    nx, nz = round(nx,5), round(nz,5)
                    if abs(nx-ox)+abs(nz-oz)>.0001:
                        v[:]=[nx,nz]
                        changed+=1
                if pn not in forms:
                    forms.append(pn)
    if changed<8:
        raise ValueError("no major form changed on "+name)
    d["blind_identity_resculpt"] = {"revision": REV, "identity_signature": cue,
        "modified_polygon_vertices": changed, "major_form_targets": forms,
        "review_views": ["front","side","top","rear","three_quarter"],
        "automatic_not_human_approved": True}
    return changed


def octagon(x,y,rx,ry):
    corners=[(-.72,-1),(.72,-1),(1,-.68),(1,.68),(.72,1),(-.72,1),(-1,.68),(-1,-.68)]
    return [[round(x+a*rx,3),round(y+b*ry,3)] for a,b in corners]


def all_part_cells(d):
    parts={}
    for p in d["parts"]:
        cells={(-x-1,y,z) for x,y,z in parts[p["mirror"]]} if p.get("mirror") else set()
        if not p.get("mirror"):
            paint(cells,p.get("shapes",[]))
        paint(cells,p.get("add",[]))
        parts[p["name"]]=cells
    return parts


def front_anchor(cells):
    if not cells:
        raise ValueError("missing existing support")
    cs=list(cells)
    z0=min(v[2] for v in cs)
    depth=max(v[2] for v in cs)-z0
    candidates=[v for v in cs if v[2]<=z0+min(4,max(2,int(depth*.22)))]
    candidates=sorted(candidates,key=lambda v:(v[2],v[0],v[1]))[:300]
    return max(candidates,key=lambda v:(
        sum((v[0]+a,v[1]+b,v[2]+c) in cells
            for a in (-1,0,1) for b in (-1,0,1) for c in (0,1,2))*100-v[2]))


def compatible(d,kind,part):
    if kind=="shield":
        return True  # protective armor, not extra equipment
    loc={"la":"LA","ra":"RA","lt":"LT","rt":"RT"}[part]
    equipped=[w.get("kind","") for w in d.get("weapons",[]) if loc in w.get("locs",[])]
    if kind=="rack":
        return "missile" in equipped
    return any(k in ("cannon","laser") for k in equipped)


def add_equipment(d,name):
    specs=EQUIPMENT.get(name,[])
    if not specs or d.get("blind_identity_weapon_stage")=="2026-11-22-v1":
        return 0
    parts={p["name"]:p for p in d["parts"]}
    cells=all_part_cells(d)
    count=0
    installed=[]
    for kind,pn,length,r in specs:
        if not compatible(d,kind,pn):
            continue
        part=parts[pn]
        x,y,z=front_anchor(cells[pn])
        ops=part.setdefault("add",[]) if part.get("mirror") else part.setdefault("shapes",[])
        if kind=="shield":
            ops.append({"box":[[x-5,y-5,z-2],[x+2,y+6,z+2]],"mat":"plate"})
        else:
            tip=z-length
            if kind=="barrel":
                profile=[(tip,.86,.86),(tip+2,1,1),(z+1,1.19,1.13),(z+3,1.10,1.08)]
            else:
                profile=[(tip,1.25,1.28),(tip+2,1.28,1.25),(z+3,1.10,1.10)]
            sections=[{"at":at,"polygon":octagon(x,y,r*sx,r*sy)} for at,sx,sy in profile]
            ops.append({"loft":{"axis":"z","sections":sections},
                        "mat":"gun" if kind=="barrel" else "plate"})
            if kind=="barrel":
                ops.append({"box":[[x,y,tip],[x,y,tip]],"mat":"recess"})
            else:
                step=max(1,round(r*.48))
                for xx in (x-step,x+step):
                    for yy in (y-step,y+step):
                        ops.append({"box":[[xx,yy,tip],[xx,yy,tip]],"mat":"recess"})
            m=d.setdefault("muzzles",{})
            loc={"la":"LA","ra":"RA","lt":"LT","rt":"RT"}[pn]
            if kind=="barrel" or loc not in m:
                m[loc]=[x,y,tip-1]
        installed.append({"kind":kind,"part":pn,"anchor":[x,y,z]})
        count+=1
    if count:
        d["blind_identity_weapon_stage"]="2026-11-22-v1"
        d["blind_identity_weapon_modules"]=installed
    return count



def remove_zero_length_loft_segments(d):
    """Collapse accidental coincident loft stations in legacy shape/add arms."""
    repaired = 0
    for p in d["parts"]:
        for sh in p.get("shapes", []) + p.get("add", []):
            sections = sh.get("loft", {}).get("sections", [])
            if len(sections) < 2:
                continue
            clean = []
            for sec in sections:
                if clean and sec["at"] == clean[-1]["at"]:
                    left = clean[-1]["polygon"]
                    right = sec["polygon"]
                    if len(left) != len(right):
                        raise ValueError("mismatched coincident contours on " + p["name"])
                    clean[-1]["polygon"] = [
                        [(float(a[0])+float(b[0]))/2,
                         (float(a[1])+float(b[1]))/2]
                        for a,b in zip(left,right)]
                    repaired += 1
                else:
                    clean.append(sec)
            sh["loft"]["sections"] = clean
    return repaired


def validate(d,name):
    names={p["name"] for p in d["parts"]}
    if len(names)!=len(d["parts"]):
        raise ValueError("duplicate part "+name)
    for p in d["parts"]:
        if p.get("parent") and p["parent"] not in names:
            raise ValueError("bad parent "+name+":"+p["name"])
        if p.get("mirror") and p["mirror"] not in names:
            raise ValueError("bad mirror "+name+":"+p["name"])
        for sh in p.get("shapes",[])+p.get("add",[]):
            loft=sh.get("loft",{})
            ss=loft.get("sections")
            if not ss:
                continue
            for a,b in zip(ss,ss[1:]):
                if float(a["at"])>=float(b["at"]) or len(a["polygon"])!=len(b["polygon"]):
                    raise ValueError("invalid loft "+name+":"+p["name"])


def main(root):
    report={"revision":REV,"original_critical_cohort":59,"models":{},
            "limitations":"Chassis-authored geometry edits and nearest-neighbor screening; no complete photographic signoff."}
    for name in sorted(PROFILES):
        row={}
        for suffix,label in (("_shape","coarse"),("","detailed")):
            path=root/"data/voxels"/(name+suffix+".json")
            d=read_recipe(root/"data/voxels",path)
            before={k:json.dumps(d.get(k),sort_keys=True) for k in ("unit","legs","weapons","jets")}
            if d.get("blind_identity_resculpt",{}).get("revision")==REV:
                changed=d["blind_identity_resculpt"]["modified_polygon_vertices"]
            else:
                changed=reshape(d,name)
            modules=add_equipment(d,name)
            remove_zero_length_loft_segments(d)
            validate(d,name)
            for k,v in before.items():
                if json.dumps(d.get(k),sort_keys=True)!=v:
                    raise ValueError("modified official record sheet "+name+":"+k)
            write_recipe(root/"data/voxels",path,d)
            row[label]={"contour_vertices":changed,
                        "weapon_modules":len(d.get("blind_identity_weapon_modules",[]))}
        report["models"][name]=row
    out=root/"docs/graphics/critical-identity-resculpt.json"
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,indent=2)+"\n")
    print("CRITICAL_RESCULPT|models=59|coarse=59|detail=59|vertices=%d|weapon_modules=%d" % (
        sum(x["coarse"]["contour_vertices"] for x in report["models"].values()),
        sum(x["coarse"]["weapon_modules"] for x in report["models"].values())))


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--root",type=Path,default=Path("."))
    main(parser.parse_args().root)
