#!/usr/bin/env python3
"""Paced exact-variant BattleTech MUL availability snapshot importer.

Only canonical /units/{slug} URLs discovered from the official sitemap are fetched.
Uses robots.txt rules/crawl delay and does not scrape query-string endpoints.
Never infers faction availability from chassis, technology, or other variants.
"""
import argparse
import datetime as dt
import json
import pathlib
import re
import time
import unicodedata
import urllib.parse
import urllib.request
import urllib.robotparser
import xml.etree.ElementTree as ET

from bs4 import BeautifulSoup

ROOT = pathlib.Path(__file__).resolve().parents[1]
HOST = "https://masterunitlist.battletech.com"
AGENT = "BtechMobile-MUL-Research/1.0 (+https://github.com/drag0nblad3/BtechMobile)"
ERAS = [
    "age_of_war", "star_league", "sw_early", "sw_lostech",
    "sw_renaissance", "clan_invasion", "civil_war", "jihad",
    "republic", "late_republic", "dark_age", "ilclan"
]
DATA_PATH = ROOT / "data/forces/availability.json"
REPORT_PATH = ROOT / "docs/mul-import-coverage.json"


def slugify(text):
    text = unicodedata.normalize("NFKD", str(text))
    text = text.encode("ascii", "ignore").decode("ascii")
    text = text.replace("'", "").replace("’", "")
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def fetch(url):
    request = urllib.request.Request(url, headers={
        "User-Agent": AGENT, "Accept": "text/html,application/xml"
    })
    with urllib.request.urlopen(request, timeout=35) as response:
        body = response.read(3_000_000)
        if len(body) >= 3_000_000:
            raise ValueError("Refusing truncated page " + url)
        return body.decode("utf-8", "replace")


def available_urls(xml):
    root = ET.fromstring(xml)
    return {
        loc.text.rsplit("/", 1)[-1]: loc.text
        for loc in root.findall(".//{http://www.sitemaps.org/schemas/sitemap/0.9}loc")
        if loc.text and "/units/" in loc.text and "?" not in loc.text
    }


def load_factions():
    source = (ROOT / "src/core/forces/era_availability.gd").read_text()
    pairs = re.findall(r'\{"id": "([^"]+)", "name": "([^"]+)", "start": \d+, "end": \d+\}', source)
    return {slugify(name): faction for faction, name in pairs}


def game_catalog():
    catalog = {}
    for folder, kind in [("units", "mech"), ("vehicles", "vehicle"),
                          ("battle_armor", "battle_armor"), ("assets", "asset")]:
        path = ROOT / "data" / folder
        for file in path.glob("*.json"):
            data = json.loads(file.read_text())
            if "configs" in data:
                for config in data["configs"]:
                    model = str(config["model"])
                    unit_id = data["id"] + "_" + model.lower().replace(" ", "_")
                    catalog[unit_id] = {
                        "name": data["name"], "model": model, "kind": kind,
                        "bv": config.get("bv"), "mul_id": config.get("source", {}).get("mul_id")
                    }
            else:
                catalog[data["id"]] = {
                    "name": data["name"], "model": data.get("model", ""), "kind": kind,
                    "bv": data.get("bv"), "mul_id": data.get("source", {}).get("mul_id")
                }
    return catalog


def url_for_unit(info, urls):
    name, model = info["name"], info["model"]
    combined = slugify(name + " " + model)
    bare = slugify(name)
    direct = urls.get(combined)
    if direct:
        return direct
    # Alias-prefix pages such as Vulture (Mad Dog) Prime are matched ONLY
    # when the full *name + variant* suffix has a unique sitemap match.
    matches = [u for slug, u in urls.items() if slug.endswith("-" + combined)]
    if len(matches) == 1:
        return matches[0]
    if not model:
        return urls.get(bare)
    return None


def parse_unit_page(url, content, known_factions):
    soup = BeautifulSoup(content, "html.parser")
    canon = soup.select_one('link[rel="canonical"]')
    if not canon or canon.get("href", "").rstrip("/") != url.rstrip("/"):
        raise ValueError("Canonical URL mismatch")
    details = {}
    for row in soup.select("div.u-kv"):
        children = row.find_all("span", recursive=False)
        # The detail grid is alternating span.k and span.v.
        for key in row.select("span.k"):
            val = key.find_next_sibling("span", class_="v")
            if val:
                details[key.get_text(" ", strip=True)] = val.get_text(" ", strip=True)
    match = re.search(r"\b(1\d{3}|2\d{3}|3\d{3})\b", details.get("Intro Year", ""))
    if not match:
        raise ValueError("Missing exact introduction year")
    intro = int(match.group(1))
    table = soup.select_one("table.amx")
    if table is None:
        raise ValueError("Missing faction-era matrix")
    header = table.select("thead tr th")
    if len(header) != 13:
        raise ValueError("Expected 12 official era columns, got %d" % (len(header) - 1))
    mapped, unknown = {}, set()
    for row in table.select("tbody tr"):
        cells = row.find_all("td", recursive=False)
        if len(cells) != 13:
            continue
        link = cells[0].select_one('a[href*="/factions/"]')
        if link is None:
            continue
        slug = urllib.parse.urlsplit(link["href"]).path.split("/")[-1]
        faction = known_factions.get(slug)
        if not faction:
            unknown.add(slug)
            continue
        mapped[faction] = [era for era, cell in zip(ERAS, cells[1:]) if cell.find("a")]
    if not mapped:
        raise ValueError("No recognized faction matrix rows")
    return intro, mapped, sorted(unknown)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--limit", type=int, default=24, help="Maximum new unit-page requests")
    p.add_argument("--delay", type=float, default=10.1,
                   help="Minimum delay between page requests; never below robots crawl-delay")
    args = p.parse_args()
    if args.limit < 1 or args.limit > 100:
        p.error("limit must be 1-100")
    robots = urllib.robotparser.RobotFileParser()
    robots.set_url(HOST + "/robots.txt")
    robots.read()
    crawl = float(robots.crawl_delay(AGENT) or robots.crawl_delay("*") or 10.0)
    delay = max(crawl, args.delay)
    print("ROBOTS crawl delay:", crawl, "requested delay:", delay, flush=True)
    if not robots.can_fetch(AGENT, HOST + "/units/atlas-as7-d"):
        raise RuntimeError("Official MUL robots disallows unit-page collection")
    if not robots.can_fetch(AGENT, HOST + "/sitemap.xml"):
        raise RuntimeError("Official MUL robots disallows sitemap collection")
    urls = available_urls(fetch(HOST + "/sitemap.xml"))
    if len(urls) < 3000:
        raise RuntimeError("Unexpectedly incomplete official unit sitemap: %d" % len(urls))
    catalog = game_catalog()
    faction_map = load_factions()
    existing = json.loads(DATA_PATH.read_text())
    records = existing.get("units", {})
    starters = json.loads((ROOT / "data/forces/starter_formations.json").read_text())["formations"]
    preference = []
    for formation in starters:
        for unit_id in formation["units"]:
            if unit_id not in preference:
                preference.append(unit_id)
    order = preference + [i for i in sorted(catalog) if i not in preference]
    reasons = {}
    matched = {}
    for unit_id in order:
        match = url_for_unit(catalog[unit_id], urls)
        if match:
            matched[unit_id] = match
        else:
            reasons[unit_id] = "no_unique_exact_name_variant_sitemap_match"
    print("CATALOG", len(catalog), "SITEMAP", len(urls),
          "EXACT_MATCHES", len(matched), "UNMATCHED", len(reasons), flush=True)

    count = 0
    results = []
    last_request = None
    for unit_id in order:
        if count >= args.limit:
            break
        if unit_id not in matched:
            continue
        # Refresh previously seeded data, but do not spend requests on
        # already successfully fetched, source-stamped exact variants.
        if records.get(unit_id, {}).get("verified_at") and records[unit_id].get("source") == matched[unit_id]:
            continue
        url = matched[unit_id]
        if not robots.can_fetch(AGENT, url):
            reasons[unit_id] = "blocked_by_robots"
            continue
        if last_request is not None:
            time.sleep(max(0.0, delay - (time.monotonic() - last_request)))
        last_request = time.monotonic()
        count += 1
        try:
            content = fetch(url)
            intro, by_faction, unrecognized = parse_unit_page(url, content, faction_map)
            expected_bv = catalog[unit_id].get("bv")
            title = BeautifulSoup(content, "html.parser").title
            title = title.get_text(" ", strip=True) if title else ""
            if expected_bv and expected_bv > 0:
                details_bv = re.search(r'<span class="k">BV</span>\s*<span class="v">([\d,]+)</span>', content)
                if details_bv and int(details_bv.group(1).replace(",", "")) != int(expected_bv):
                    reasons[unit_id] = "BV differs from game sheet: MUL %s vs game %s" % (
                        details_bv.group(1), expected_bv)
                    print("SKIP", unit_id, reasons[unit_id], flush=True)
                    continue
            if unrecognized:
                print("UNMAPPED FACTIONS", unit_id, unrecognized, flush=True)
            records[unit_id] = {
                "intro_year": intro, "mul_id": catalog[unit_id].get("mul_id"),
                "source": url, "verified_at": dt.date.today().isoformat(),
                "factions": by_faction
            }
            results.append(unit_id)
            print("OK", unit_id, intro, len(by_faction), "faction rows", flush=True)
        except Exception as exc:
            reasons[unit_id] = "fetch_or_parse_failed: " + str(exc)[:160]
            print("SKIP", unit_id, reasons[unit_id], flush=True)

    existing["units"] = dict(sorted(records.items()))
    existing["snapshot_date"] = dt.date.today().isoformat()
    existing["note"] = (
        "Every imported matrix cell is from an exact official MUL unit page. "
        "Rows missing from a unit page are unverified, not negative evidence. "
        "A listed faction with an empty era array has no availability marks."
    )
    DATA_PATH.write_text(json.dumps(existing, ensure_ascii=False, indent=2) + "\n")
    report = {
        "snapshot_date": dt.date.today().isoformat(),
        "source": HOST + "/sitemap.xml",
        "catalog_variants": len(catalog),
        "sitemap_unit_pages": len(urls),
        "exact_sitemap_matches": len(matched),
        "verified_matrix_variants": sum(1 for r in records.values() if r.get("verified_at")),
        "total_records_including_previous_seeds": len(records),
        "requests_this_run": count,
        "successful_imports_this_run": len(results),
        "successful_ids": results,
        "missing_and_skipped": reasons
    }
    REPORT_PATH.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    print("IMPORT REPORT", json.dumps({k:v for k,v in report.items()
          if k not in ["successful_ids","missing_and_skipped"]}), flush=True)


if __name__ == "__main__":
    main()
