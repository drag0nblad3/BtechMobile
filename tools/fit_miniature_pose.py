#!/usr/bin/env python3
"""Joint-angle fit with a frozen camera calibration.

Annotate photo UV points and model-space XYZ points. Each moving landmark can
specify group (left_arm/right_arm/left_leg/right_leg), with pivot coordinates
in the JSON 'pivots' mapping. Rotation is about the model's X axis for arm
pitch and hip flexion, Y for torso yaw. Fit group angles without changing
camera parameters; compare every candidate under the same camera.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from scipy.optimize import least_squares
from scipy.spatial.transform import Rotation

from fit_miniature_camera import project


def articulated_points(landmarks, pivots, angles):
    points = []
    for item in landmarks:
        xyz = np.asarray(item["xyz"], dtype=float)
        group = item.get("group")
        if group and group in pivots:
            pivot = np.asarray(pivots[group], dtype=float)
            axis = "y" if group == "torso" else "x"
            xyz = pivot + Rotation.from_euler(axis, angles[group]).apply(xyz - pivot)
        points.append(xyz)
    return np.asarray(points)


def fit(data, camera):
    groups = sorted(set(item.get("group") for item in data["landmarks"]
                        if item.get("group") in data.get("pivots", {})))
    if not groups:
        raise ValueError("Need at least one articulated landmark group and pivot")
    uv = np.asarray([item["uv"] for item in data["landmarks"]], dtype=float)
    weights = np.asarray([item.get("weight", 1) for item in data["landmarks"]], dtype=float)
    w, h = data["image_size"]
    params = np.r_[camera["rotation_rotvec"], camera["translation"],
                   np.log(camera["focal_px"])]
    def residual(values):
        xyz = articulated_points(data["landmarks"], data["pivots"], dict(zip(groups, values)))
        predicted, depths = project(xyz, params, w, h)
        return np.r_[((predicted-uv)*np.sqrt(weights[:, None])).ravel(),
                     np.minimum(depths-0.1, 0)*100]
    result = least_squares(residual, np.zeros(len(groups)), bounds=(-1.2, 1.2),
                           max_nfev=500, loss="soft_l1")
    errors = residual(result.x)[:2*len(uv)].reshape(-1, 2)
    return {"joint_angles_degrees": {g: float(np.degrees(a)) for g, a in zip(groups, result.x)},
            "rms_error_px": float(np.sqrt(np.mean(np.sum(errors**2, axis=1)))),
            "camera_frozen": True,
            "caution": "Single-axis joint model. Update landmark XYZ and refit after pivot changes."}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("annotations", type=Path)
    parser.add_argument("camera", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = fit(json.loads(args.annotations.read_text()),
                 json.loads(args.camera.read_text()))
    content = json.dumps(result, indent=2) + "\n"
    if args.output:
        args.output.write_text(content)
    else:
        print(content, end="")


if __name__ == "__main__":
    main()
