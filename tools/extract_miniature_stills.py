#!/usr/bin/env python3
"""Extract reproducible multi-angle stills from a locally available video.

Use only footage where the 2023 Catalyst plastic Sagittaire is individually
visible. Do not infer camera azimuth from timestamps alone.
Example:
  python tools/extract_miniature_stills.py clip.mp4 --times 12.4 17.8 23.1 --outdir refs/sagittaire
"""
import argparse
import json
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("video", type=Path)
    parser.add_argument("--times", nargs="+", type=float, required=True)
    parser.add_argument("--outdir", type=Path, required=True)
    parser.add_argument("--label", default="sagittaire")
    args = parser.parse_args()
    if not args.video.is_file():
        parser.error("video must be a locally accessible file")
    args.outdir.mkdir(parents=True, exist_ok=True)
    records = []
    for index, second in enumerate(args.times):
        if second < 0:
            parser.error("timestamps must be nonnegative")
        filename = args.outdir / f"{args.label}_{index:02d}_{second:.2f}s.png"
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error",
                        "-ss", str(second), "-i", str(args.video),
                        "-frames:v", "1", "-y", str(filename)], check=True)
        records.append({"file": str(filename), "source_video": str(args.video),
                        "time_seconds": second, "view": "unclassified",
                        "sculpt_verified": False, "camera_fit": None,
                        "pose_fit": None, "score_eligible": False})
    (args.outdir / "frame_manifest.json").write_text(json.dumps(records, indent=2)+"\n")
    print(f"Extracted {len(records)} frames; classify views before using for scoring.")


if __name__ == "__main__":
    main()
