#!/usr/bin/env python3
"""Index actual Catalyst plastic photos, without storing any source photographs.

Jaded Falconer's catalog identifies the miniature, manufacturer, box, and image.
An unreviewed near-front photo is NEVER treated as an approved angle or pose.
"""
import argparse
import csv
import html.parser
import json
import pathlib
import re
import urllib.parse
import urllib.request

GALLERY = "https://jadedfalconer.com/Pages/6How/miniatures"
HOST = "jadedfalconer.com"
ALIASES = {"madcat": "timberwolf", "thor": "summoner",
           "loki": "hellbringer", "blackhawk": "nova",
           "arcticcheetahhankyu": "arcticcheetah",
           "stonerhinobehemoth": "stonerhino",
           "blackpythonviper": "blackpython",
           "direwolfdaishi": "direwolf",
           "conjurerhellhound": "conjurer",
           "mistlynxkoshi": "mistlynx"}


def normalized(name):
    text = re.sub(r"[^a-z0-9]", "", name.casefold())
    return ALIASES.get(text, text)


class TableReader(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.rows = []
        self.row = None
        self.cell = None

    def handle_starttag(self, tag, attrs):
        if tag == "tr":
            self.row = []
        if tag in ("td", "th") and self.row is not None:
            self.cell = {"text": "", "links": []}
        if tag == "a" and self.cell is not None:
            link = dict(attrs).get("href", "")
            if link:
                self.cell["links"].append(link)

    def handle_data(self, data):
        if self.cell is not None:
            self.cell["text"] += data

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self.cell is not None:
            self.cell["text"] = " ".join(self.cell["text"].split())
            self.row.append(self.cell)
            self.cell = None
        elif tag == "tr" and self.row is not None:
            self.rows.append(self.row)
            self.row = None


def discover(html, models):
    parser = TableReader()
    parser.feed(html)
    choices = {}
    for cells in parser.rows:
        if len(cells) < 7:
            continue
        name, unit_type = cells[0]["text"], cells[3]["text"]
        if "mech" not in unit_type.casefold():
            continue
        key = normalized(name)
        if not key or key not in models:
            continue
        images = [urllib.parse.urljoin(GALLERY, href)
                  for c in cells[6:] for href in c["links"]
                  if re.search(r"\.(?:jpg|jpeg|png)(?:[?#]|$)", href, re.I)]
        images = [url for url in images if
                  urllib.parse.urlparse(url).hostname == HOST
                  and "/Pictures/CGLminis/" in url]
        if not images:
            continue
        row = {"model": models[key], "view": "front",
               "reference_page": GALLERY, "image_url": images[0],
               "photo_credit": "Jaded Falconer miniature photo catalog",
               "source_type": "modern_CGL_plastic_photo",
               "miniature_name": name, "base_number": cells[1]["text"],
               "sculpt_variant": cells[2]["text"],
               "source_pack": cells[4]["text"],
               "white_background_threshold": 235,
               "crop_bottom_fraction": 0.95,
               "exclude_dark_base_below": {"start_y_fraction": 0.78,
                                            "min_channel_mean": 68},
               "camera_assessment": "Unverified front/quarter photographed angle",
               "pose_description": "Unverified physical miniature stance",
               "status": "DISCOVERED_PHOTO_NEEDS_POSE_CAMERA_MASK_REVIEW",
               "camera_search": {"yaw_offsets": [-15, 0, 15],
                                 "pitch_offsets": [-12, 0, 12]}}
        # Favor the first published plastic sculpt, avoiding variant duplicates.
        choices.setdefault(key, row)
    return sorted(choices.values(), key=lambda x: x["model"])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scorecard", type=pathlib.Path, required=True)
    ap.add_argument("--output", type=pathlib.Path, required=True)
    ap.add_argument("--html", type=pathlib.Path)
    args = ap.parse_args()
    with args.scorecard.open(encoding="utf-8", newline="") as file:
        ids = [row["model"] for row in csv.DictReader(file)
               if "/" not in row["model"]]
    aliases = {normalized(name): name for name in ids}
    if args.html:
        html = args.html.read_text(encoding="utf-8")
    else:
        request = urllib.request.Request(GALLERY, headers={
            "User-Agent": "BtechMobile-reference-index/1.0 (source citations only)"})
        with urllib.request.urlopen(request, timeout=30) as response:
            html = response.read(5_000_000).decode("utf-8", errors="replace")
    candidates = discover(html, aliases)
    report = {"schema_version": 2,
              "purpose": "Unverified cataloged plastic photo leads; no approved pose/angle/masks",
              "source_catalog": GALLERY, "total_mechs": len(ids),
              "matched": len(candidates),
              "missing_model_ids": sorted(set(ids) -
                                          {r["model"] for r in candidates}),
              "candidates": candidates}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("REFERENCE_INDEX|mechs=%d|matched=%d|missing=%d" % (
        len(ids), len(candidates), len(report["missing_model_ids"])))
    print("REFERENCE_INDEX_JSON_START")
    print(json.dumps(report, separators=(",", ":")))
    print("REFERENCE_INDEX_JSON_END")


if __name__ == "__main__":
    main()
