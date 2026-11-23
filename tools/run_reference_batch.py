#!/usr/bin/env python3
"""Run real-photo silhouette trials in resumable 20-sculpt batches.

Candidate camera/rig scores are exploratory until a person checks the picture,
pose, foreground mask, and actual camera perspective. Never fill approved slots.
"""
import argparse
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]


def execute(*argv):
    print("BATCH_COMMAND|" + " ".join(map(str, argv)), flush=True)
    subprocess.run(list(map(str, argv)), cwd=ROOT, check=True, timeout=1200)


def run_batch(models, poses, output, index):
    names = [r["model"] for r in models]
    folder = output / ("batch_%02d" % index)
    folder.mkdir(parents=True, exist_ok=True)
    manifest = folder / "candidates.json"
    manifest.write_text(json.dumps({"candidates": models}, indent=2),
                        encoding="utf-8")
    exported = folder / "model-masks"
    execute("godot", "--headless", "-s",
            "tools/export_reference_review_masks.gd", "--",
            exported, poses, ",".join(names))
    execute("godot", "--headless", "-s",
            "tools/reference_camera_sweep.gd", "--",
            folder / "camera-sweep", poses, manifest)
    report = folder / "candidate-fit.json"
    execute(sys.executable, "tools/score_first_reference_photos.py",
            "--candidates", manifest, "--models", exported,
            "--sweep", folder / "camera-sweep/index.json",
            "--request-delay", "0.4", "--output", report)
    data = json.loads(report.read_text(encoding="utf-8"))
    usable = [r for r in data["candidates"]
              if r.get("score_camera_adjusted_unverified") is not None]
    print("REFERENCE_BATCH|index=%d|size=%d|measured=%d|failed=%d" % (
        index, len(names), len(usable), len(names) - len(usable)), flush=True)
    for row in data["candidates"]:
        print("REFERENCE_RESULT_JSON|" + json.dumps(row, sort_keys=True),
              flush=True)
    return data["candidates"]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--index", type=pathlib.Path, required=True)
    ap.add_argument("--poses", type=str, required=True)
    ap.add_argument("--output", type=pathlib.Path, required=True)
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--limit", type=int, default=20)
    args = ap.parse_args()
    candidates = json.loads(args.index.read_text(
        encoding="utf-8"))["candidates"]
    if not (0 <= args.offset <= len(candidates)) or args.limit < 1:
        raise ValueError("Invalid batch boundaries")
    chosen = candidates[args.offset:args.offset + args.limit]
    report = run_batch(chosen, args.poses, args.output, args.offset // 20 + 1)
    result = {"source_count": len(chosen),
              "measured_count": sum(
                  r.get("score_camera_adjusted_unverified") is not None
                  for r in report),
              "candidate_results": report}
    out = args.output / ("batch_%02d" % (args.offset // 20 + 1))
    (out / "summary.json").write_text(
        json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print("BATCH_COMPLETE|offset=%d|count=%d" % (args.offset, len(chosen)),
          flush=True)


if __name__ == "__main__":
    main()
