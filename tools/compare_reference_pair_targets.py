#!/usr/bin/env python3
"""Trial one-source-image pair similarity before sculpting; no approved fit claims.

Transient official art URLs -> provisional foreground masks -> 70% IoU +
30% boundary F1. Never store source art or promote a quarter-only trial to
a multi-angle certified similarity. Designed for Godot silhouette mask export.
"""
import argparse
import io
import json
import pathlib
import urllib.parse
import urllib.request

import cv2
import numpy as np
from PIL import Image, ImageDraw

from score_reference_silhouettes import locate, read_mask, score_masks

SAFE_HOSTS = {"cfw.sarna.net", "www.sarna.net"}
LIMIT = 8_000_000
VIEWS = {"quarter"}


def fetch_art(url):
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "https" or parsed.hostname not in SAFE_HOSTS:
        raise ValueError("Reference must use an approved official-art archive host")
    req = urllib.request.Request(url, headers={
        "User-Agent": "BtechMobile-source-silhouette-review/1.0 (noncommercial visual QA)",
        "Accept": "image/png,image/jpeg,image/webp;q=0.9"})
    with urllib.request.urlopen(req, timeout=30) as result:
        if urllib.parse.urlparse(result.geturl()).hostname not in SAFE_HOSTS:
            raise ValueError("Reference redirected off approved source host")
        payload = result.read(LIMIT + 1)
        mime = result.headers.get("Content-Type", "")
    if len(payload) > LIMIT:
        raise ValueError("Reference file exceeds 8 MB")
    if mime and not mime.startswith("image/"):
        raise ValueError("Reference returned nonimage data: " + mime)
    with Image.open(io.BytesIO(payload)) as im:
        im.load()
        if im.width < 120 or im.height < 120:
            raise ValueError("Reference image too small")
        return im.convert("RGBA")


def reference_mask(image, bounds, threshold=222, close_size=9):
    """Conservative line-art extraction; always marked unverified.

    Restrict to a documented subject rectangle; close broken ink, fill large
    silhouettes, and filter marginal noise. A human must approve outlines.
    """
    image = image.copy()
    image.thumbnail((512, 512))
    w, h = image.size
    a = np.asarray(image, dtype=np.uint8)
    x0, y0, x1, y1 = (round(bounds[0] * w), round(bounds[1] * h),
                      round(bounds[2] * w), round(bounds[3] * h))
    if x1 <= x0 or y1 <= y0 or x0 < 0 or y0 < 0 or x1 > w or y1 > h:
        raise ValueError("Invalid subject ROI")
    alpha = a[:, :, 3]
    # Some official illustration files are already transparent subjects.
    is_transparent = np.mean(alpha < 128) > 0.07
    if is_transparent:
        ink = np.asarray(alpha >= 128, dtype=np.uint8) * 255
    else:
        gray = cv2.cvtColor(a[:, :, :3], cv2.COLOR_RGB2GRAY)
        ink = np.asarray(gray < threshold, dtype=np.uint8) * 255
    roi = np.zeros((h, w), dtype=np.uint8)
    roi[y0:y1, x0:x1] = 255
    ink &= roi
    if not is_transparent:
        k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (close_size, close_size))
        ink = cv2.morphologyEx(ink, cv2.MORPH_CLOSE, k, iterations=2)
    contours, _ = cv2.findContours(ink, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    foreground = np.zeros((h, w), dtype=np.uint8)
    kept = 0
    for contour in contours:
        area = cv2.contourArea(contour)
        mx = cv2.moments(contour)
        if area < 0.004 * (x1 - x0) * (y1 - y0) or mx["m00"] == 0:
            continue
        cx, cy = mx["m10"] / mx["m00"], mx["m01"] / mx["m00"]
        if not (x0 <= cx < x1 and y0 <= cy < y1):
            continue
        cv2.drawContours(foreground, [contour], -1, 255, cv2.FILLED)
        kept += 1
    share = float(np.mean(foreground > 0))
    lower = foreground[int(h * 0.82):int(h * 0.96)] > 0
    ground_strip = float(np.max(np.mean(lower, axis=1))) if lower.size else 0.0
    if ground_strip > 0.62:
        raise ValueError("Ground/background ink merged into figure (row share %.3f)"
                         % ground_strip)
    if kept == 0 or not 0.04 <= share <= 0.78:
        raise ValueError("Unreliable foreground segmentation (share %.3f, parts %d)"
                         % (share, kept))
    mask = {(int(x), int(y)) for y, x in np.argwhere(foreground > 0)}
    preview = Image.fromarray(255 - foreground, mode="L").convert("RGB")
    return mask, preview, {"foreground_fraction": round(share, 4),
                           "components_retained": kept,
                           "auto_mask_status": "UNVERIFIED_OUTLINE_AND_CAMERA"}


def assess(pairs, model_root, output, downloader=fetch_art):
    output.mkdir(parents=True, exist_ok=True)
    masks = {}
    subjects = {}
    for pair in pairs:
        for side in ("a", "b"):
            ref = pair[side]
            key = ref["model"]
            if key in masks:
                continue
            try:
                raw = downloader(ref["image_url"])
                # Low-resolution threshold-only QA preview, not an original
                # copyrighted source image or an approved silhouette mask.
                source_preview = raw.convert("L")
                source_preview.thumbnail((160, 160))
                source_preview = source_preview.point(
                    lambda value: 0 if value < 210 else 255)
                source_preview.save(output / (key + "_line_qa_160.png"))
                ink, picture, diagnostics = reference_mask(
                    raw, ref["bounds"], ref.get("threshold", 222),
                    ref.get("close_size", 9))
                picture.save(output / (key + "_reference_mask.png"))
                masks[key] = ink
                subjects[key] = {"status": "PROVISIONAL",
                                 "source_page": ref["source_page"],
                                 "source_image": ref["image_url"],
                                 **diagnostics}
            except (ValueError, OSError, urllib.error.URLError) as exc:
                subjects[key] = {"status": "UNSCORABLE",
                                 "source_page": ref["source_page"],
                                 "error": str(exc)}
    results = []
    for pair in pairs:
        a, b = pair["a"]["model"], pair["b"]["model"]
        view = pair.get("view", "quarter")
        row = {"pair": pair["name"], "models": [a, b], "view": view,
               "status": "UNSCORABLE",
               "source_pose": "UNVERIFIED_SINGLE_ILLUSTRATION_EACH",
               "reference_similarity_0_100": None,
               "model_similarity_0_100": None,
               "model_a_to_reference_0_100": None,
               "model_b_to_reference_0_100": None,
               "goal_model_pair_interval_0_100": None,
               "features_in_common": pair.get("shared", []),
               "reference_differences": pair.get("differences", [])}
        try:
            if view not in VIEWS:
                raise ValueError("Only one provisional quarter illustration is supported")
            if a not in masks or b not in masks:
                raise ValueError("Missing reference mask (see per-model errors)")
            paths = [locate(model_root, name, view) for name in (a, b)]
            if any(path is None for path in paths):
                raise ValueError("Godot model silhouette missing")
            model_a, model_b = [read_mask(path) for path in paths]
            ref_a, ref_b = masks[a], masks[b]
            target = score_masks(ref_a, ref_b)
            current = score_masks(model_a, model_b)
            own_a = score_masks(model_a, ref_a)
            own_b = score_masks(model_b, ref_b)
            wrong_a = score_masks(model_a, ref_b)
            wrong_b = score_masks(model_b, ref_a)
            row.update({
                "status": "PROVISIONAL_NEEDS_FOREGROUND_CAMERA_POSE_REVIEW",
                "reference_similarity_0_100": target,
                "model_similarity_0_100": current,
                "model_a_to_reference_0_100": own_a,
                "model_b_to_reference_0_100": own_b,
                "wrong_reference_a_0_100": wrong_a,
                "wrong_reference_b_0_100": wrong_b,
                "identity_margin_a": round(own_a - wrong_a, 1),
                "identity_margin_b": round(own_b - wrong_b, 1),
                # The sculpt target is to converge on reference difference,
                # not to drive unrelated chassis indefinitely far apart.
                "goal_model_pair_interval_0_100": [max(0, target - 6),
                                                    min(100, target + 6)],
                "gap_model_minus_reference": round(current - target, 1),
                "individual_goal": "Improve each own-reference fit by >=5 from "
                                    "the pre-sculpt baseline without shrinking "
                                    "the identity margin; manually verify camera."
            })
        except (OSError, ValueError) as exc:
            row["error"] = str(exc)
        results.append(row)
        print("PRE_SCULPT_REFERENCE_PAIR|" + json.dumps(row, sort_keys=True))
    result = {"method": "70% normalized IoU + 30% tolerance-2 boundary F1",
              "approved_four_angle_scores": 0,
              "limitations": "One artwork each; perspective, pose, object "
                             "segmentation and bases not manually certified.",
              "references": subjects, "pairs": results}
    (output / "pair-goals.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--manifest", type=pathlib.Path, required=True)
    p.add_argument("--models", type=pathlib.Path, required=True)
    p.add_argument("--output", type=pathlib.Path, required=True)
    args = p.parse_args()
    entries = json.loads(args.manifest.read_text(encoding="utf8"))
    if entries.get("version") != 1:
        raise ValueError("Invalid pair manifest version")
    assess(entries["pairs"], args.models, args.output)


if __name__ == "__main__":
    main()
