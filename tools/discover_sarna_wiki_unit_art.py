#!/usr/bin/env python3
"""Discover BattleTechWiki infobox art for missing silhouette reference models.

Only page-matched infobox file links are admitted; no guesses at image filenames.
A source illustration is not a verified camera, pose or sculpt generation.
"""
import argparse
import html
from html.parser import HTMLParser
import json
import pathlib
import re
import time
import unicodedata
import urllib.parse
import urllib.request
import urllib.error

ROOT = "https://www.sarna.net/wiki/"
IMAGE_HOST = "cfw.sarna.net"
SOURCE_TYPE = "Sarna_infobox_art_generation_unverified"
ALIASES = {
    "alfar": "Alfar",
    "glass_spider": "Glass_Spider",
    "hermes_iii": "Hermes_III",
    "hatamoto_hi": "Hatamoto-Hi",
    "hatamoto_kaze": "Hatamoto-Kaze",
    "hatamoto_ku": "Hatamoto-Ku",
    "hatamoto_mizo": "Hatamoto-Mizo",
    "jagermech_iii": "JagerMech_III",
    "wolf_trap_tora": "Wolf_Trap",
    "von_rohrs_hebi": "Von_Rohrs_(Hebi)",
    "rook_nh1b": "Rook",
    "spider_sdr10k": "Spider",
    "victor_vtrcr": "Victor",
    "vehicle/demolisher_heavy_tank_clan": "Demolisher_Heavy_Tank",
    "vehicle/demolisher_heavy_tank_mk_i": "Demolisher_Heavy_Tank",
    "vehicle/galleon_light_tank_gal_100": "Galleon_Light_Tank",
    "vehicle/lrm_carrier_c": "LRM_Carrier",
    "vehicle/srm_carrier_c": "SRM_Carrier",
    "vehicle/pike_support_vehicle_clan": "Pike_Support_Vehicle",
    "vehicle/von_luckner_heavy_tank_vnl_k65n": "Von_Luckner_Heavy_Tank",
    "battle_armor/elemental_ba_ap_gauss": "Elemental_(Battle_Armor)",
    "battle_armor/elemental_ba_flamer": "Elemental_(Battle_Armor)",
    "battle_armor/elemental_ba_laser": "Elemental_(Battle_Armor)",
    "battle_armor/elemental_ba_mg": "Elemental_(Battle_Armor)",
    "battle_armor/is_standard_ba_flamer": "Standard_Battle_Armor",
    "battle_armor/is_standard_ba_laser": "Standard_Battle_Armor",
    "battle_armor/is_standard_ba_mg": "Standard_Battle_Armor",
}
FAMILY_EXCEPTIONS = {"vehicle/demolisher_heavy_tank_clan",
    "vehicle/demolisher_heavy_tank_mk_i", "vehicle/galleon_light_tank_gal_100",
    "vehicle/lrm_carrier_c", "vehicle/srm_carrier_c",
    "vehicle/pike_support_vehicle_clan",
    "vehicle/von_luckner_heavy_tank_vnl_k65n",
    "wolf_trap_tora", "rook_nh1b", "spider_sdr10k", "victor_vtrcr"}


def normal(value):
    ascii_text = unicodedata.normalize("NFKD", value)
    return re.sub(r"[^a-z0-9]", "", "".join(c for c in ascii_text
        if not unicodedata.combining(c)).lower())


class Infobox(HTMLParser):
    def __init__(self):
        super().__init__()
        self.title = ""
        self.in_title = False
        self.table_depth = 0
        self.in_box = False
        self.art = None
        self.file_href = None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "title":
            self.in_title = True
        if tag == "table":
            if self.in_box:
                self.table_depth += 1
            elif "infobox" in a.get("class", "").split():
                self.in_box = True
                self.table_depth = 1
        if self.in_box and self.art is None:
            if tag == "a" and a.get("href", "").startswith("/wiki/File:"):
                self.file_href = a["href"]
            if tag == "img" and self.file_href:
                self.art = (a.get("src", ""), a.get("alt", ""), self.file_href)

    def handle_data(self, data):
        if self.in_title:
            self.title += data

    def handle_endtag(self, tag):
        if tag == "title":
            self.in_title = False
        if tag == "table" and self.in_box:
            self.table_depth -= 1
            if self.table_depth == 0:
                self.in_box = False


def canonical(model):
    key = model.split("/", 1)[-1]
    return ALIASES.get(model, "_".join(p.capitalize()
        for p in key.split("_")))


def decode_page(page, model):
    parser = Infobox()
    parser.feed(page)
    title = html.unescape(parser.title).split(" - BattleTechWiki")[0].strip()
    if not title or not parser.art:
        return None
    expected = canonical(model).replace("_", " ").replace("(Battle Armor)", "")
    main = re.split(r"\s+\(", title, 1)[0]
    equal_name = normal(main) == normal(expected)
    if model in FAMILY_EXCEPTIONS:
        equal_name = normal(main) in (normal(expected), normal(
            model.split("/", 1)[-1].split("_")[0]))
    if model.startswith("battle_armor/"):
        equal_name = ("elemental" in normal(title) if "elemental" in model
            else "standardbattlearmor" in normal(title))
    if not equal_name:
        return None
    src, alt, link = parser.art
    image = urllib.parse.urljoin(ROOT, src)
    parsed = urllib.parse.urlparse(image)
    if (parsed.scheme != "https" or parsed.hostname != IMAGE_HOST
            or "/wiki/images/" not in parsed.path):
        return None
    filename = urllib.parse.unquote(link.split("/wiki/File:", 1)[-1])
    if normal(filename.split(".", 1)[0]) in ("", "nopic", "none"):
        return None
    # Article titles can be correct while their lead image is a magazine
    # cover, secondary unit or advertisement. Don't use unrelated cover art.
    family = normal(model.split("/", 1)[-1].split("_")[0])
    if model in FAMILY_EXCEPTIONS:
        family = normal(expected.split(" ", 1)[0])
    if model.startswith("battle_armor/"):
        family = "elemental" if "elemental" in model else "standard"
    if len(family) >= 4 and family not in normal(filename):
        return None
    tier = ("modern_Recognition_Guide_illustration" if
        re.search(r"rgilclan|recognition.guide", filename, re.I)
        else SOURCE_TYPE)
    return {"image_url": image, "file_link": "https://www.sarna.net" + link,
        "filename": filename, "title": title, "reference_tier": tier,
        "generation_approved": False}


def fetch(page):
    url = ROOT + urllib.parse.quote(page.replace(" ", "_"), safe="_()-")
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0 (BtechMobile reference provenance audit)"})
    try:
        with urllib.request.urlopen(req, timeout=25) as response:
            return url, response.read(1_000_000).decode("utf-8",
                errors="replace")
    except (urllib.error.URLError, OSError, TimeoutError):
        return url, ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--index", type=pathlib.Path, required=True)
    ap.add_argument("--output", type=pathlib.Path, required=True)
    args = ap.parse_args()
    missing = json.loads(args.index.read_text(
        encoding="utf-8"))["unmatched"]
    results, skipped = [], []
    for model in missing:
        if model.startswith("archetype/"):
            skipped.append({"model": model,
                "reason": "Generic visual archetype has no unique canonical sculpt"})
            continue
        query = canonical(model)
        url, page = fetch(query)
        parsed = decode_page(page, model) if page else None
        if parsed:
            family_only = (model.startswith("battle_armor/") or
                           model in FAMILY_EXCEPTIONS)
            parsed.update({"model": model, "view": "front",
                "reference_page": url, "reference_name": query,
                "source_type": parsed["reference_tier"],
                "status": "FAMILY_ONLY_NOT_AN_EXACT_VARIANT" if family_only
                           else "IMAGE_SOURCE_FOUND_VIEW_NOT_APPROVED",
                "camera_assessment": "UNKNOWN_VIEW_AND_PROJECTION",
                "pose_description": "NO_MATCHED_ARTICULATED_POSE",
                "camera_guess": {"yaw_deg": 0.0, "pitch_deg": -6.0,
                    "projection": "orthographic", "roll_deg": 0.0,
                    "distance_heights": 4.5},
                "camera_projections": ["orthographic", "perspective"],
                "camera_search": {"yaw_offsets": [-25, 0, 25],
                                  "pitch_offsets": [-12, 0, 12]}})
            results.append(parsed)
        else:
            skipped.append({"model": model, "reason":
                "No page with verified matching infobox illustration",
                "tried": url})
        print("SARNA_SOURCE|" + json.dumps({"model": model,
              "found": parsed is not None, "page": url}), flush=True)
        time.sleep(0.15)
    report = {"schema_version": 1, "requested": len(missing),
        "matches": len(results), "unmatched": skipped,
        "candidates": results,
        "qualification": "Not verified silhouette angle, pose, or image generation; family images are not exact chassis variants"}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n",
        encoding="utf-8")
    print("SARNA_SOURCE_SUMMARY|total=%d|found=%d|unmatched=%d" %
        (len(missing), len(results), len(skipped)), flush=True)
    print("SARNA_SOURCE_JSON_START")
    print(json.dumps(report, separators=(",", ":")))
    print("SARNA_SOURCE_JSON_END")


if __name__ == "__main__":
    main()
