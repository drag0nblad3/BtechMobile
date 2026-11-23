#!/usr/bin/env python3
"""Catalog fallback official TRO images where no current-plastic photo was matched.

Only a real link present in Sarna's 599-file TRO image index is admitted.
These are legacy illustration references, NOT interchangeable plastic photos.
"""
import argparse
import csv
import html.parser
import json
import pathlib
import re
import urllib.parse
import urllib.request

ROOT = "https://www.sarna.net/files/media/images/product_scans/tro_scans/"
DIRS = ("mech", "vehicle")
SUPPORTED = (".png", ".jpg", ".jpeg", ".gif")
ALIEN = ("agromech", "battlearmor")


def norm(s):
    return re.sub(r"[^a-z0-9]", "", s.casefold())


class Links(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.hrefs = []

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            url = dict(attrs).get("href")
            if url:
                self.hrefs.append(url)


def candidate_files(html, category):
    parser = Links()
    parser.feed(html)
    result = {}
    for href in parser.hrefs:
        url = urllib.parse.urljoin(ROOT + category + "/", href)
        path = urllib.parse.urlparse(url)
        if path.hostname != "www.sarna.net":
            continue
        expected = "/files/info/media/images/product_scans/tro_scans/" + category + "/"
        if expected not in path.path:
            continue
        filename = urllib.parse.unquote(path.path.rsplit("/", 1)[-1])
        if pathlib.Path(filename).suffix.lower() not in SUPPORTED:
            continue
        root = pathlib.Path(filename).stem
        # Ignore secondary art from unrelated protagonists and CCG variants.
        if norm(root):
            result[filename] = url
    return result


def find_art(name, available):
    key = norm(name)
    exact = [file for file in available if norm(
        pathlib.Path(file).stem) == key]
    if exact:
        return sorted(exact, key=lambda s: (not s.endswith(".gif"), s))[0]
    # Admit variant illustration only when a chassis code follows, not another
    # chassis name (e.g. Phoenix cannot borrow Phoenix Hawk artwork).
    suffix = []
    for file in available:
        stem = pathlib.Path(file).stem
        variant = re.fullmatch(r"(.+?)[_-]([a-zA-Z]{2,6}-\d[a-zA-Z0-9-]*)", stem)
        if variant and norm(variant.group(1)) == key:
            suffix.append(file)
    if suffix:
        return sorted(suffix, key=len)[0]
    # e.g. 3025_phoenix_hawk1: published legacy revision, still a provisional lead.
    indexed = [file for file in available if
               re.fullmatch(r"(?:3025|3050)_" +
                            re.escape(name) + r"\d*", pathlib.Path(file).stem,
                            re.IGNORECASE)]
    return sorted(indexed)[0] if indexed else None


def fetch_index(category):
    url = ROOT + category + "/"
    req = urllib.request.Request(url, headers={
        "User-Agent": "BtechMobile-TRO-reference-index/1.0 (metadata only)"})
    with urllib.request.urlopen(req, timeout=30) as handle:
        return candidate_files(handle.read(1_000_000).decode(
            "utf-8", errors="replace"), category)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--scorecard", type=pathlib.Path, required=True)
    parser.add_argument("--plastic", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args()
    plastic = json.loads(args.plastic.read_text(encoding="utf-8"))
    used = {r["model"] for r in plastic["candidates"]}
    with args.scorecard.open(encoding="utf-8", newline="") as file:
        models = [row["model"] for row in csv.DictReader(file)]
    listings = {category: fetch_index(category) for category in DIRS}
    rows, missing = [], []
    for id in models:
        if id in used:
            continue
        category = "vehicle" if id.startswith(("vehicle/", "archetype/")) else "mech"
        if id.startswith("battle_armor/"):
            missing.append(id)
            continue
        key = id.split("/", 1)[-1]
        filename = find_art(key, listings[category])
        if filename is None:
            missing.append(id)
            continue
        source_url = listings[category][filename]
        # Every download target is backed by a verified Sarna directory listing.
        download_url = source_url.replace("/files/info/", "/files/download/", 1)
        rows.append({"model": id, "view": "front",
            "reference_page": source_url, "image_url": download_url,
            "photo_credit": "Official TRO illustration, hosted by Sarna",
            "source_type": "legacy_official_TRO_illustration",
            "image_filename": filename, "white_background_threshold": 192,
            "crop_bottom_fraction": 1.0,
            "pose_description": "Illustration pose, not verified against rig",
            "camera_assessment": "Illustration perspective not yet measured",
            "status": "TRO_IMAGE_LEAD_NEEDS_POSE_CAMERA_AND_MASK_REVIEW",
            "camera_guess": {"yaw_deg": 0.0, "pitch_deg": 0.0,
                "projection": "orthographic", "distance_heights": 4.5},
            "camera_search": {"yaw_offsets": [-25, 0, 25],
                              "pitch_offsets": [-12, 0, 12]}})
    report = {"schema_version": 1, "source_catalogs": [
        ROOT + c + "/" for c in DIRS], "total_visuals": len(models),
        "already_plastic": len(used), "matched_TRO": len(rows),
        "unmatched": missing, "candidates": rows}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n",
                           encoding="utf-8")
    print("TRO_INDEX|visuals=%d|plastic=%d|matched=%d|unmatched=%d" % (
        len(models), len(used), len(rows), len(missing)))
    print("TRO_INDEX_JSON_START")
    print(json.dumps(report, separators=(",", ":")))
    print("TRO_INDEX_JSON_END")


if __name__ == "__main__":
    main()
