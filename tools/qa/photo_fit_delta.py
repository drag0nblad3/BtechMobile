#!/usr/bin/env python3
"""Summarize unapproved before/after photographic silhouette trials.

Both sides must use the same reference candidate registry. This is diagnostic
data, never an approval, a four-angle likeness rating, or a CI pass threshold.
"""
import argparse
import json
from pathlib import Path


def _by_key(report):
    result = {}
    for row in report.get("candidate_results", report.get("candidates", [])):
        key = (row["model"], row["view"])
        if key in result:
            raise ValueError("duplicate reference trial: %s/%s" % key)
        result[key] = row
    return result


def _number(row, key):
    raw = row.get(key)
    return round(float(raw), 2) if raw is not None else None


def compare_reports(before, after):
    initial = _by_key(before)
    current = _by_key(after)
    rows = []
    for model, view in sorted(set(initial) | set(current)):
        old = initial.get((model, view), {})
        new = current.get((model, view), {})
        a = _number(old, "score_camera_adjusted_unverified")
        b = _number(new, "score_camera_adjusted_unverified")
        pose_a = _number(old, "pose_fit_0_100_provisional")
        pose_b = _number(new, "pose_fit_0_100_provisional")
        delta = round(b - a, 2) if a is not None and b is not None else None
        pose_delta = (round(pose_b - pose_a, 2)
                      if pose_a is not None and pose_b is not None else None)
        status = ("CAMERA_PAIR_PROVISIONAL" if delta is not None else
                  "UNSCORED_NO_MATCHED_CAMERA_PAIR")
        rows.append({
            "model": model, "view": view,
            "source_url": new.get("source_url", old.get("source_url")),
            "source_mask_quality_before": old.get("segmentation_review"),
            "source_mask_quality_after": new.get("segmentation_review"),
            "fit_camera_before": a, "fit_camera_after": b,
            "fit_camera_delta_unverified": delta,
            "pose_before": pose_a, "pose_after": pose_b,
            "pose_delta_unverified": pose_delta,
            "camera_before": old.get("best_camera_provisional"),
            "camera_after": new.get("best_camera_provisional"),
            "error_before": old.get("error"), "error_after": new.get("error"),
            "status": status,
            "approved_score": False
        })
    paired = [r for r in rows if r["fit_camera_delta_unverified"] is not None]
    deltas = [r["fit_camera_delta_unverified"] for r in paired]
    return {
        "approved_scores": 0,
        "score_kind": "EXPLORATORY_SAME_SOURCE_CAMERA_REFIT_PER_VERSION",
        "warning": ("Photo/base segmentation and stance/camera are unverified. "
                    "Only one photographed angle per design is available. "
                    "The independent camera refit can mask real geometry defects. "
                    "Do not promote deltas to verified likeness scores."),
        "models_attempted": len(rows), "comparable": len(paired),
        "improved_at_least_2": sum(d >= 2 for d in deltas),
        "degraded_at_least_2": sum(d <= -2 for d in deltas),
        "missing_or_failed": len(rows) - len(paired),
        "rows": rows
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("before", "after", "output"):
        parser.add_argument("--" + name, type=Path, required=True)
    args = parser.parse_args()
    old = json.loads(args.before.read_text(encoding="utf-8"))
    new = json.loads(args.after.read_text(encoding="utf-8"))
    result = compare_reports(old, new)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n",
                           encoding="utf-8")
    print("PROVISIONAL_SCULPT_DELTA|paired=%d|up=%d|down=%d|missing=%d" % (
        result["comparable"], result["improved_at_least_2"],
        result["degraded_at_least_2"], result["missing_or_failed"]))
    for row in result["rows"]:
        print("PROVISIONAL_SCULPT_DELTA_ROW|" + json.dumps(
            row, sort_keys=True))


if __name__ == "__main__":
    main()
