#!/usr/bin/env python3
"""Jenner whole-anatomy experimental reconstruction from 2021 CGL plastic.

Rebuilds geometric volumes in seven independently auditable stages:
pelvis/center torso, disc cockpit, shoulder/pod housings, thighs, shins,
three distinct toe tips, and dorsal sensor. Runs ONLY against independent
v12 source in this experiment; never touches the merged Godot models.
"""
import copy
import json
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent


def rnd(v):
    return round(v, 5)


def named(spec):
    return {p["name"]: p for p in spec["parts"]}


def torso_and_pelvis(spec):
    for sec in named(spec)["ct"]["shapes"][0]["sections"]:
        y = sec["at"]
        for p in sec["polygon"]:
            if y == 1.12:
                p[0] = rnd(p[0] * .88)
                if p[1] > 0:
                    p[1] = rnd(p[1] * .76)
            elif y == 1.34:
                p[0] = rnd(p[0] * .93)
                if p[1] > 0:
                    p[1] = rnd(p[1] * .82)
            elif y == 1.61 and p[1] > .05:
                p[1] = rnd(.05 + (p[1]-.05)*.91)
            elif y == 1.9 and p[1] > .085:
                p[1] = rnd(.085 + (p[1]-.085)*.9)


def oblate_cockpit(spec):
    head = named(spec)["hd"]
    for sh in head["shapes"]:
        if sh["axis"] != "z" or sh.get("op") == "subtract":
            continue
        for sec in sh["sections"]:
            weight = max(0., min(1., (-sec["at"]-.57)/.58))
            for pt in sec["polygon"]:
                pt[0] = rnd(pt[0]*(1+.018*weight))
                factor = 1. - (.05 if sh.get("op") == "paint" else .11)*weight
                pt[1] = rnd(1.545 + (pt[1]-1.545)*factor)


def shoulders_and_pods(spec):
    by = named(spec)
    for side in ("l", "r"):
        for sec in by[side+"t"]["shapes"][0]["sections"]:
            if sec["at"] < 1.93:
                continue
            for p in sec["polygon"]:
                if p[1] < 0:
                    p[1] = rnd(p[1]-.045*(1 if sec["at"] <= 2.099 else .5))
                elif p[1] > .18:
                    p[1] = rnd(p[1]-.013)
        for sec in by[side+"a"]["shapes"][0]["sections"]:
            if abs(sec["at"]) < .70 or abs(sec["at"]) > .92:
                continue
            for p in sec["polygon"]:
                if p[0] > 1.87:
                    p[0] = rnd(1.87+(p[0]-1.87)*.88)
                if p[1] > .20:
                    p[1] = rnd(.20+(p[1]-.20)*.92)


def thigh_and_knee(spec):
    by = named(spec)
    for side in ("l", "r"):
        sec = by[side+"l"]["shapes"][0]["sections"][1]
        for p in sec["polygon"]:
            if p[1] < -.09:
                p[1] = rnd(p[1]-.043)
            if p[1] > .03:
                p[1] = rnd(p[1]+.012)


def shins_and_calves(spec):
    by = named(spec)
    for side in ("l", "r"):
        sec = by[side+"l_shin"]["shapes"][0]["sections"][1]
        x0 = min(p[0] for p in sec["polygon"])
        x1 = max(p[0] for p in sec["polygon"])
        center = (x0+x1)/2
        for p in sec["polygon"]:
            p[0] = rnd(center+(p[0]-center)*1.065)
            if p[1] < -.03:
                p[1] = rnd(p[1]-.03)
            if p[1] > .06:
                p[1] = rnd(p[1]+.042)


def _tip(center, offset):
    x = center + offset
    def profile(w, lo, hi):
        return [[rnd(x-w),rnd(lo+.014)], [rnd(x+w),rnd(lo+.014)],
                [rnd(x+w+.006),rnd(lo+.028)],
                [rnd(x+w+.006),rnd(hi-.018)],
                [rnd(x+w),rnd(hi)], [rnd(x-w),rnd(hi)],
                [rnd(x-w-.006),rnd(hi-.018)],
                [rnd(x-w-.006),rnd(lo+.028)]]
    return {"axis": "z", "mat": "armor", "op": "add", "sections": [
        {"at": -.50, "polygon": profile(.025,.015,.063)},
        {"at": -.415, "polygon": profile(.032,.011,.084)},
        {"at": -.325, "polygon": profile(.038,0.,.104)}]}


def _gap(center, offset):
    x = center+offset
    poly = [[rnd(x-.0145),0], [rnd(x+.0145),0],
            [rnd(x+.0145),.018], [rnd(x+.0145),.092],
            [rnd(x+.0145),.112], [rnd(x-.0145),.112],
            [rnd(x-.0145),.092], [rnd(x-.0145),.018]]
    return {"axis": "z", "mat": "armor", "op": "subtract", "sections": [
        {"at": -.55, "polygon": copy.deepcopy(poly)},
        {"at": -.275, "polygon": copy.deepcopy(poly)}]}


def three_clawed_feet(spec):
    by = named(spec)
    for side, center in (("l", -.43), ("r", .43)):
        foot = by[side+"l_foot"]
        foot["shapes"] = ([foot["shapes"][0]] +
                          [_tip(center, off) for off in (-.093,0.,.093)] +
                          [_gap(center, off) for off in (-.047,.047)])


def dorsal_sensor(spec):
    ct = named(spec)["ct"]
    dish = ct["shapes"][-1]
    if dish["axis"] != "y" or len(dish["sections"]) != 4:
        raise ValueError("unexpected sensor loft; abort")
    for i in range(1,4):
        sec = dish["sections"][i]
        for p in sec["polygon"]:
            p[0] = rnd(p[0]*(.92 if i==3 else 1.08))
            p[1] = rnd(.078+(p[1]-.078)*(.83 if i==3 else 1.12))
    # Additional height exceeds two voxel sample planes: actual sensor
    # silhouette rather than a no-op subpixel vertex adjustment.
    for i, y in ((1,2.33),(2,2.355),(3,2.395)):
        dish["sections"][i]["at"] = y


PASSES = (
    ("01_torso_pelvis", torso_and_pelvis),
    ("02_cockpit", oblate_cockpit),
    ("03_shoulders_weapons", shoulders_and_pods),
    ("04_thigh_knees", thigh_and_knee),
    ("05_shin_calves", shins_and_calves),
    ("06_three_toes", three_clawed_feet),
    ("07_dorsal", dorsal_sensor),
)


def build_stages():
    start = json.loads((HERE/"jenner_assembly_v12.json").read_text())
    saved = [("00_v12_control", copy.deepcopy(start))]
    for label, step in PASSES:
        step(start)
        start["shape_refinement_revision"] = "miniature-v14-"+label
        saved.append((label, copy.deepcopy(start)))
    return saved


def build():
    spec = build_stages()[-1][1]
    spec["shape_refinement_revision"] = "miniature-v14-whole-anatomy-trial"
    spec["reference_review"] = {
        "priority": "All 30 subassembly geometries audited, real shape corrections to torso, head, shoulders, weapon pods, knees, calves, and foot toes",
        "reference_sculpt": "2021 Catalyst Game Labs Jenner CAT35729 / base 63",
        "photographic_source_set": ["jenner_photo_annotations.json",
                                   "jenner_additional_reference_views.json"],
        "camera_pose_rule": "Fit yaw/elevation/roll/perspective/framing and both legs on v12 control, freeze independently per photo. Side-view occlusion is unscored.",
        "do_not_assume": "Reference silhouettes prove resemblance; source neural or polygon density is accuracy",
        "status": "experiment only, unmerged"
    }
    return spec


if __name__=="__main__":
    output=HERE/"jenner_assembly_v14_trial.json"
    output.write_text(json.dumps(build(), indent=2)+"\n")
    print("Created", output)
