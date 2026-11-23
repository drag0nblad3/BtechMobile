#!/usr/bin/env python3
"""Choose preliminary reference pose at the camera already selected for a photo.

The selected pose is NOT a rig adjustment in the game: verify the physical
articulations, feet and view before approving any per-angle silhouette score.
"""
import argparse
import json
import pathlib

from score_reference_silhouettes import locate, read_mask, score_masks


def select_candidates(trial, reference_root, poses):
    image = locate(reference_root, trial["model"], trial["view"])
    if image is None:
        return {"error": "No vetted foreground reference mask"}
    ref = read_mask(image)
    ranked = []
    for candidate in poses:
        if (candidate["model"], candidate["view"]) != (
                trial["model"], trial["view"]):
            continue
        path = pathlib.Path(candidate["path"])
        if not path.is_file():
            continue
        score = score_masks(read_mask(path), ref)
        ranked.append((score, candidate))
    if not ranked:
        return {"error": "No projected joint candidate mask"}
    ranked.sort(key=lambda pair: pair[0], reverse=True)
    best, spec = ranked[0]
    return {"pose_fit_0_100_provisional": best,
        "pose_candidate_id": spec["candidate_id"],
        "pose_joints_candidate": spec["joints"],
        "pose_camera_candidate": spec["camera"],
        "pose_candidates_tested": len(ranked),
        "pose_status": "UNVERIFIED_ARTICULATION_GROUND_CONTACT_AND_CAMERA"}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    for name in ("report", "pose-index", "references", "output"):
        ap.add_argument("--" + name, type=pathlib.Path, required=True)
    args = ap.parse_args()
    rows = json.loads(args.report.read_text(encoding="utf-8"))["candidates"]
    poses = json.loads(args.pose_index.read_text(
        encoding="utf-8"))["candidates"]
    results = []
    for row in rows:
        result = dict(row)
        if (row.get("score_camera_adjusted_unverified") is not None or
                row.get("provisional_camera_fit_0_100") is not None):
            result.update(select_candidates(row, args.references, poses))
        print("POSE_FIT_JSON|" + json.dumps(result, sort_keys=True), flush=True)
        results.append(result)
    report = {"approved_scores": 0, "candidates": results}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n",
                           encoding="utf-8")
    scored = [r for r in results if r.get("pose_fit_0_100_provisional") is not None]
    print("POSE_FIT_BATCH|total=%d|measured=%d" % (len(results), len(scored)))


if __name__ == "__main__":
    main()
