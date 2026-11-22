#!/usr/bin/env python3
"""50 sequential silhouette/weapon-quality passes on every editable voxel recipe.

Changes only art geometry. Never moves pivot points, combat hit locations,
firing-origin metadata, equipment, or gameplay statistics. Idempotent.
"""
import copy
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOX = ROOT / "data" / "voxels"
ART = VOX / "assets"
FOCUS = ["front_silhouette", "side_profile", "waist_depth", "shoulder_roof",
         "weapon_arm_clearance", "cockpit_beak", "thigh_anatomy",
         "digitigrade_shin", "ankle_and_foot", "signature_weapon_mount"]
BIRD = set("raven shadow_cat timber_wolf marauder locust flea spider fire_moth mist_lynx mad_dog summoner stormcrow cicada adder grendel kit_fox ice_ferret viper".split())
WIDE = set("king_crab stalker urbanmech annihilator kodiak turkina dire_wolf nightstar atlas longbow mauler malice cyclops".split())
QUAD = set("goliath scorpion tarantula thunder_stallion".split())
SPECIAL_HEAD = set("atlas jenner wolverine king_crab urbanmech".split())


def round5(x):
    return round(x, 5)


def apply_one(d, name, asset=False):
    counts = []
    for pass_no in range(50):
        focus = pass_no % 10
        cycle = pass_no // 10
        strength = 1.0 - cycle * 0.12
        changes = 0
        for part in d.get("parts", []):
            if "mirror" in part:
                continue
            part_name = part.get("name", "")
            for shape in part.get("shapes", []):
                loft = shape.get("loft")
                if not loft:
                    continue
                axis = loft.get("axis", "y")
                sections = loft.get("sections", [])
                for i, section in enumerate(sections):
                    phase = i / max(1, len(sections) - 1)
                    vertices = section.get("polygon", [])
                    if not vertices:
                        continue
                    xs = [v[0] for v in vertices]
                    zs = [v[1] for v in vertices]
                    cx = (min(xs) + max(xs)) / 2
                    cz = (min(zs) + max(zs)) / 2
                    for v in vertices:
                        x, z = v
                        fx = fz = 1.0
                        forward = 0.0
                        if asset:
                            if focus == 0 and part_name in ("hull", "fuselage", "base"):
                                fx = 1 - .005 * strength
                            elif focus == 1 and part_name in ("hull", "fuselage", "base"):
                                fz = 1 - .005 * strength
                            elif focus == 2 and ("turret" in part_name or "pod" in part_name):
                                fx = 1 - .004 * strength
                            elif focus == 3 and ("launcher" in part_name or "missile" in part_name):
                                fx = 1 - .003 * strength
                            elif focus == 4 and ("track" in part_name or "wheel" in part_name):
                                fx = 1 - .003 * strength
                            elif focus == 5 and ("cockpit" in part_name or "nose" in part_name):
                                fx = 1 - .003 * strength
                            elif focus == 6 and ("rotor" in part_name or "tail" in part_name):
                                fx = 1 - .003 * strength
                            elif focus == 7 and ("skirt" in part_name or "hover" in part_name):
                                fx = 1 - .003 * strength
                            elif focus == 8 and "soldier" in part_name:
                                fx = 1 - .005 * strength
                            elif focus == 9 and ("hull" in part_name or "soldier" in part_name or "fuselage" in part_name or "base" in part_name):
                                fx = 1 - .002 * strength
                        else:
                            avian = name in BIRD
                            wide = name in WIDE
                            quad = name in QUAD
                            if focus == 0 and part_name == "ct" and axis == "y" and not quad:
                                fx = 1 - (.003 if wide else .007 if phase < .28 else .002) * strength
                            elif focus == 1 and part_name == "ct" and axis == "y":
                                fz = 1 - (.007 if avian else .003) * strength
                            elif focus == 2 and part_name in ("ct", "pelvis") and axis == "y" and phase < .36 and not quad:
                                fx = 1 - (.010 if not wide else .003) * strength
                            elif focus == 3 and part_name in ("lt", "rt") and axis == "y" and phase > .30:
                                fx = 1 - (.007 if not wide else .002) * strength
                            elif focus == 4 and part_name in ("la", "ra") and axis == "y" and phase > .35:
                                fx = 1 - .008 * strength
                            elif focus == 5 and part_name == "hd" and axis == "y" and name not in SPECIAL_HEAD:
                                fx = 1 - .003 * strength
                                if avian and z < cz:
                                    forward = .045 * strength
                            elif focus == 6 and part_name in ("ll", "rl") and axis == "y" and not quad:
                                fx = 1 - .004 * strength
                            elif focus == 7 and "shin" in part_name and axis == "y":
                                fx = 1 - .007 * strength
                            elif focus == 8 and ("foot" in part_name or "tarsus" in part_name) and axis == "y":
                                fx = 1 - (.005 if avian else .002) * strength
                            elif focus == 9 and any(w in part_name for w in ("cannon", "rack", "lrm", "srm", "gun", "gauss", "launcher")) and axis == "y":
                                fx = 1 - .002 * strength
                        nx = cx + (x - cx) * fx
                        nz = cz + (z - cz) * fz - forward
                        if abs(nx - x) > 0.000001 or abs(nz - z) > 0.000001:
                            v[0], v[1] = round5(nx), round5(nz)
                            changes += 1
        counts.append(changes)
    d["art_quality_passes"] = 50
    d["art_quality_revision"] = "50-stage-source-review-20261121"
    return counts


def is_already_done(d):
    return int(d.get("art_quality_passes", 0)) >= 50


def write(path, d):
    path.write_text(json.dumps(d, indent=2) + "\n")


def main():
    audit = {"mechs": {}, "assets": {}, "stages": FOCUS, "source_changed": 0}
    for low_path in sorted(VOX.glob("*_shape.json")):
        name = low_path.name[:-11]
        high_path = VOX / (name + ".json")
        paths = [low_path] + ([high_path] if high_path.exists() else [])
        original = [json.loads(p.read_text()) for p in paths]
        if all(is_already_done(d) for d in original):
            audit["mechs"][name] = {"passes": 50, "already_reviewed": True}
            continue
        models = [copy.deepcopy(d) for d in original]
        scores = [apply_one(d, name) for d in models]
        # Primary loft contours MUST agree between low/high LOD models.
        if len(models) == 2:
            lo_parts = {p["name"]: p for p in models[0].get("parts", [])}
            for high_part in models[1].get("parts", []):
                low_part = lo_parts.get(high_part["name"], {})
                for i, sh in enumerate(high_part.get("shapes", [])):
                    source_shapes = low_part.get("shapes", [])
                    if "loft" in sh and i < len(source_shapes) and "loft" in source_shapes[i]:
                        if source_shapes[i]["loft"] != sh["loft"]:
                            sh["loft"] = copy.deepcopy(source_shapes[i]["loft"])
        for p, d in zip(paths, models):
            write(p, d)
            audit["source_changed"] += 1
        audit["mechs"][name] = {"passes": 50, "edited_vertices": sum(sum(x) for x in scores)}
    for asset_path in sorted(ART.glob("*.json")):
        model = json.loads(asset_path.read_text())
        if is_already_done(model):
            audit["assets"][asset_path.stem] = {"passes": 50, "already_reviewed": True}
            continue
        old = copy.deepcopy(model)
        counts = apply_one(model, asset_path.stem, True)
        # Never raise the declared cap. The in-engine occupancy guard remains authoritative.
        if int(model.get("voxel_cap", 50000)) > 50000:
            raise ValueError("Asset cap exceeds 50k: " + asset_path.name)
        write(asset_path, model)
        audit["source_changed"] += 1
        audit["assets"][asset_path.stem] = {"passes": 50, "edited_vertices": sum(counts)}
    target = ROOT / "docs" / "graphics" / "fifty_pass_source_quality_report.json"
    write(target, audit)
    print("50-pass source quality report:", audit["source_changed"], "files changed")


if __name__ == "__main__":
    main()
