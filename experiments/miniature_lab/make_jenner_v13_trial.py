#!/usr/bin/env python3
"""Conservative Jenner torso/leg anatomy trial; NOT accepted production art.

The 2021 CGL plastic Jenner has a stepped upper torso and heavy knee/calf
armor; v12's neutral-pose side silhouette makes both too columnar.
No rig pivots, damage locations, arm pods, or existing merged art are edited.
"""
import copy
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def rounded(v):
    return round(v, 5)


def build():
    spec = json.loads((HERE / "jenner_assembly_v12.json").read_text())
    by = {p["name"]: p for p in spec["parts"]}
    for sec in by["ct"]["shapes"][0]["sections"]:
        for pt in sec["polygon"]:
            if sec["at"] == 1.34 and pt[1] > .04:
                pt[1] = rounded(.04+(pt[1]-.04)*.84)
            elif sec["at"] == 1.9 and pt[1] > .075:
                pt[1] = rounded(.075+(pt[1]-.075)*.84)
            elif sec["at"] == 2.08 and pt[1] > .08:
                pt[1] = rounded(.08+(pt[1]-.08)*.91)
    for side in ("l", "r"):
        # Do not alter thigh loft. An earlier proposed thigh adjustment
        # disconnected the independently claimed knee armor and was rejected.
        shin = by[side+"l_shin"]["shapes"][0]["sections"][1]
        xlo = min(p[0] for p in shin["polygon"])
        xhi = max(p[0] for p in shin["polygon"])
        cx = (xlo+xhi)/2
        for pt in shin["polygon"]:
            pt[0] = rounded(cx+(pt[0]-cx)*1.065)
            if pt[1] < -.03:
                pt[1] = rounded(pt[1]-.023)
            elif pt[1] > .06:
                pt[1] = rounded(pt[1]+.04)
        foot = by[side+"l_foot"]
        for p in foot["shapes"][0]["sections"][0]["polygon"]:
            if p[1] < -.24:
                p[1] = rounded(p[1]-.043)
        for shape in foot["shapes"][1:]:
            for sec in shape["sections"]:
                for p in sec["polygon"]:
                    if p[1] < -.35:
                        p[1] = rounded(p[1]-.07)
    spec["shape_refinement_revision"] = "miniature-v13-torso-leg-anatomy-trial-20261123"
    spec["reference_review"] = {
        "severity": "critical",
        "old_issue": ("torso continuous slab with too little rear lower-body taper; "
                      "legs thin Z-struts and overly squared claws"),
        "sculpt": "CGL 2021 Jenner CAT35729 / base 63",
        "reference_photos": [
            "https://www.rpgminihunter.com.au/cdn/shop/files/Fit_P1190416_Final_1200x1200.jpg?v=1708318633",
            "https://www.rpgminihunter.com.au/cdn/shop/files/Fit_P1190417_Final_1200x1200.jpg?v=1708318633"
        ],
        "trial_changes": [
            "Reduce only posterior waist and chest depth; preserve shoulder/head physical contacts",
            "Extend individual toe tips, continue subtractive toe gaps to their new ends",
            "Preserve all hip, knee, ankle pivots and independent rig ownership",
            "Do NOT broaden upper thigh: detected disconnection of its knee-armor ownership after oblique segmentation; revert that change"
        ],
        "pose_caveat": ("Standing neutral source projection is not calibrated to "
                        "actual miniature's bent and staggered leg pose. "
                        "Do not interpret neutral front similarity as proof."),
        "acceptance": ("Do not promote without per-part 2x2 contact, multi-view "
                       "camera+pose frozen reference metrics, and actual engine rig test")
    }
    return spec


if __name__ == "__main__":
    output = HERE / "jenner_assembly_v13_trial.json"
    output.write_text(json.dumps(build(), indent=2) + "\n")
    print(output)
