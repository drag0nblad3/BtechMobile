#!/usr/bin/env python3
"""Rank source voxel recipes by torso depth / modeled height (triage only).

This is NOT a photographic fidelity score: weapons, cockpit projections and
pose can legitimately increase depth. Use reference-calibrated comparisons
before resculpting.
"""
import argparse
import json
from pathlib import Path


def points(shape):
    if "box" in shape or "shell" in shape:
        return shape.get("box", shape.get("shell"))
    loft = shape.get("loft")
    if not loft:
        return []
    axis = loft["axis"]
    out = []
    for section in loft["sections"]:
        for a, b in section["polygon"]:
            t = section["at"]
            out.append([a, t, b] if axis == "y" else
                       [a, b, t] if axis == "z" else [t, a, b])
    return out


def measure(recipe):
    all_points = []
    torso_points = []
    for part in recipe["parts"]:
        part_points = [p for shape in part.get("shapes", [])
                       if "erase" not in shape for p in points(shape)]
        all_points.extend(part_points)
        if part["name"] in ("ct", "hd", "lt", "rt"):
            torso_points.extend(part_points)
    if not all_points or not torso_points:
        return None
    height = max(p[1] for p in all_points) - min(p[1] for p in all_points)
    depth = max(p[2] for p in torso_points) - min(p[2] for p in torso_points)
    if height <= 0:
        return None
    return round(depth / height, 4)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="*", type=Path)
    args = parser.parse_args()
    paths = args.paths or sorted(Path("data/voxels").glob("*.json"))
    scores = []
    for path in paths:
        data = json.loads(path.read_text())
        if "parts" not in data or "source" in data:
            continue
        score = measure(data)
        if score is not None:
            scores.append((score, data.get("id", path.stem), path))
    print("torso_depth_height_proxy,chassis,path")
    for score, name, path in sorted(scores, reverse=True):
        print(f"{score:.4f},{name},{path}")


if __name__ == "__main__":
    main()
