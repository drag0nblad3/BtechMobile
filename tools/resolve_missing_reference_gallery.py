#!/usr/bin/env python3
"""Resolve named Sarna gallery files to real thumbnail URLs, without guessing paths.

Discovery metadata and scoring candidates only: no source artwork is committed.
Only an image explicitly linked on the documented chassis article is accepted.
"""
import argparse
import html.parser
import json
import pathlib
import urllib.parse
import urllib.request

HOSTS = {"www.sarna.net", "cfw.sarna.net"}
PHOTO_SUFFIXES = (".jpg", ".jpeg", ".png", ".gif")


def normalize(value):
    return str(value).casefold().replace("_", " ").replace("-", " ").strip()


def image_name(url):
    path = urllib.parse.unquote(urllib.parse.urlparse(url).path)
    if "/wiki/images/thumb/" in path:
        parts = path.split("/wiki/images/thumb/", 1)[1].split("/")
        return parts[2] if len(parts) > 2 else ""
    if "/wiki/images/" in path:
        parts = path.split("/wiki/images/", 1)[1].split("/")
        return parts[2] if len(parts) > 2 else ""
    return ""


def permitted_image(url):
    value = urllib.parse.urlparse(url)
    return (value.scheme == "https" and value.hostname in HOSTS
            and "/wiki/images/" in value.path
            and value.path.lower().endswith(PHOTO_SUFFIXES))


class GalleryImages(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.anchors = []
        self.images = {}

    def handle_starttag(self, tag, attrs):
        props = dict(attrs)
        if tag == "a":
            self.anchors.append(props.get("href", ""))
        elif tag == "img":
            url = props.get("data-src") or props.get("src") or ""
            url = urllib.parse.urljoin("https://www.sarna.net/", url)
            if not permitted_image(url):
                return
            name = image_name(url)
            if name:
                self.images.setdefault(name, url)

    def handle_endtag(self, tag):
        if tag == "a" and self.anchors:
            self.anchors.pop()


def fetch_gallery(page):
    parsed = urllib.parse.urlparse(page)
    if parsed.scheme != "https" or parsed.hostname != "www.sarna.net":
        raise ValueError("Unapproved gallery host")
    if not parsed.path.startswith("/wiki/"):
        raise ValueError("Not an approved Sarna wiki article")
    req = urllib.request.Request(page, headers={
        "User-Agent": "BtechMobile-Reference-Discovery/1.0 (metadata only)"})
    with urllib.request.urlopen(req, timeout=40) as handle:
        source = handle.read(2_000_001)
    if len(source) > 2_000_000:
        raise ValueError("Oversized article")
    parser = GalleryImages()
    parser.feed(source.decode("utf-8", errors="replace"))
    return parser.images


def select_image(images, expected):
    if not expected:
        return None
    equal = [url for filename, url in images.items()
             if normalize(filename) == normalize(expected)]
    return equal[0] if len(equal) == 1 else None


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--leads", type=pathlib.Path, required=True)
    ap.add_argument("--output", type=pathlib.Path, required=True)
    args = ap.parse_args()
    leads = json.loads(args.leads.read_text(encoding="utf-8"))
    candidates, unresolved = [], []
    cache = {}
    for entry in leads["sources"]:
        row = dict(entry)
        page, expected = row["reference_page"], row.get("expected_filename")
        try:
            if page not in cache:
                cache[page] = fetch_gallery(page)
            images = cache[page]
            selected = select_image(images, expected)
            row["gallery_image_count"] = len(images)
            row["gallery_matching_file_found"] = selected is not None
            if selected:
                row["image_url"] = selected
                row["filename"] = expected
                row["source_type"] = "Sarna_gallery_" + row["match_class"]
                row["status"] = ("IMAGE_FOUND_VIEW_POSE_AND_MASK_UNVERIFIED"
                    if row["match_class"] in ("exact_variant", "exact_chassis")
                    else "SIBLING_OR_NONCANON_SOURCE_NOT_EXACT")
                row["camera_assessment"] = "GALLERY_IMAGE_CAMERA_NOT_CALIBRATED"
                row["pose_description"] = "GALLERY_POSE_NOT_FITTED"
                candidates.append(row)
            else:
                # Image filenames are leads for manual reconciliation, not proof.
                row["gallery_image_names"] = sorted(images)[:75]
                unresolved.append(row)
                print("REVIEW_GALLERY|" + json.dumps({
                    "model": row["model"], "files": row["gallery_image_names"]},
                    sort_keys=True), flush=True)
        except (OSError, ValueError) as exc:
            row["error"] = str(exc)
            unresolved.append(row)
        print("REFERENCE_DISCOVERED|" + json.dumps({
            "model": row["model"], "matched": "image_url" in row,
            "filename": row.get("filename"), "image_url": row.get("image_url"),
            "match_class": row["match_class"], "error": row.get("error")},
            sort_keys=True), flush=True)
    result = {"schema_version": 1, "status": "EXPLORATORY_IMAGES_ONLY",
              "candidates": candidates, "unresolved": unresolved}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print("REFERENCE_DISCOVERY|matched=%d|unresolved=%d" %
          (len(candidates), len(unresolved)), flush=True)


if __name__ == "__main__":
    main()
