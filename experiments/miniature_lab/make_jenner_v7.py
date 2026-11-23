"""Generate a 30-subassembly Jenner with mirrored oblique load-bearing cuts.

This experiment reads only existing experimental v5/v6 files. Partitioned
pieces transfer source cells without adding bridge material or modifying
production art. All output paths stay under experiments/miniature_lab/.
"""
import copy
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def transfer(name, loc, parent, owner, planes, normal, pivot, degrees=32, kind="rigid"):
    return {
        "name": name, "loc": loc, "parent": parent, "claim_from": owner,
        "subassembly_kind": kind, "pivot": pivot, "shapes": [],
        "partition": {"planes": [
            {"normal": normal_vector, "origin": point} for normal_vector, point in planes
        ]},
        "attach_normal": normal, "angle_tolerance_deg": degrees,
    }


def build():
    early = json.loads((HERE / "jenner_assembly_v5.json").read_text())
    recent = json.loads((HERE / "jenner_assembly_v6.json").read_text())
    spec = copy.deepcopy(recent)
    old = {p["name"]: p for p in early["parts"]}
    # Only cockpit and sidepods retain 16-to-32-vertex sculpt upgrades.
    # Other automatic smoothing degrades some reference fits; keep it out.
    for i, part in enumerate(spec["parts"][:len(early["parts"])]):
        if part["name"] not in ("hd", "la", "ra"):
            p = copy.deepcopy(old[part["name"]])
            p["parent"] = part.get("parent")
            spec["parts"][i] = p
    spec["shape_refinement_revision"] = "miniature-v7-30part-oblique-20261123"
    spec["assembly_guide"].update({
        "edition": "CGL Inner Sphere Striker Lance 2021 / 35729",
        "angular_joints": "Backed 2x2 faces, measured oblique contact normals",
        "symmetry": "Mirror cut planes, verify both sides separately",
        "smooth_contours": "32-point cockpit and pod loft sections",
        "no_invented_bloat": "Transfer owned cells; never bridge or add volume",
    })
    parts = spec["parts"]
    for sign, side in ((-1, "l"), (1, "r")):
        parts.append(transfer(
            "hd_" + side + "_cheek", "HD", "hd_nose_shell", "hd_nose_shell",
            [([sign, -.02, -.20], [sign * .14, 1.57, -1.045])],
            [-sign, .02, .20], [sign * .14, 1.57, -1.045],
            30, "nose_cheek_plate"))
        arm, torso = side + "a", side + "t"
        socket = arm + "_inboard_socket"
        parts.append(transfer(
            socket, "LA" if sign < 0 else "RA", torso, arm,
            [([-sign, .11, -.12], [sign * .655, 1.80, .01])],
            [-sign, -.11, .12], [sign * .65, 1.8, .01],
            30, "angled_shoulder_socket"))
        for part in parts:
            if part["name"] == arm:
                part["parent"] = socket
    parts.append(transfer(
        "ct_lower_skirt", "CT", "ct", "ct",
        [([0, -1, .14], [0, 1.41, 0])],
        [0, 1, -.14], [0, 1.41, 0], 34, "waist_skirt"))
    for part in parts:
        if part["name"] in ("ll", "rl"):
            part["parent"] = "ct_lower_skirt"
    return spec


if __name__ == "__main__":
    output = HERE / "jenner_assembly_v7.json"
    output.write_text(json.dumps(build(), indent=2) + "\n")
    print("Wrote", output)
