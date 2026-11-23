#!/usr/bin/env python3
"""Download vetted candidate photos temporarily; measure PROVISIONAL masks only.

Raw photographs are not stored in Git or output artifacts. Generated contour
masks and provisional metrics are NOT approved reference-fidelity scores.
"""
import argparse
import io
import json
import pathlib
import urllib.parse
import urllib.request
from collections import deque

from PIL import Image, ImageOps

from score_reference_silhouettes import locate, read_mask, score_masks

ALLOWED_HOSTS = {"store.catalystgamelabs.com", "www.wargamesemporium.co.uk"}
OFFSETS = ((0, 1), (1, 0), (0, -1), (-1, 0))


def fetch_photo(url):
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "https" or parsed.hostname not in ALLOWED_HOSTS:
        raise ValueError("External photo URL host not explicitly approved")
    request = urllib.request.Request(url, headers={
        "User-Agent": "BtechMobile-silhouette-audit/1.0 (noncommercial QA)"})
    with urllib.request.urlopen(request, timeout=25) as response:
        raw = response.read(8_000_001)
    if len(raw) > 8_000_000:
        raise ValueError("Reference photograph exceeds 8 MB")
    with Image.open(io.BytesIO(raw)) as image:
        color = ImageOps.exif_transpose(image).convert("RGBA")
        # Shopify product PNGs are sometimes transparent; composite on white,
        # never treat the previewer's black transparency as foreground.
        background = Image.new("RGBA", color.size, (255, 255, 255, 255))
        return Image.alpha_composite(background, color).convert("RGB")


def remove_noise(pixels, w, h):
    occupied = set(pixels)
    seen = set()
    cleaned = set()
    for start in occupied:
        if start in seen:
            continue
        queue = deque([start])
        seen.add(start)
        component = []
        while queue:
            x, y = queue.popleft()
            component.append((x, y))
            for dx, dy in OFFSETS:
                near = (x + dx, y + dy)
                if near in occupied and near not in seen:
                    seen.add(near)
                    queue.append(near)
        if len(component) >= 8:
            cleaned.update(component)
    return cleaned


def prepare_mask(photo, threshold=232, crop_bottom_fraction=1.0):
    image = photo.copy()
    image.thumbnail((700, 700))
    w, h = image.size
    pix = image.load()
    bottom = int(h * float(crop_bottom_fraction))
    bg = pix[0, 0]
    dark_background = sum(bg) < 150
    occupied = {(x, y) for y in range(bottom) for x in range(w)
                if (sum(pix[x, y]) > 3 * (255 - int(threshold))
                    if dark_background else
                    sum(pix[x, y]) < 3 * int(threshold))}
    occupied = remove_noise(occupied, w, h)
    if not (0.008 <= len(occupied) / (w * h) <= 0.7):
        raise ValueError("Subject segmentation fraction is implausible")
    out = Image.new("RGB", (w, h), "white")
    outpix = out.load()
    for x, y in occupied:
        outpix[x, y] = (0, 0, 0)
    return out, len(occupied) / (w * h)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for key in ("candidates", "models", "output"):
        parser.add_argument("--" + key, type=pathlib.Path, required=True)
    parser.add_argument("--sweep", type=pathlib.Path)
    args = parser.parse_args()
    registry = json.loads(args.candidates.read_text(encoding="utf-8"))
    camera_trials = []
    if args.sweep and args.sweep.is_file():
        camera_trials = json.loads(args.sweep.read_text(
            encoding="utf-8")).get("candidates", [])
    out = []
    masks = args.output.parent / "reference-masks"
    for entry in registry["candidates"]:
        model, view = entry["model"], entry["view"]
        row = {"model": model, "view": view, "source_url": entry["reference_page"],
               "result_kind": "EXPLORATORY_UNVERIFIED_POSE_CAMERA_AND_MASK",
               "source_type": entry["source_type"], "score_0_100": None}
        try:
            photo = fetch_photo(entry["image_url"])
            mask, share = prepare_mask(
                photo, entry["white_background_threshold"],
                entry["crop_bottom_fraction"])
            out_file = masks / model / (view + ".png")
            out_file.parent.mkdir(parents=True, exist_ok=True)
            mask.save(out_file)
            row["foreground_fraction"] = round(share, 3)
            model_file = locate(args.models, model, view)
            if model_file is None:
                raise ValueError("No pose-matched model silhouette exported")
            reference = read_mask(out_file)
            row["score_0_100"] = score_masks(read_mask(model_file), reference)
            trials = [t for t in camera_trials
                      if t["model"] == model and t["view"] == view]
            ranked = []
            for trial in trials:
                trial_score = score_masks(read_mask(
                    pathlib.Path(trial["path"])), reference)
                ranked.append((trial_score, trial))
            if ranked:
                # Only a restricted grid near the manually estimated photo angle.
                ranked.sort(key=lambda item: item[0], reverse=True)
                best_score, best = ranked[0]
                row["camera_grid_count"] = len(ranked)
                row["best_camera_provisional"] = best["camera"]
                row["score_camera_adjusted_unverified"] = best_score
                row["raw_score_initial_guess"] = row["score_0_100"]
                row["camera_fit_status"] = "GRID_CANDIDATE_REQUIRES_VISUAL_APPROVAL"
            row["review_needed"] = ("Check foreground extraction including base, "
                "verify arm/leg joint pose, verify camera yaw/pitch/projection; "
                "DO NOT promote this result to approved scorecard yet.")
        except (ValueError, OSError, urllib.error.URLError) as error:
            row["error"] = str(error)
        out.append(row)
        print("REFERENCE_CANDIDATE|" + json.dumps(row, sort_keys=True))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({"method": "preliminary-mask-ioU-70-boundary-f1-30",
         "approved_scores": 0, "candidates": out}, indent=2) + "\n",
         encoding="utf-8")


if __name__ == "__main__":
    main()
