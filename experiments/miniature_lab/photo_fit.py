#!/usr/bin/env python3
"""Compare the independent source assembly with hand-annotated same-sculpt photos.

No third-party image bytes are stored or downloaded. Results are coarse
silhouette diagnostics, NOT a calibrated photogrammetric measurement.
"""
import argparse
import json
import math
from pathlib import Path
import miniature_lab as geo


def as_normalized(view, polygon):
    x0, y0, x1, y1 = view["crop_px"]
    return [[(x - x0) / (x1 - x0), (y - y0) / (y1 - y0)]
            for x, y in polygon]


def make_reference(view, size):
    mask = geo.polygon_mask(as_normalized(view, view["outline_px"]), size)
    for hole in view.get("voids_px", []):
        mask -= geo.polygon_mask(as_normalized(view, hole), size)
    return mask


def rotate(point, pivot, angles):
    x, y, z = (point[i] - pivot[i] for i in range(3))
    ax, ay, az = [math.radians(a) for a in angles]
    y, z = y * math.cos(ax) - z * math.sin(ax), y * math.sin(ax) + z * math.cos(ax)
    x, z = x * math.cos(ay) + z * math.sin(ay), -x * math.sin(ay) + z * math.cos(ay)
    x, y = x * math.cos(az) - y * math.sin(az), x * math.sin(az) + y * math.cos(az)
    return (x + pivot[0], y + pivot[1], z + pivot[2])


def posed_points(spec, parts, pose):
    indices = {p["name"]: p for p in spec["parts"]}
    chains = {}
    for part in spec["parts"]:
        chain, current = [], part
        while current:
            chain.append(current)
            current = indices.get(current.get("parent"))
        chains[part["name"]] = chain
    pitch = spec["pitch"]
    result = {}
    for name, cells in parts.items():
        coords = []
        for cell in cells:
            point = tuple((v + .5) * pitch for v in cell)
            for joint in chains[name]:
                angles = pose.get(joint["name"], [0, 0, 0])
                if any(angles):
                    point = rotate(point, joint.get("pivot", [0, 0, 0]), angles)
            coords.append(point)
        result[name] = coords
    return result


def projected_masks(spec, parts, yaw, elevation, pose, size):
    posed = posed_points(spec, parts, pose)
    flat = [geo.project(pt, yaw, elevation)
            for values in posed.values() for pt in values]
    pitch = spec["pitch"]
    xmin = min(x for x, _ in flat) - pitch
    xmax = max(x for x, _ in flat) + pitch
    ymin = min(y for _, y in flat) - pitch
    ymax = max(y for _, y in flat) + pitch
    span = max(xmax - xmin, ymax - ymin)
    cx, cy = (xmin + xmax) / 2, (ymin + ymax) / 2
    radius = max(1, round(size * pitch * .56 / span))
    segments = {}
    for name, coords in posed.items():
        mask = set()
        for point in coords:
            x, y = geo.project(point, yaw, elevation)
            px = round(size / 2 + (x - cx) * size / span)
            py = round(size / 2 - (y - cy) * size / span)
            for dx in range(-radius, radius + 1):
                for dy in range(-radius, radius + 1):
                    pixel = (px + dx, py + dy)
                    if 0 <= pixel[0] < size and 0 <= pixel[1] < size:
                        mask.add(pixel)
        segments[name] = mask
    return set().union(*segments.values()), segments


def iou(a, b):
    return len(a & b) / len(a | b) if a | b else 0.0


def fit(spec, parts, reference, size=72):
    results = []
    for view in reference["views"]:
        truth = make_reference(view, size)
        candidates = []
        for yaw in view["yaw_candidates"]:
            for elevation in view["elevation_candidates"]:
                for pose in view["pose_candidates"]:
                    mask, members = projected_masks(
                        spec, parts, yaw, elevation, pose["angles"], size)
                    candidates.append(
                        (iou(mask, truth), yaw, elevation, pose["name"], members))
        best = max(candidates, key=lambda item: item[0])
        segments = {}
        for name, polygon in view.get("parts_px", {}).items():
            if name not in parts:
                raise ValueError("unknown component annotation: " + name)
            target = geo.polygon_mask(as_normalized(view, polygon), size)
            segments[name] = round(iou(best[4][name], target), 3)
        results.append({
            "view": view["name"], "iou": round(best[0], 3),
            "yaw": best[1], "elevation": best[2], "pose": best[3],
            "annotated_component_iou": segments,
            "annotator_confidence": view.get("confidence", "approximate"),
            "candidate_count": len(candidates),
        })
    return {
        "chassis": spec["id"],
        "status": "approximate manually traced outlines, not pixel-perfect",
        "reference_id": reference["reference_id"],
        "views": results,
        "mean_iou": round(sum(v["iou"] for v in results) / len(results), 3),
    }


def main():
    cli = argparse.ArgumentParser()
    cli.add_argument("--source", type=Path, required=True)
    cli.add_argument("--reference", type=Path, required=True)
    cli.add_argument("--out", type=Path)
    cli.add_argument("--size", type=int, default=72)
    args = cli.parse_args()
    spec = json.loads(args.source.read_text())
    ref = json.loads(args.reference.read_text())
    if ref["sculpt"] != spec["sculpt"]:
        raise SystemExit("Sculpt mismatch: never mix miniature editions")
    parts = geo.rasterize(spec)
    faults = geo.audit(spec, parts)
    if faults:
        raise SystemExit("Invalid sculpt: " + str(faults[:8]))
    result = fit(spec, parts, ref, args.size)
    print(json.dumps(result, indent=2))
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(result, indent=2) + "\n")


if __name__ == "__main__":
    main()
