#!/usr/bin/env python3
"""Five independently reviewable Jenner sculpt passes; no merged art changes."""
import copy
import json
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent


def r(value):
    return round(value, 5)


def parts(spec):
    return {p["name"]: p for p in spec["parts"]}


def torso_depth(spec):
    """Reduce slab-like rear torso while keeping original head/hip pivots."""
    for i, sec in enumerate(parts(spec)["ct"]["shapes"][0]["sections"]):
        weight = (0, .45, .85, 1, .5, 0)[i]
        for q in sec["polygon"]:
            q[0] = r(q[0] * (1 - weight*.01))
            q[1] = r(q[1] + weight*(.015 if q[1] < 0 else -.055))


def disc_cockpit(spec):
    """Flatten/advance the oblate disc; retain paint-only window geometry."""
    hd = parts(spec)["hd"]
    for sec in hd["shapes"][0]["sections"]:
        z = sec["at"]
        w = max(0, min(1, (-z-.67)/.49))
        sec["at"] = r(z-w*.02)
        for q in sec["polygon"]:
            q[0] = r(q[0]*(1+.08*(.5+.5*w)))
            q[1] = r(1.54+(q[1]-1.54)*(1-.06*(.5+.5*w)))
    for sh in hd["shapes"][1:]:
        if sh.get("op") != "paint":
            continue
        for sec in sh["sections"]:
            sec["at"] = r(sec["at"]-.02)
            for q in sec["polygon"]:
                q[0] = r(q[0]*1.08)
                q[1] = r(1.54+(q[1]-1.54)*.94)
    for sec in hd["shapes"][0]["sections"]:
        w = max(0, min(1, (-sec["at"]-.33)/.83))
        for q in sec["polygon"]:
            q[0] = r(q[0]*(1+.015*w))
            q[1] = r(1.53+(q[1]-1.53)*.95+.015*(1-w))
    for sh in hd["shapes"][1:]:
        if sh.get("op") != "paint":
            continue
        for sec in sh["sections"]:
            for q in sec["polygon"]:
                q[1] = r(1.53+(q[1]-1.53)*.95+.009)


def shoulders_and_pods(spec):
    """Improve shoulder sweep and pod facets, without widening external span."""
    by = parts(spec)
    for side in ("l", "r"):
        for i, sec in enumerate(by[side+"t"]["shapes"][0]["sections"]):
            weight = (0, .35, 1, .55, 0)[i]
            for q in sec["polygon"]:
                q[0] = r(q[0]*(1-weight*.02))
                q[1] = r(q[1]+weight*(-.035 if q[1] < 0 else .035/3))
        for sec in by[side+"a"]["shapes"][0]["sections"]:
            pp = sec["polygon"]
            cy = (min(q[0] for q in pp)+max(q[0] for q in pp))/2
            cz = (min(q[1] for q in pp)+max(q[1] for q in pp))/2
            ry = (max(q[0] for q in pp)-min(q[0] for q in pp))/2
            rz = (max(q[1] for q in pp)-min(q[1] for q in pp))/2
            for q in pp:
                yy, zz = (q[0]-cy)/ry, (q[1]-cz)/rz
                q[0] = r(cy+ry*math.copysign(abs(yy)**.9, yy))
                q[1] = r(cz+rz*math.copysign(abs(zz)**.9, zz))


def knee_profiles(spec):
    """Refine actual fore-aft calf/knee contours, not the camera pose."""
    by = parts(spec)
    for side in ("l", "r"):
        for q in by[side+"l"]["shapes"][0]["sections"][1]["polygon"]:
            if q[1] < -.08:
                q[1] = r(q[1]-.018)
        for q in by[side+"l_shin"]["shapes"][0]["sections"][1]["polygon"]:
            if q[1] > 0:
                q[1] = r(q[1]+.012)


def dorsal_sensor(spec):
    """An anchored 24-vertex dish, no floating cap or auto-added connectors."""
    def ring(rx, rz, zcenter=.078):
        return [[r(rx*math.cos(2*math.pi*i/24)),
                 r(zcenter+rz*math.sin(2*math.pi*i/24))]
                for i in range(24)]
    parts(spec)["ct"]["shapes"].append({
        "axis": "y", "mat": "structure", "op": "add",
        "sections": [
            {"at": 2.275, "polygon": ring(.072, .055)},
            {"at": 2.306, "polygon": ring(.0765, .075)},
            {"at": 2.31, "polygon": ring(.085, .093)},
            {"at": 2.325, "polygon": ring(.0782, .085)},
        ],
    })


STAGES = (
    ("01_torso", torso_depth),
    ("02_disc_cockpit", disc_cockpit),
    ("03_shoulders_pods", shoulders_and_pods),
    ("04_knees", knee_profiles),
    ("05_dorsal_dish", dorsal_sensor),
)


def build_stages():
    spec = json.loads((HERE/"jenner_assembly_v10.json").read_text())
    result = [("00_v10_control", copy.deepcopy(spec))]
    for name, action in STAGES:
        action(spec)
        spec["shape_refinement_revision"] = "miniature-v11-"+name+"-20261123"
        spec["reference_fit_policy"] = (
            "Fit camera/pose once to v8 control; freeze camera, lens and "
            "pose across all v10/v11 candidates. Missing view is unscored."
        )
        result.append((name, copy.deepcopy(spec)))
    return result


if __name__ == "__main__":
    _, result = build_stages()[-1]
    output = HERE/"jenner_assembly_v11.json"
    output.write_text(json.dumps(result, indent=2)+"\n")
    print("Generated", output, "with", len(result["parts"]), "components")
