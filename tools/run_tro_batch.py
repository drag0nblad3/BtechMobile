#!/usr/bin/env python3
"""Score a bounded set of official TRO illustrations; never approve the fit."""
import argparse
import json
import pathlib
import sys

from run_reference_batch import execute


def main():
    ap = argparse.ArgumentParser()
    for field in ("index", "output"):
        ap.add_argument("--" + field, type=pathlib.Path, required=True)
    ap.add_argument("--poses", type=str, required=True)
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--limit", type=int, default=20)
    args = ap.parse_args()
    all_candidates = json.loads(args.index.read_text(encoding="utf-8"))[
        "candidates"]
    if args.offset < 0 or args.limit < 1:
        raise ValueError("Invalid index range")
    selected = all_candidates[args.offset:args.offset + args.limit]
    if not selected:
        raise ValueError("Empty TRO source batch")
    folder = args.output / ("batch_%02d" % (args.offset // 20 + 1))
    folder.mkdir(parents=True, exist_ok=True)
    subset = folder / "candidates.json"
    subset.write_text(json.dumps({"candidates": selected}, indent=2) + "\n",
                      encoding="utf-8")
    names = ",".join(x["model"] for x in selected)
    execute("godot", "--headless", "-s",
            "tools/export_reference_review_masks.gd", "--",
            folder / "model-masks", args.poses, names)
    execute("godot", "--headless", "-s",
            "tools/reference_camera_sweep.gd", "--",
            folder / "sweep", args.poses, subset)
    execute(sys.executable, "tools/score_tro_illustrations.py",
            "--candidates", subset, "--models", folder / "model-masks",
            "--sweep", folder / "sweep/index.json",
            "--output", folder / "scores.json")
    results = json.loads((folder / "scores.json").read_text(
        encoding="utf-8"))["candidates"]
    count = sum("provisional_camera_fit_0_100" in r for r in results)
    print("TRO_BATCH_COMPLETE|offset=%d|size=%d|measured=%d" % (
        args.offset, len(selected), count), flush=True)


if __name__ == "__main__":
    main()
