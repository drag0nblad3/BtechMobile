#!/usr/bin/env python3
"""Print compact binary model/reference masks for human QA in CI logs."""
import argparse
import json
import pathlib
from score_reference_silhouettes import read_mask, normalize


def lines(path, size=32):
    cells = normalize(read_mask(path), size)
    return ["".join("#" if (x, y) in cells else " "
                    for x in range(size)) for y in range(size)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=pathlib.Path, required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--select", type=str, default="")
    args = parser.parse_args()
    report = json.loads(args.report.read_text())
    for trial in report["candidates"]:
        if trial.get("score_0_100") is None:
            continue
        model, view = trial["model"], trial["view"]
        if args.select and model not in args.select.split(","):
            continue
        a = args.models / model / (view + ".txt")
        b = args.report.parent / "reference-masks" / model / (view + ".png")
        if not a.is_file() or not b.is_file():
            continue
        print(f"MODEL_VS_REFERENCE_{model}_{view} (model LEFT / photo RIGHT)")
        model_rows, photo_rows = lines(a), lines(b)
        for left, right in zip(model_rows, photo_rows):
            print("|" + left + "|  |" + right + "|")
        print("END_MODEL_VS_REFERENCE")


if __name__ == "__main__":
    main()
