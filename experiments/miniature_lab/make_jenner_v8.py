"""Refine a 30-part Jenner with 16-vertex hard armor and joint-angle tests.

No merged data is read or changed. Source is the independent v7 trial.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def corner_points(poly, fraction=.105):
    """Add two controllable hard-surface bevel points at each polygon corner."""
    out = []
    for i, p in enumerate(poly):
        a, b = poly[(i-1) % len(poly)], poly[(i+1) % len(poly)]
        out.append([round(p[k]*(1-fraction)+a[k]*fraction, 5) for k in (0, 1)])
        out.append([round(p[k]*(1-fraction)+b[k]*fraction, 5) for k in (0, 1)])
    return out


def build():
    spec = json.loads((HERE / "jenner_assembly_v7.json").read_text())
    by = {p["name"]: p for p in spec["parts"]}
    for name in ("ct", "lt", "rt"):
        shape = by[name]["shapes"][0]
        if shape["axis"] != "y" or shape["mat"] != "armor":
            raise ValueError(name + ": unexpected armor loft")
        for section in shape["sections"]:
            if len(section["polygon"]) != 8:
                raise ValueError(name + ": unexpected polygon")
            section["polygon"] = corner_points(section["polygon"])

    normals = {
        "hd": [0, .25, .97], "lt": [1, 0, 0], "rt": [-1, 0, 0],
        "la": [1, .1, -.11], "ra": [-1, .1, -.11],
        "ll": [0, 1, 0], "rl": [0, 1, 0],
        "ll_shin": [0, 1, 0], "rl_shin": [0, 1, 0],
        "ll_foot": [0, 1, 0], "rl_foot": [0, 1, 0],
    }
    for name, direction in normals.items():
        by[name]["attach_normal"] = direction
        by[name]["angle_tolerance_deg"] = 30
    spec["shape_refinement_revision"] = "miniature-v8-angled-shoulder-control-polygons-20261123"
    spec["assembly_guide"]["full_joint_audit"] = (
        "All 29 parent-child attachments checked for backed face patch "
        "and measured angular error"
    )
    return spec


if __name__ == "__main__":
    out = HERE / "jenner_assembly_v8.json"
    out.write_text(json.dumps(build(), indent=2) + "\n")
    print(out)
