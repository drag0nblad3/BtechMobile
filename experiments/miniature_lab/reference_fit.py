#!/usr/bin/env python3
"""Manual-photo landmark registration for independent miniature assemblies.

Camera and leg pose are fit separately. This is NOT calibrated photogrammetry.
Requires only Python stdlib. Original photographs are never stored in git.
"""
import argparse
import json
import math
from pathlib import Path
from miniature_lab import project, rasterize, audit


def center(cells, axis=None, extreme=None):
    pts = [(x + .5, y + .5, z + .5) for x, y, z in cells]
    if axis is not None:
        boundary = (max if extreme == "max" else min)(v[axis] for v in pts)
        pts = [v for v in pts if abs(v[axis] - boundary) < .6]
    return tuple(sum(p[i] for p in pts) / len(pts) for i in range(3))


def anchors(spec, parts):
    pitch = spec["pitch"]
    names = {p["name"]: p for p in spec["parts"]}
    out = {"dorsal": center(parts["ct"], 1, "max"),
           "nose": center(parts["hd"], 2, "min"),
           "left_pod": center(parts["la"], 0, "min"),
           "right_pod": center(parts["ra"], 0, "max"),
           "waist": center(parts["ct"], 1, "min")}
    for s in ("l", "r"):
        for name, part_name in (("hip", s + "l"), ("knee", s + "l_shin"),
                                ("ankle", s + "l_foot")):
            out[s + "_" + name] = tuple(v / pitch for v in names[part_name]["pivot"])
        out[s + "_foot"] = center(parts[s + "l_foot"], 1, "min")
    return out


def normalize(view):
    x, y, w, h = view["crop"]
    if min(w, h) <= 0:
        raise ValueError("invalid source photo crop")
    return {key: ((u - x) / w, (v - y) / h)
            for key, (u, v) in view["landmarks_px"].items()}


def camera_fit(pts, observed, yaw, elevation):
    pairs = [(project(pts[k], yaw, elevation), observed[k])
             for k in ("dorsal", "nose", "left_pod", "right_pod", "waist")
             if k in observed]
    if len(pairs) < 3:
        raise ValueError("camera registration requires at least three torso anchors")
    ax = sum(a[0] for a, _ in pairs) / len(pairs)
    ay = sum(a[1] for a, _ in pairs) / len(pairs)
    bx = sum(b[0] for _, b in pairs) / len(pairs)
    by = sum(b[1] for _, b in pairs) / len(pairs)
    # Source projected y is up; photograph y is down.
    numerator = sum((a[0] - ax) * (b[0] - bx) -
                    (a[1] - ay) * (b[1] - by) for a, b in pairs)
    denom = sum((a[0] - ax) ** 2 + (a[1] - ay) ** 2 for a, _ in pairs)
    scale = numerator / denom if denom > 0 else 0
    if scale <= 0:
        return None  # No mirror/reflection cheat.
    tx, ty = bx - scale * ax, by + scale * ay
    residuals = [math.hypot(scale * a[0] + tx - b[0],
                           -scale * a[1] + ty - b[1]) for a, b in pairs]
    return {"yaw": yaw, "elevation": elevation, "scale": scale,
            "tx": tx, "ty": ty,
            "rigid_rmse": math.sqrt(sum(v*v for v in residuals)/len(residuals)),
            "rigid_points": len(residuals)}


def image_projection(pt, camera):
    x, y = project(pt, camera["yaw"], camera["elevation"])
    return (camera["scale"] * x + camera["tx"],
            -camera["scale"] * y + camera["ty"])


def add(a, b):
    return tuple(v + w for v, w in zip(a, b))


def sub(a, b):
    return tuple(v - w for v, w in zip(a, b))


def rotate_x(vec, degrees):
    radians = math.radians(degrees)
    x, y, z = vec
    return (x, y * math.cos(radians) - z * math.sin(radians),
            y * math.sin(radians) + z * math.cos(radians))


def articulated(pts, side, thigh_pitch, shin_pitch):
    hip, knee, ankle, foot = (pts[side + "_" + n] for n in
                              ("hip", "knee", "ankle", "foot"))
    knee2 = add(hip, rotate_x(sub(knee, hip), thigh_pitch))
    ankle2 = add(knee2, rotate_x(sub(ankle, knee), thigh_pitch + shin_pitch))
    foot2 = add(ankle2, sub(foot, ankle))  # Sole remains approximately level.
    return knee2, ankle2, foot2


def pose_fit(pts, observed, camera, side):
    labels = [(side + "_" + name, index) for index, name
              in enumerate(("knee", "ankle", "foot"))
              if side + "_" + name in observed]
    if not labels:
        return None
    best = None
    for thigh in range(-35, 36, 5):
        for shin in range(-40, 41, 5):
            joints = articulated(pts, side, thigh, shin)
            errors = [math.dist(image_projection(joints[i], camera), observed[k])
                      for k, i in labels]
            rmse = math.sqrt(sum(v * v for v in errors) / len(errors))
            objective = rmse + (abs(thigh) + abs(shin)) * .0002
            if best is None or objective < best["objective"]:
                best = {"thigh_pitch": thigh, "shin_pitch": shin,
                        "rmse": round(rmse, 5), "objective": objective}
    best.pop("objective")
    return best


def score(spec, parts, annotation):
    pts = anchors(spec, parts)
    records = []
    for view in annotation["views"]:
        observed = normalize(view)
        proposals = [camera_fit(pts, observed, yaw, elev)
                     for yaw in view["yaw_candidates"]
                     for elev in view["elevation_candidates"]]
        proposals = [p for p in proposals if p is not None]
        if not proposals:
            raise ValueError("no valid camera for " + view["name"])
        selected = min(proposals, key=lambda p: p["rigid_rmse"])
        for side in ("l", "r"):
            fitted = pose_fit(pts, observed, selected, side)
            if fitted is not None:
                selected[side + "_leg_pose"] = fitted
        selected["rigid_rmse"] = round(selected["rigid_rmse"], 5)
        selected["name"] = view["name"]
        selected["landmarks"] = sorted(observed)
        records.append(selected)
    return {"revision": spec.get("shape_refinement_revision", "baseline"),
            "mean_rigid_rmse": round(sum(p["rigid_rmse"] for p in records) /
                                      len(records), 5),
            "views": records,
            "metric": "2D normalized crop units; lower is better",
            "caveat": "Coarsely hand-picked points, orthographic camera; pose fit has only leg-pitch degrees of freedom. NOT an image silhouette score."}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("annotations", type=Path)
    parser.add_argument("assemblies", type=Path, nargs="+")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    ann = json.loads(args.annotations.read_text(encoding="utf-8"))
    results = []
    for path in args.assemblies:
        spec = json.loads(path.read_text(encoding="utf-8"))
        parts = rasterize(spec)
        errors = audit(spec, parts)
        if errors:
            raise SystemExit("Invalid model: " + str(errors[:3]))
        results.append(score(spec, parts, ann))
    report = {"source": ann["reference_url"], "confidence": ann["confidence"],
              "candidates": results}
    output = json.dumps(report, indent=2) + "\n"
    if args.output:
        base = Path(__file__).resolve().parent
        dest = args.output.resolve()
        if not dest.is_relative_to(base):
            raise SystemExit("Reports must stay inside the experiment directory")
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(output, encoding="utf-8")
    print(output)


if __name__ == "__main__":
    main()
