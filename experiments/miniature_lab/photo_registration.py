#!/usr/bin/env python3
"""Register pose and camera before scoring a plastic-miniature silhouette.

Hand-marked landmarks and estimated lens values remain diagnostic, not proof
of sculpt fidelity. Fit on a fixed control sculpt; freeze both camera and
pose when comparing alternative geometry. No production model is loaded.
"""
import argparse
import json
import math
from pathlib import Path

import miniature_lab as geo
import photo_fit
import reference_fit

RIGID = ("dorsal", "nose", "left_pod", "right_pod", "waist")


def project_camera(point, camera):
    """Perspective camera orbit around an explicit 3D target."""
    yaw, elev, roll = [math.radians(camera[k])
                       for k in ("yaw", "elevation", "roll")]
    x, y, z = (point[i] - camera["target"][i] for i in range(3))
    u = math.cos(yaw) * x + math.sin(yaw) * z
    dep = -math.sin(yaw) * x + math.cos(yaw) * z
    v = math.cos(elev) * y + math.sin(elev) * dep
    depth = math.cos(elev) * dep - math.sin(elev) * y
    denom = camera["distance"] + depth
    if denom <= .1:
        return None
    return ((math.cos(roll)*u - math.sin(roll)*v) / denom,
            (math.sin(roll)*u + math.cos(roll)*v) / denom,
            denom)


def position(point, camera):
    p = project_camera(point, camera)
    return None if p is None else (
        camera["tx"] + camera["scale"] * p[0],
        camera["ty"] - camera["scale"] * p[1])


def fit_translation_scale(points, observed):
    """Positive uniform scale; translation permitted but no mirror/stretch."""
    if len(points) < 3:
        return None
    src = [(p[0], -p[1]) for p in points]
    ma = [sum(p[k] for p in src)/len(src) for k in (0, 1)]
    mb = [sum(p[k] for p in observed)/len(src) for k in (0, 1)]
    den = sum(sum((a[k]-ma[k])**2 for k in (0, 1)) for a in src)
    if den < 1e-12:
        return None
    scale = sum(sum((a[k]-ma[k])*(b[k]-mb[k]) for k in (0, 1))
                for a, b in zip(src, observed)) / den
    if scale <= 0:
        return None
    tx, ty = (mb[k] - scale*ma[k] for k in (0, 1))
    rmse = math.sqrt(sum((scale*a[0]+tx-b[0])**2 +
                         (scale*a[1]+ty-b[1])**2
                         for a, b in zip(src, observed)) / len(src))
    return (scale, tx, ty, rmse)


def crop_observations(landmarks, photo):
    x0, y0, x1, y1 = photo["crop_px"]
    if x1 <= x0 or y1 <= y0:
        raise ValueError("invalid photo crop")
    return {key: ((x-x0)/(x1-x0), (y-y0)/(y1-y0))
            for key, (x, y) in landmarks["landmarks_px"].items()}


def fit_camera(anchors, observed, photo, distances=(3, 4.5, 7, 12),
               rolls=(-8, -4, 0, 4, 8)):
    """Use only rigid landmarks, never the silhouette being evaluated."""
    keys = [k for k in RIGID if k in observed]
    if len(keys) < 3:
        return None
    points, pixels = ([anchors[k] for k in keys],
                      [observed[k] for k in keys])
    best = None
    for yaw in photo["yaw_candidates"]:
        for elevation in photo["elevation_candidates"]:
            for roll in rolls:
                for distance in distances:
                    cam = {"yaw": yaw, "elevation": elevation, "roll": roll,
                           "distance": distance, "target": anchors["waist"]}
                    pp = [project_camera(p, cam) for p in points]
                    if any(v is None for v in pp):
                        continue
                    result = fit_translation_scale(pp, pixels)
                    if result is None:
                        continue
                    scale, tx, ty, error = result
                    if best is None or error < best["rigid_rmse"]:
                        best = {**cam, "scale": scale, "tx": tx, "ty": ty,
                                "rigid_rmse": error, "rigid_landmarks": keys}
    return best


def fit_pose(anchors, observed, camera, side):
    """Fit hip pitch/roll plus knee flex independently per leg."""
    keys = [side+"_"+s for s in ("knee", "ankle", "foot")
            if side+"_"+s in observed]
    if not {side+"_knee", side+"_ankle"}.issubset(keys):
        return None
    hip, knee, ankle, foot = [anchors[side+"_"+k] for k in
                              ("hip", "knee", "ankle", "foot")]
    best = None
    for pitch in range(-40, 41, 10):
        for roll in range(-18, 19, 6):
            for flex in range(-40, 41, 10):
                def bent(pt, shin):
                    if shin:
                        pt = photo_fit.rotate(pt, knee, (flex, 0, 0))
                    return photo_fit.rotate(pt, hip, (pitch, 0, roll))
                coords = [bent(pt, i > 0)
                          for i, pt in enumerate((knee, ankle, foot))]
                projected = {side+"_"+key: position(pt, camera)
                             for key, pt in zip(("knee", "ankle", "foot"), coords)}
                if any(projected[k] is None for k in keys):
                    continue
                rmse = math.sqrt(sum(math.dist(projected[k], observed[k])**2
                                     for k in keys) / len(keys))
                objective = rmse + (abs(pitch)+abs(roll)+abs(flex))*.00003
                if best is None or objective < best["objective"]:
                    best = {"thigh_pitch": pitch, "thigh_roll": roll,
                            "shin_pitch": flex, "rmse": rmse,
                            "objective": objective, "landmarks": keys}
    if best:
        best.pop("objective")
    return best


def calibration(spec, parts, outlines, landmarks, pairs):
    """Register a single control sculpt; compare other geometry unchanged."""
    if spec["sculpt"] != outlines["sculpt"]:
        raise ValueError("do not mix miniature generations")
    extract = getattr(reference_fit, "anchors", None)
    if extract is None:
        extract = reference_fit.landmarks
    raw = extract(spec, parts)
    anchors = {key: tuple(v*spec["pitch"] for v in pt)
               for key, pt in raw.items()}
    masks = {v["name"]: v for v in outlines["views"]}
    marks = {v["name"]: v for v in landmarks["views"]}
    records = []
    for view_name, landmark_name in pairs.items():
        photo = masks[view_name]
        row = {"view": view_name, "source_view": landmark_name,
               "status": "unscored"}
        if landmark_name not in marks:
            row["reason"] = "camera/pose landmarks unavailable"
            records.append(row)
            continue
        mark = marks[landmark_name]
        obs = crop_observations(mark, photo)
        candidates = dict(photo)
        candidates["yaw_candidates"] = sorted(set(
            photo["yaw_candidates"] + mark.get("yaw_candidates", [])))
        candidates["elevation_candidates"] = sorted(set(
            photo["elevation_candidates"] + mark.get("elevation_candidates", [])))
        camera = fit_camera(anchors, obs, candidates)
        if camera is None:
            row["reason"] = "at least three unmirrored rigid landmarks required"
            records.append(row)
            continue
        legs = {side: fit_pose(anchors, obs, camera, side)
                for side in ("l", "r")}
        if any(value is None for value in legs.values()):
            row["reason"] = "pose landmarks insufficient for both legs"
            row["camera"] = camera
        else:
            pose = {}
            for side, fit in legs.items():
                pose[side+"l"] = [fit["thigh_pitch"], 0, fit["thigh_roll"]]
                pose[side+"l_shin"] = [fit["shin_pitch"], 0, 0]
            row.update({"status": "diagnostic_only", "camera": camera,
                        "pose": pose, "leg_fit": legs})
        records.append(row)
    return {"reference_id": outlines["reference_id"], "sculpt": spec["sculpt"],
            "calibrated_against": spec.get("shape_refinement_revision"),
            "optics_status": "distance estimated; lens and FOV not measured",
            "registration": records}


def registered_mask(spec, parts, camera, pose, size):
    """Freeze framing, camera perspective, pose, and crop across models."""
    modeled = photo_fit.posed_points(spec, parts, pose)
    mask = set()
    for cells in modeled.values():
        for pt in cells:
            projected = project_camera(pt, camera)
            if projected is None:
                continue
            x = round((camera["tx"]+camera["scale"]*projected[0])*size)
            y = round((camera["ty"]-camera["scale"]*projected[1])*size)
            radius = max(1, round(size*spec["pitch"]*.55*camera["scale"] /
                                  projected[2]))
            for dx in range(-radius, radius+1):
                for dy in range(-radius, radius+1):
                    xx, yy = x+dx, y+dy
                    if 0 <= xx < size and 0 <= yy < size:
                        mask.add((xx, yy))
    return mask


def evaluate(spec, parts, outlines, frozen, size=58):
    """No IoU on an unregistered view; no 'miniature accuracy' percentage."""
    if spec["sculpt"] != outlines["sculpt"] or frozen["sculpt"] != spec["sculpt"]:
        raise ValueError("do not score another miniature generation")
    photos = {v["name"]: v for v in outlines["views"]}
    rows = []
    for registered in frozen["registration"]:
        row = {"view": registered["view"], "status": registered["status"]}
        if row["status"] != "diagnostic_only":
            row["reason"] = registered["reason"]
        else:
            truth = photo_fit.make_reference(photos[row["view"]], size)
            predicted = registered_mask(spec, parts, registered["camera"],
                                        registered["pose"], size)
            camera = registered["camera"]
            row.update({"iou": round(photo_fit.iou(predicted, truth), 4),
                        "camera_fit_rmse": round(camera["rigid_rmse"], 4),
                        "leg_fit_rmse": {k: round(v["rmse"], 4)
                                         for k, v in registered["leg_fit"].items()},
                        "camera_yaw": camera["yaw"],
                        "camera_elevation": camera["elevation"],
                        "camera_roll": camera["roll"],
                        "camera_distance": camera["distance"]})
        rows.append(row)
    measured = [v["iou"] for v in rows if "iou" in v]
    return {"model": spec.get("shape_refinement_revision"),
            "status": "diagnostic_only_uncalibrated_lens",
            "mean_registered_iou": (round(sum(measured)/len(measured), 4)
                                    if measured else None),
            "registered_views": len(measured), "total_views": len(rows),
            "views": rows,
            "warning": "Reference points, lens and stance are estimated; "
                       "do not interpret this as photographic accuracy."}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--calibration-model", type=Path, required=True)
    parser.add_argument("--compare", type=Path, nargs="+", required=True)
    parser.add_argument("--masks", type=Path, required=True)
    parser.add_argument("--landmarks", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    outlines = json.loads(args.masks.read_text())
    marks = json.loads(args.landmarks.read_text())
    source = json.loads(args.calibration_model.read_text())
    original = geo.rasterize(source)
    if geo.audit(source, original):
        raise SystemExit("Invalid control sculpt")
    mapping = {"front_left": "front_left_3quarter",
               "front_right": "front_right_3quarter",
               "rear_left": "rear_left_3quarter",
               "rear_right": "unmeasured_camera_pose"}
    frozen = calibration(source, original, outlines, marks, mapping)
    scores = []
    for path in args.compare:
        spec = json.loads(path.read_text())
        parts = geo.rasterize(spec)
        if geo.audit(spec, parts):
            raise SystemExit("Invalid geometry: "+str(path))
        scores.append(evaluate(spec, parts, outlines, frozen))
    raw = json.dumps({"calibration": frozen, "comparisons": scores}, indent=2)+"\n"
    if args.output:
        lab = Path(__file__).resolve().parent
        if not args.output.resolve().is_relative_to(lab):
            raise SystemExit("Reports must stay inside experimental directory")
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(raw)
    print(raw)


if __name__ == "__main__":
    main()
