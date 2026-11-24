#!/usr/bin/env python3
"""Rebuild Jenner thigh anatomy, then reattach knee and shin deliberately.

Earlier sculpt attempts were abandoned when a prior partition isolated the
knee. This generator retains the revised mechanical mass and rebuilds the
interface, ownership cut, angular contact and hinge pivots AFTER sculpting.
No hidden bridges and no modification to main's Jenner.
"""
import json
from pathlib import Path

import miniature_lab as geo
import reattach_after_resculpt as mount

HERE=Path(__file__).resolve().parent


def rounded(x):
    return round(x,5)


def octagon(cx,cz,rx,rz):
    return [[rounded(cx+x),rounded(cz+z)] for x,z in
            ((-.78*rx,-rz),(.78*rx,-rz),(rx,-.78*rz),(rx,.78*rz),
             (.78*rx,rz),(-.78*rx,rz),(-rx,.78*rz),(-rx,-.78*rz))]


def resculpt_thighs(spec):
    by={p["name"]:p for p in spec["parts"]}
    for side,sign in (("l",-1),("r",1)):
        thigh=by[side+"l"]
        loft=thigh["shapes"][0]
        section=loft["sections"][1]
        xs=[p[0] for p in section["polygon"]]
        cx=(min(xs)+max(xs))/2
        for p in section["polygon"]:
            p[0]=rounded(cx+(p[0]-cx)*1.07)
            if p[1]<-.08:
                p[1]=rounded(p[1]-.045)
            elif p[1]>.03:
                p[1]=rounded(p[1]+.028)
        # Anatomical transition BELOW the bulkiest upper thigh.
        loft["sections"].insert(1,{"at":.795,
                                   "polygon":octagon(sign*.37,-.158,.142,.178)})
        # Separate exterior knuckle loft, fused physically into the
        # authored thigh mass; the cut below gives it correct ownership.
        thigh["shapes"].append({
            "axis":"y","mat":"armor","op":"add",
            "sections":[
                {"at":.705,"polygon":octagon(sign*.37,-.245,.122,.141)},
                {"at":.83,"polygon":octagon(sign*.37,-.244,.106,.120)}
            ]})
    return spec


def rebuild_knee_mounts(spec):
    by={p["name"]:p for p in spec["parts"]}
    for side,sign in (("l",-1),("r",1)):
        thigh_name,shin_name,cuff_name=(side+"l",side+"l_shin",
                                        side+"l_knee_armor")
        # These raw source masses must be evaluated BEFORE claim/split.
        thigh=geo.rasterize({"pitch":spec["pitch"],
                             "parts":[by[thigh_name]]})[thigh_name]
        shin=geo.rasterize({"pitch":spec["pitch"],
                            "parts":[by[shin_name]]})[shin_name]
        cut={"normal":[0,-1,.24], "origin":[0,.825,-.14]}
        candidate=mount.find_reattachment(
            thigh,spec["pitch"],[cut],downstream=(shin,),
            target=[0,.825,-.14])
        if candidate["errors"]:
            raise ValueError("cannot reattach "+cuff_name)
        mount.apply_to_spec(spec,cuff_name,cut,
                            pivot=[sign*.37,.79,-.16],
                            downstream_pivots={
                                shin_name:[sign*.37,.68,-.14]})
        # Keep the readable authored unnormalized normal from the source
        # plane; direction-only checks normalize it when validating.
        by[cuff_name]["attach_normal"]=[0,1,-.24]
        by[cuff_name]["angle_tolerance_deg"]=38
    return spec


def build():
    spec=json.loads((HERE/"jenner_assembly_v15_trial.json").read_text())
    resculpt_thighs(spec)
    rebuild_knee_mounts(spec)
    spec["shape_refinement_revision"]=(
        "miniature-v16-thigh-resculpt-reattached-knees")
    spec["reference_review"].update({
        "reattach_policy":"Sculpt anatomy first, then re-partition and re-anchor joints to the new true interface; do not discard sculpt solely because old joint plane disconnects it. Never auto-fill seams.",
        "old_shin_pivot":"z=0 was at rear of knee interface; re-anchor physical shin hinge to z=-.14 inside knee cross-section",
        "thigh_rebuild":"Four-station thigh loft plus a real supported forward knee-knuckle 2-station loft; symmetric L/R; local negative-space retained",
        "knee_reattach":"Re-cut lower thigh as separately owned knee at oblique plane normal (0,-1,0.24) through (0,.825,-.14), move knee articulation pivot to (±.37,.79,-.16)",
        "status":"isolated experimental candidate, not production"})
    return spec


if __name__=="__main__":
    output=HERE/"jenner_assembly_v16_trial.json"
    output.write_text(json.dumps(build(),indent=2)+"\n")
    print(output)
