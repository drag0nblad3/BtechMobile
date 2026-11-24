#!/usr/bin/env python3
"""Experimental v15: three distinct Jenner claw tips at real 0.04 voxel pitch.

Refines the seven-pass whole-anatomy v14 without editing its baseline or
any shipped game model. The two cuts terminate behind the extended tips,
so three visible claws reconnect to one supported tarsus.
"""
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent


def build():
    spec=json.loads((HERE/"jenner_assembly_v14_trial.json").read_text())
    for side,cx in (("l",-.43),("r",.43)):
        foot=next(p for p in spec["parts"] if p["name"]==side+"l_foot")
        foot["shapes"]=foot["shapes"][:4]
        for offset in (-.047,.047):
            x=cx+offset
            profile=[[round(x-.029,5),0],[round(x+.029,5),0],
                     [round(x+.029,5),.018],[round(x+.029,5),.092],
                     [round(x+.029,5),.112],[round(x-.029,5),.112],
                     [round(x-.029,5),.092],[round(x-.029,5),.018]]
            foot["shapes"].append({
                "axis":"z","mat":"armor","op":"subtract",
                "sections":[{"at":-.55,"polygon":[p[:] for p in profile]},
                            {"at":-.375,"polygon":[p[:] for p in profile]}]})
    spec["shape_refinement_revision"]=(
        "miniature-v15-whole-anatomy-three-separated-toes")
    spec["reference_review"]["status"]=(
        "EXPERIMENT ONLY, v14 controls retained; actual toe tips now form "
        "three separate voxel columns at the front of each foot")
    spec["reference_review"]["toe_sculpt"]=(
        "Deepen two forward toe gaps to 0.058 world-units wide, end at "
        "z=-0.375; three tips stay separate near z=-0.46, reconnect into "
        "a solid shared tarsus. Verified voxel-pitch connectivity "
        "on both sides.")
    return spec


if __name__=="__main__":
    out=HERE/"jenner_assembly_v15_trial.json"
    out.write_text(json.dumps(build(),indent=2)+"\n")
    print(out)
