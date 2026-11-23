#!/usr/bin/env python3
"""Index official current Master Unit List art for unpaired Mechs and vehicles.

Use real unit pages, image links and matching page titles; never fabricate art
URLs or interpret a vehicle render as a different BattleMech.
"""
import argparse
import html.parser
import json
import pathlib
import re
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = "https://masterunitlist.battletech.com/units/"
SITE = "masterunitlist.battletech.com"
EXPLICIT = {
    "glass_spider": "galahad-glass-spider",
    "vehicle/bulldog_medium_tank": "bulldog-medium-tank",
    "vehicle/von_luckner_heavy_tank_vnl_k65n": "von-luckner-heavy-tank-vnl-k65n",
    "vehicle/hetzer_wheeled_assault_gun": "hetzer-wheeled-assault-gun",
    "vehicle/lrm_carrier": "lrm-carrier",
    "vehicle/lrm_carrier_c": "lrm-carrier",
    "vehicle/srm_carrier": "srm-carrier",
    "vehicle/srm_carrier_c": "srm-carrier",
    "archetype/lrm_carrier": "lrm-carrier",
    "battle_armor/elemental_ba_laser": "elemental-battle-armor-laser-sqd4",
    "battle_armor/elemental_ba_flamer": "elemental-battle-armor-flamer-sqd4",
    "battle_armor/elemental_ba_mg": "elemental-battle-armor-mg-sqd4",
    "battle_armor/elemental_ba_ap_gauss": "elemental-battle-armor-ap-gauss-sqd4",
    "battle_armor/is_standard_ba_laser": "is-standard-battle-armor-laser-sqd4",
    "battle_armor/is_standard_ba_flamer": "is-standard-battle-armor-flamer-sqd4",
    "battle_armor/is_standard_ba_mg": "is-standard-battle-armor-mg-sqd4",
}
UNOFFICIAL_ARCHETYPES = {
    "artillery_carrier", "attack_vtol", "field_emplacement", "hover_scout",
    "hover_tank", "infantry_jump", "infantry_motorized", "infantry_rifles",
    "missile_emplacement", "savior_repair_vehicle", "tracked_tank",
    "transport_vtol", "wheeled_supply_truck",
}


def normalized(text):
    return re.sub(r"[^a-z0-9]", "", text.casefold())


class Page(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.titling = False
        self.title = ""
        self.art = []

    def handle_starttag(self, tag, attrs):
        attr = dict(attrs)
        if tag == "title":
            self.titling = True
        if tag in ("img", "a"):
            url = attr.get("src", attr.get("href", ""))
            alt = attr.get("alt", "")
            if "/point-backs/unit-art/manual/" in url and (
                    ".webp" in url or ".png" in url):
                self.art.append((url, alt))

    def handle_data(self, data):
        if self.titling:
            self.title += data

    def handle_endtag(self, tag):
        if tag == "title":
            self.titling = False


def candidates_for(model):
    if model.startswith("archetype/") and model.split("/")[1] in UNOFFICIAL_ARCHETYPES:
        return []
    key = model.split("/", 1)[-1]
    out = [EXPLICIT[model]] if model in EXPLICIT else []
    direct = key.replace("_", "-")
    if direct not in out:
        out.append(direct)
    if model.startswith("vehicle/"):
        shortened = re.sub(r"-(?:clan|mk-i|mk-ii|c)$", "", direct)
        if shortened != direct and shortened not in out:
            out.append(shortened)
    # Avoid searching a generic short name that could match other models.
    return out[:3]


def accept_page(markup, model):
    page = Page()
    page.feed(markup)
    title = page.title.split("·", 1)[0].strip()
    if not title or not page.art:
        return None
    key = model.split("/", 1)[-1].replace("_", " ")
    title_n = normalized(title)
    name = normalized(key)
    # The current title must describe the same family, not a misleading
    # similarly named mech. Variant suffixes are allowed but clearly flagged.
    alias = {"glass_spider": "galahadglassspider",
             "elemental_ba_ap_gauss": "elementalbattlear"}.get(
                 model.split("/", 1)[-1])
    if model == "glass_spider":
        equal_family = "galahad" in title_n and "glassspider" in title_n
    elif model.startswith("battle_armor/"):
        group = "elemental" if "elemental" in model else "isstandard"
        weapon = model.rsplit("_", 1)[-1]
        weapon = "apgauss" if model.endswith("ap_gauss") else weapon
        equal_family = group in title_n and weapon in title_n
    elif model.startswith("archetype/"):
        equal_family = name in title_n or (model.endswith("lrm_carrier") and
                                           "lrmcarrier" in title_n)
    elif model.startswith("vehicle/"):
        base = re.sub(r"(?:clan|mki|mkii|c|gal100|vnlk65n)$", "", name)
        equal_family = base in title_n and len(base) >= 7
    else:
        # Compare complete chassis names. A prefix such as Phoenix must NEVER
        # silently accept Phoenix Hawk, nor Locust accept Locust IIC.
        exact = title_n == name
        spoken = key.replace("_", " ")
        suffix = title[len(spoken):] if title.casefold().startswith(
            spoken.casefold()) else ""
        variant = re.match(r"^ [A-Z]{2,6}[-]?[0-9][A-Za-z0-9-]*", suffix)
        equal_family = exact or variant is not None
    if not equal_family:
        return None
    for src, alt in page.art:
        image = urllib.parse.urljoin(ROOT, src)
        url = urllib.parse.urlparse(image)
        if url.scheme == "https" and url.hostname == SITE and (
                "/point-backs/unit-art/manual/" in url.path):
            return {"title": title, "image_url": image,
                    "illustration_label": alt}
    return None


def fetch_page(url):
    req = urllib.request.Request(url, headers={
        "User-Agent": "BtechMobile-official-art-reference/1.0 (QA research)"})
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            return response.read(500_000).decode("utf-8", errors="replace")
    except (urllib.error.URLError, TimeoutError, OSError):
        return ""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--unmatched", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--limit", type=int, default=100)
    args = parser.parse_args()
    ids = json.loads(args.unmatched.read_text(encoding="utf-8"))["unmatched"]
    sources, missed = [], []
    for id in ids[:args.limit]:
        found = None
        attempted = []
        for slug in candidates_for(id):
            url = ROOT + urllib.parse.quote(slug, safe="-")
            attempted.append(url)
            page = fetch_page(url)
            parsed = accept_page(page, id) if page else None
            if parsed:
                found = {"model": id, "view": "front", "reference_page": url,
                    "image_url": parsed["image_url"],
                    "source_type": "official_MUL_illustration",
                    "source_title": parsed["title"],
                    "camera_assessment": "UNVERIFIED_DRAWING_CAMERA",
                    "pose_description": "UNVERIFIED_DRAWING_POSE",
                    "status": "SOURCE_FOUND_POSE_CAMERA_MASK_NOT_APPROVED",
                    "camera_guess": {"yaw_deg": 0.0, "pitch_deg": -7.0,
                        "roll_deg": 0.0, "projection": "orthographic",
                        "distance_heights": 4.5},
                    "camera_search": {"yaw_offsets": [-25, 0, 25],
                        "pitch_offsets": [-10, 0, 10]}}
                break
        if found:
            sources.append(found)
            print("MUL_FOUND|" + id + "|" + found["reference_page"], flush=True)
        else:
            missed.append({"model": id, "tried": attempted})
        if attempted:
            time.sleep(0.2)
    result = {"schema_version": 1, "total_requested": min(
        len(ids), args.limit), "matched": len(sources),
        "unmatched": missed, "candidates": sources}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n",
                           encoding="utf-8")
    print("MUL_INDEX|requested=%d|matched=%d|missing=%d" % (
        result["total_requested"], len(sources), len(missed)), flush=True)
    print("MUL_INDEX_JSON_START")
    print(json.dumps(result, separators=(",", ":")))
    print("MUL_INDEX_JSON_END")


if __name__ == "__main__":
    main()
