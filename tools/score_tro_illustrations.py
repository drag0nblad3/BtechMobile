#!/usr/bin/env python3
"""Measure provisional voxel silhouettes against archived official TRO line art.

Scanned ink artwork has no ground-truth camera or articulations. These masks
and scores are diagnostic only; NEVER mark main scorecard angles as verified.
"""
import argparse
import io
import json
import pathlib
import urllib.parse
import urllib.request
from collections import deque

from PIL import Image, ImageFilter, ImageOps
from score_reference_silhouettes import locate, read_mask, score_masks

ALLOWED = {"www.sarna.net"}
STEPS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def download(url):
    uri = urllib.parse.urlparse(url)
    if uri.scheme != "https" or uri.hostname not in ALLOWED:
        raise ValueError("Unvetted TRO artwork download domain")
    if "/files/download/media/images/product_scans/tro_scans/" not in uri.path:
        raise ValueError("Not an archive-verified TRO image path")
    req = urllib.request.Request(url, headers={"User-Agent":
        "BtechMobile-reference-review/1.0 (noncommercial art QA)"})
    with urllib.request.urlopen(req, timeout=35) as response:
        data = response.read(5_000_001)
    if len(data) > 5_000_000:
        raise ValueError("Artwork size exceeds 5 MB")
    with Image.open(io.BytesIO(data)) as im:
        picture = ImageOps.exif_transpose(im).convert("RGBA")
        white = Image.new("RGBA", picture.size, "white")
        image = Image.alpha_composite(white, picture).convert("L")
    return image


def fill_art_contour(image, max_dimension=700):
    image.thumbnail((max_dimension, max_dimension))
    w, h = image.size
    # Adapt the stroke cutoff to old scanned paper instead of treating the
    # grey page itself as a large, convincing BattleMech.
    border = ([image.getpixel((x, 0)) for x in range(0, w, max(1, w // 24))] +
              [image.getpixel((0, y)) for y in range(0, h, max(1, h // 24))])
    bg = sorted(border)[len(border) // 2]
    cutoff = max(75, min(215, bg - 48))
    ink = image.point(lambda p: 255 if p < cutoff else 0)
    # Small morphological closing patches breaks in the external ink outline.
    closed = ink.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(3))
    black = set()
    pixels = closed.load()
    for y in range(h):
        for x in range(w):
            if pixels[x, y] >= 128:
                black.add((x, y))
    if not black:
        raise ValueError("No legible foreground in TRO illustration")
    # Fill regions of paper enclosed by the outer lines, but not open spaces.
    outside = set()
    queue = deque()
    for x in range(w):
        for point in ((x, 0), (x, h - 1)):
            if point not in black and point not in outside:
                outside.add(point)
                queue.append(point)
    for y in range(h):
        for point in ((0, y), (w - 1, y)):
            if point not in black and point not in outside:
                outside.add(point)
                queue.append(point)
    while queue:
        x, y = queue.popleft()
        for dx, dy in STEPS:
            p = (x + dx, y + dy)
            if 0 <= p[0] < w and 0 <= p[1] < h and p not in black and p not in outside:
                outside.add(p)
                queue.append(p)
    foreground = {(x, y) for y in range(h) for x in range(w)
                  if (x, y) not in outside}
    coverage = len(foreground) / max(1, w * h)
    if not 0.005 < coverage < 0.75:
        raise ValueError("Unreliable artwork segmentation area: %.3f" % coverage)
    mask = Image.new("RGB", (w, h), "white")
    out = mask.load()
    for x, y in foreground:
        out[x, y] = (0, 0, 0)
    return mask, round(coverage, 4)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for field in ("candidates", "models", "sweep", "output"):
        parser.add_argument("--" + field, type=pathlib.Path, required=True)
    args = parser.parse_args()
    records = json.loads(args.candidates.read_text(encoding="utf-8"))["candidates"]
    trials = json.loads(args.sweep.read_text(encoding="utf-8"))["candidates"]
    results = []
    for candidate in records:
        model, angle = candidate["model"], candidate["view"]
        row = {"model": model, "view": angle, "source_url":
               candidate["reference_page"], "art": candidate["image_filename"],
               "result_kind": "EXPLORATORY_LEGACY_TRO_NOT_APPROVED"}
        try:
            image = download(candidate["image_url"])
            foreground, coverage = fill_art_contour(image)
            file = args.output.parent / "masked-TRO" / model / (angle + ".png")
            file.parent.mkdir(parents=True, exist_ok=True)
            foreground.save(file)
            reference = read_mask(file)
            neutral = locate(args.models, model, angle)
            if neutral is None:
                raise ValueError("Missing projected model")
            row["foreground_fraction"] = coverage
            row["initial_0_100"] = score_masks(read_mask(neutral), reference)
            scoped = [x for x in trials if x["model"] == model and x["view"] == angle]
            scored = sorted(((score_masks(read_mask(
                pathlib.Path(x["path"])), reference), x) for x in scoped),
                key=lambda p: p[0], reverse=True)
            if scored:
                row["provisional_camera_fit_0_100"] = scored[0][0]
                row["camera_candidate"] = scored[0][1]["camera"]
            row["review_needed"] = (
                "Manually isolate official line art, exclude annotations, "
                "fit rig pose and verify interpretation of legacy design.")
        except (OSError, ValueError, urllib.error.URLError) as e:
            row["error"] = str(e)
        print("TRO_SCORE_JSON|" + json.dumps(row, sort_keys=True), flush=True)
        results.append(row)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({"approved_scores": 0,
        "candidates": results}, indent=2) + "\n", encoding="utf-8")
    print("TRO_BATCH_SCORE|total=%d|measured=%d" % (
        len(results), sum("provisional_camera_fit_0_100" in r for r in results)))


if __name__ == "__main__":
    main()
