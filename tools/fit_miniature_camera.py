#!/usr/bin/env python3
"""Fit camera and articulated pose to manually annotated miniature landmarks.

Input JSON:
{
  "image_size": [1200, 900],
  "landmarks": [
    {"name":"head", "xyz":[0,40,-6], "uv":[600,120], "weight":2},
    {"name":"left_shoulder", "xyz":[-11,33,0], "uv":[450,260]}
  ],
  "pose_groups": {"left_arm": ["left_shoulder","left_elbow"]},
  "pivot_by_group": {"left_arm": [-11,33,0]}
}
Provide at least six independently located landmarks for a perspective fit.
Pixels are top-left origin. Coordinates are in model authoring grid units.
No automatic image matching is claimed. A calibrated view is eligible for
scoring only when RMS reprojection error is below --max-error-px.
"""
import argparse
import json
import math
from pathlib import Path

import numpy as np
from scipy.optimize import least_squares
from scipy.spatial.transform import Rotation


def project(xyz, params, width, height):
    rot = Rotation.from_rotvec(params[:3]).as_matrix()
    camera_xyz = xyz @ rot.T + params[3:6]
    z = camera_xyz[:, 2]
    focal = math.exp(params[6])
    uv = np.column_stack((width / 2 + focal * camera_xyz[:, 0] / z,
                          height / 2 - focal * camera_xyz[:, 1] / z))
    return uv, z


def fit(data, max_error_px):
    width, height = data["image_size"]
    landmarks = data["landmarks"]
    if len(landmarks) < 6:
        raise ValueError("At least six 3D-to-2D landmarks required")
    xyz = np.asarray([v["xyz"] for v in landmarks], dtype=float)
    uv = np.asarray([v["uv"] for v in landmarks], dtype=float)
    weights = np.asarray([v.get("weight", 1) for v in landmarks], dtype=float)
    if np.any(weights <= 0):
        raise ValueError("All weights must be positive")
    span = max(np.ptp(xyz, axis=0))
    center = xyz.mean(axis=0)
    best = None
    # Multistart over yaw; use the same fitted camera for every candidate.
    for yaw in np.linspace(-math.pi, math.pi, 12, endpoint=False):
        rot = Rotation.from_euler("y", yaw).as_rotvec()
        params = np.r_[rot, -center[0], -center[1], span * 4, math.log(max(width, height))]
        def residual(p):
            pred, z = project(xyz, p, width, height)
            penalty = np.minimum(z - 0.1, 0) * 100
            return np.r_[((pred - uv) * np.sqrt(weights[:, None])).ravel(), penalty]
        res = least_squares(residual, params, max_nfev=250, loss="soft_l1",
                            bounds=([-10]*3 + [-1e5]*2 + [0.1, math.log(10)],
                                    [10]*3 + [1e5]*3 + [math.log(1e5)]))
        predicted, z = project(xyz, res.x, width, height)
        rms = float(np.sqrt(np.mean(np.sum((predicted - uv)**2, axis=1))))
        if np.all(z > 0) and (best is None or rms < best["rms_error_px"]):
            best = {"rms_error_px": rms, "rotation_rotvec": res.x[:3].tolist(),
                    "translation": res.x[3:6].tolist(), "focal_px": math.exp(res.x[6]),
                    "landmark_errors_px": {v["name"]: float(np.linalg.norm(predicted[i]-uv[i]))
                                            for i, v in enumerate(landmarks)}}
    if best is None:
        raise RuntimeError("No camera solution with all landmarks in front of camera")
    best["score_eligible"] = best["rms_error_px"] <= max_error_px
    best["note"] = "Pose pivots are not optimized here; supply pose-matched landmark xyz before fitting."
    return best


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("annotations", type=Path)
    parser.add_argument("--max-error-px", type=float, default=12)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    data = json.loads(args.annotations.read_text())
    result = fit(data, args.max_error_px)
    output = json.dumps(result, indent=2) + "\n"
    if args.output:
        args.output.write_text(output)
    else:
        print(output, end="")


if __name__ == "__main__":
    main()
