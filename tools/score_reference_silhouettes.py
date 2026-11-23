#!/usr/bin/env python3
"""Score paired, binary multi-angle silhouette masks; missing references remain unscored.

python tools/score_reference_silhouettes.py \
    --scorecard docs/graphics/all-model-reference-silhouette-scorecard.csv \
    --renders /tmp/mech-masks --references /tmp/reference-masks \
    --output /tmp/multiangle-scored.csv

Expected paths: <root>/<model-id>/front.png (or .txt), side, quarter, top.
PNG is pre-masked: opaque black subject on white, or opaque subject on alpha.
Text files use # foreground and . background. Remove bases and match poses.
"""
import argparse
import csv
import pathlib

VIEWS = ("front", "side", "quarter", "top")
WEIGHTS = {"front": 0.55, "side": 0.28, "quarter": 0.12, "top": 0.05}
SIZE = 128


def read_mask(path):
    if path.suffix == ".txt":
        lines = path.read_text(encoding="utf-8").splitlines()
        if not lines or len(set(map(len, lines))) != 1:
            raise ValueError(f"Non-rectangular text mask: {path}")
        return {(x, y) for y, line in enumerate(lines)
                for x, char in enumerate(line) if char == "#"}
    from PIL import Image  # Only required for PNG masks.
    with Image.open(path) as src:
        image = src.convert("RGBA")
        w, h = image.size
        transparent = image.getchannel("A").getextrema()[0] < 255
        pixels = image.load()
        return {(x, y) for y in range(h) for x in range(w)
                if (pixels[x, y][3] >= 128 if transparent
                    else sum(pixels[x, y][:3]) < 384)}


def normalize(mask, resolution=SIZE):
    if not mask:
        return set()
    xmin, xmax = min(x for x, _ in mask), max(x for x, _ in mask)
    ymin, ymax = min(y for _, y in mask), max(y for _, y in mask)
    width, height = xmax - xmin + 1, ymax - ymin + 1
    scale = (resolution - 8) / max(width, height)
    dw, dh = max(1, round(width * scale)), max(1, round(height * scale))
    ox, oy = (resolution - dw) // 2, (resolution - dh) // 2
    return {(ox + x, oy + y) for y in range(dh) for x in range(dw)
            if (xmin + min(width - 1, int((x + 0.5) * width / dw)),
                ymin + min(height - 1, int((y + 0.5) * height / dh))) in mask}


def outline(mask):
    return {p for p in mask if any((p[0] + dx, p[1] + dy) not in mask
            for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)))}


def near_any(p, candidates, tolerance=2):
    return any((p[0] + dx, p[1] + dy) in candidates
               for dx in range(-tolerance, tolerance + 1)
               for dy in range(-tolerance, tolerance + 1)
               if dx * dx + dy * dy <= tolerance * tolerance)


def score_masks(model, reference):
    a, b = normalize(model), normalize(reference)
    if not a or not b:
        raise ValueError("Empty model or reference silhouette")
    iou = len(a & b) / len(a | b)
    ea, eb = outline(a), outline(b)
    precision = sum(near_any(p, eb) for p in ea) / len(ea)
    recall = sum(near_any(p, ea) for p in eb) / len(eb)
    f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0
    return round(100 * (0.7 * iou + 0.3 * f1), 1)


def weighted_overall(scores):
    if any(view not in scores for view in VIEWS):
        return None
    return round(sum(scores[v] * WEIGHTS[v] for v in VIEWS), 1)


def locate(root, model, angle):
    folder = root / model
    found = [folder / (angle + ext) for ext in (".png", ".txt")
             if (folder / (angle + ext)).is_file()]
    if len(found) > 1:
        raise ValueError(f"Ambiguous masks for {model}/{angle}")
    return found[0] if found else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for flag in ("scorecard", "renders", "references", "output"):
        parser.add_argument("--" + flag, type=pathlib.Path, required=True)
    args = parser.parse_args()
    with args.scorecard.open(newline="", encoding="utf-8") as file:
        reader = csv.DictReader(file)
        columns, entries = list(reader.fieldnames or []), list(reader)
    for row in entries:
        scores = {}
        any_unverified = False
        for view in VIEWS:
            key = view + "_0_100"
            row[key] = ""  # No stale scores from an earlier review.
            stance = row.get("stance_" + view + "_review",
                             row.get("stance_review_status", ""))
            if stance and stance not in ("VERIFIED_RIG_MATCH", "NOT_APPLICABLE_STATIC"):
                any_unverified = True
                continue
            if stance == "VERIFIED_RIG_MATCH" and not row.get("stance_profile", "").strip():
                raise ValueError(f"{row['model']}/{view}: approved rig pose requires a stance_profile")
            model = locate(args.renders, row["model"], view)
            ref = locate(args.references, row["model"], view)
            if model is None or ref is None:
                continue
            try:
                score = score_masks(read_mask(model), read_mask(ref))
            except (ValueError, OSError) as exc:
                raise ValueError(f"Invalid {row['model']} {view}: {exc}") from exc
            row[key], scores[view] = f"{score:.1f}", score
        overall = weighted_overall(scores)
        row["overall_0_100"] = "" if overall is None else f"{overall:.1f}"
        row["status"] = ("SCORED_MASK_PAIR_4_OF_4" if len(scores) == 4 else
                         f"PARTIAL_MASK_PAIR_{len(scores)}_OF_4__OTHER_POSES_UNVERIFIED"
                         if scores and any_unverified else
                         f"PARTIAL_MASK_PAIR_{len(scores)}_OF_4" if scores else
                         "AWAITING_RIG_STANCE_MATCH" if any_unverified else
                         "UNSCORED – no matched silhouette masks")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=columns)
        writer.writeheader()
        writer.writerows(entries)
    print(f"REFERENCE_SILHOUETTES|models={len(entries)}|complete="
          f"{sum(e['status'] == 'SCORED_MASK_PAIR_4_OF_4' for e in entries)}")


if __name__ == "__main__":
    main()
