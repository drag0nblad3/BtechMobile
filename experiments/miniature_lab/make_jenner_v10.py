"""Reproduce independent Jenner v10 from v9 without touching merged art.

The actual source v9 recipe is the input (not an older experimental branch);
both weapon pods, both paired bores, and both muzzle origins are transformed
in the same coordinate system.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def rescale_pod_x(x):
    sign = 1 if x >= 0 else -1
    return round(sign*(.56+(abs(x)-.48)*(.395/.475)), 5)


def rescale_shoulder_x(x):
    sign = 1 if x >= 0 else -1
    return round(sign*(.36+(abs(x)-.36)*(.20/.12)), 5)


def make_vent(side):
    sign = 1 if side == "r" else -1
    polygon = [[round(sign*x, 5), y]
               for x, y in ((.409,2.056),(.446,2.079),
                            (.528,1.957),(.498,1.936))]
    return {"axis":"z", "mat":"armor", "op":"subtract", "sections":[
        {"at":-.30, "polygon": polygon},
        {"at":-.206, "polygon": polygon}]}


def build():
    spec = json.loads((HERE/"jenner_assembly_v9.json").read_text())
    by = {p["name"]:p for p in spec["parts"]}
    for side in ("l", "r"):
        shoulder = by[side+"t"]
        for shape in shoulder["shapes"]:
            for sec in shape["sections"]:
                for point in sec["polygon"]:
                    point[0] = rescale_shoulder_x(point[0])
        shoulder["shapes"].append(make_vent(side))
        pod = by[side+"a"]
        for shape in pod["shapes"]:
            if shape["axis"] == "x":
                for sec in shape["sections"]:
                    sec["at"] = rescale_pod_x(sec["at"])
            else:
                for sec in shape["sections"]:
                    for point in sec["polygon"]:
                        point[0] = rescale_pod_x(point[0])
        pod["pivot"][0] = round((1 if side == "r" else -1)*.54, 5)
        for point in spec["muzzles"][pod["loc"]]:
            point[0] = rescale_pod_x(point[0])
    spec["shape_refinement_revision"] = (
        "miniature-v10-shoulder-pod-layout-20261123")
    spec["shape_fit_notes"]["shoulders"] = (
        "Outer shoulder armor broadened and angled; pods compressed toward "
        "their outboard caps without exceeding previous outer silhouette")
    spec["shape_fit_notes"]["pod_alignment"] = (
        "Port bores, barrel supports and muzzle transforms mapped together, "
        "no duplicate arms")
    return spec


if __name__ == "__main__":
    output = HERE/"jenner_assembly_v10.json"
    output.write_text(json.dumps(build(), indent=2)+"\n")
    print("Generated", output)
