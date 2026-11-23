#!/usr/bin/env python3
"""Reproducible five-pass Jenner v12 resculpt using additional same-sculpt views.

Reads ONLY v11 experimental geometry. Does not alter merged game models.
"""
import copy
import json
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent


def r(x):
    return round(x, 5)


def ellipse(x, y, rx, ry, n=16):
    return [[r(x+rx*math.cos(2*math.pi*i/n)),
             r(y+ry*math.sin(2*math.pi*i/n))] for i in range(n)]


def as_parts(spec):
    return {p["name"]:p for p in spec["parts"]}


def reshape_disc(spec):
    head = as_parts(spec)["hd"]
    for shape in head["shapes"]:
        for sec in shape["sections"]:
            for point in sec["polygon"]:
                point[0] = r(point[0]*1.08)


def separate_glazing(spec):
    head = as_parts(spec)["hd"]
    for shape in head["shapes"][1:4]:
        for sec in shape["sections"]:
            center = sum(p[0] for p in sec["polygon"])/len(sec["polygon"])
            for p in sec["polygon"]:
                p[0] = r(center+(p[0]-center)*.6)


def recessed_grille(spec):
    ct = as_parts(spec)["ct"]
    original = ct["shapes"]
    if len(original)!=22 or any(s.get("op")!="subtract" for s in original[3:15]):
        raise ValueError("Unexpected v11 torso loft; refuse silent geometry drift")
    holes = []
    for y in (1.835, 1.90, 1.965, 2.03):
        for x in (-.165, -.055, .055, .165):
            shape = ellipse(x, y, .0195*1.18, .024*1.09)
            holes.append({"axis":"z", "mat":"armor", "op":"subtract",
                          "sections":[{"at":-.33, "polygon":copy.deepcopy(shape)},
                                      {"at":-.185, "polygon":copy.deepcopy(shape)}]})
    ct["shapes"] = original[:3]+holes+original[15:]


def shoulder_fairings(spec):
    parts = as_parts(spec)
    for side in ("lt","rt"):
        sections = parts[side]["shapes"][0]["sections"]
        for index, dy in ((-2,.009), (-1,.02)):
            sec=sections[index]
            sec["at"]=r(sec["at"]+dy)
            for p in sec["polygon"]:
                p[1]=r(p[1]+.0036)


def narrow_toes(spec):
    parts = as_parts(spec)
    for side, sign in (("l",-1), ("r",1)):
        foot = parts[side+"l_foot"]
        center = sign*.43
        for i, shape in enumerate(foot["shapes"]):
            for sec in shape["sections"]:
                w = 1. if sec["at"]<=.065 else (.5 if sec["at"]<=.106 else 0.)
                for p in sec["polygon"]:
                    p[0]=r(center+(p[0]-center)*(1-.1*w))
                    if i==0 and sec["at"]<=.106 and p[1]<-.18:
                        p[1]=r(p[1]-.0125)


PASSES = (
    ("01_disc", reshape_disc), ("02_glazing", separate_glazing),
    ("03_grille", recessed_grille), ("04_shoulders", shoulder_fairings),
    ("05_toes", narrow_toes)
)


def build_stages():
    spec = json.loads((HERE/"jenner_assembly_v11.json").read_text())
    stages=[("00_v11_control",copy.deepcopy(spec))]
    for name, action in PASSES:
        action(spec)
        spec["shape_refinement_revision"]="miniature-v12-"+name
        stages.append((name,copy.deepcopy(spec)))
    return stages


def build():
    spec=build_stages()[-1][1]
    spec["shape_refinement_revision"]="miniature-v12-multisource-20261123"
    spec["multi_reference"]={
       "sculpt":"Catalyst 2021 plastic CAT35729 base 63",
       "original_painted_collage":"jenner_photo_annotations.json",
       "added_unpainted_photos":"jenner_additional_reference_views.json",
       "frozen_camera_and_pose":"v11 control; same per-photo camera, crop and leg posture used across candidates",
       "held_out_oblique_side":"Poor 0.114 crop camera-registration residual; upper-body only diagnostic, never used to justify improvement",
       "passes":["widen projecting cockpit disc 8%",
                 "physically separated three forward glazing panels",
                 "four-by-four negative-space upper grille",
                 "slope the upper shoulder armor 0.02 model units",
                 "taper both three-toe feet without moving attachment pivots"],
       "limitations":"Preview-scale image annotations have ±8–15 px uncertainty. No real lens calibration. Quantitative scores provisional."
    }
    return spec


if __name__=="__main__":
    output=HERE/"jenner_assembly_v12.json"
    output.write_text(json.dumps(build(),indent=2)+"\n")
    print("Built experimental",output)
