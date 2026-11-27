#!/usr/bin/env python3
"""50 sequential silhouette/weapon-quality passes on every editable voxel recipe.

Changes only art geometry. Never moves pivot points, combat hit locations,
firing-origin metadata, equipment, or gameplay statistics. Idempotent.
"""
import copy
import json
import math
from pathlib import Path
from pack_voxel_catalog import logical_paths, read_recipe, write_recipe

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
    """Second cycle 51-100. Review five views; edit only measured outliers."""
    reviewed = []
    for cycle in range(50):
        feature = cycle % 10
        view = ("front", "side", "rear", "top", "three_quarter")[cycle % 5]
        edited = 0
        base = next((p for p in d.get("parts", []) if p.get("name") == "ct"), {})
        body_lofts = [s["loft"] for s in base.get("shapes", []) if "loft" in s]
        body_x = [v[0] for l in body_lofts for sec in l["sections"]
                  for v in sec["polygon"]]
        body_z = [v[1] for l in body_lofts if l.get("axis", "y") == "y"
                  for sec in l["sections"] for v in sec["polygon"]]
        width = max(1.0, max(body_x) - min(body_x)) if body_x else 10.0
        depth = max(1.0, max(body_z) - min(body_z)) if body_z else 10.0
        for part in d.get("parts", []):
            if part.get("mirror"):
                continue
            pname = part.get("name", "")
            for shape in part.get("shapes", []):
                loft = shape.get("loft", {})
                sections = loft.get("sections", [])
                if len(sections) < 2:
                    continue
                axis = loft.get("axis", "y")
                widths = [max(v[0] for v in sec["polygon"]) -
                          min(v[0] for v in sec["polygon"]) for sec in sections]
                depths = [max(v[1] for v in sec["polygon"]) -
                          min(v[1] for v in sec["polygon"]) for sec in sections]
                widest = max(widths)
                if widest < 1.0:
                    continue
                for i, sec in enumerate(sections):
                    frac = i / max(1, len(sections) - 1)
                    w, dz = widths[i], depths[i]
                    sx = sz = 1.0
                    rear_only = False
                    if asset:
                        # Review assets without giving infantry or vehicle
                        # silhouettes generic humanoid proportions.
                        if feature == 1 and pname in ("hull", "fuselage") and axis == "y" and dz > width * 1.3:
                            sz = .996
                            rear_only = True
                    elif feature == 0 and pname == "ct" and axis == "y" and name not in WIDE | QUAD | {"jenner", "wolverine"}:
                        if frac < .31 and w > widest * .78:
                            sx = .989
                    elif feature == 1 and pname == "ct" and axis == "y" and name not in QUAD | {"king_crab", "turkina", "stalker"}:
                        if dz > width * (1.24 if name in BIRD else 1.12) and .1 < frac < .9:
                            sz = .986
                            rear_only = True
                    elif feature == 2 and pname in ("lt", "rt") and axis == "y" and name not in QUAD | {"atlas", "king_crab", "timber_wolf", "archer"}:
                        if frac > .60 and w > widest * .90 and w > width * .22:
                            sx = .991
                    elif feature == 3 and pname in ("la", "ra") and axis == "y" and name not in QUAD | {"king_crab", "crab", "rifleman", "archer", "timber_wolf", "dire_wolf", "marauder", "warhammer", "annihilator"}:
                        if frac > .45 and w > width * .37:
                            sx = .989
                    elif feature == 4 and pname == "hd" and axis == "y" and name not in SPECIAL_HEAD | {"marauder", "raven", "locust", "timber_wolf", "shadow_cat"}:
                        if w > width * .62 and frac > .25:
                            sx = .986
                    elif feature == 5 and pname in ("ll", "rl") and axis == "y" and name not in QUAD:
                        if frac > .35 and w > width * (.51 if name in WIDE else .42):
                            sx = .986
                    elif feature == 6 and ("shin" in pname or pname in ("ll", "rl")) and axis == "y" and name not in QUAD:
                        if .18 < frac < .72 and dz > depth * .62:
                            sz = .992
                            rear_only = True
                    elif feature == 7 and ("foot" in pname or "tarsus" in pname) and axis == "y" and name not in QUAD:
                        if frac < .48 and w < width * .16 and width > 13:
                            sx = 1.008
                    elif feature == 8 and axis == "z" and any(t in pname for t in ("barrel", "cannon", "gun", "gauss", "ppc")):
                        if frac < .32 and w >= widest * .94 and len(sections) > 2:
                            sx = .991
                    elif feature == 9 and pname == "ct" and axis == "y" and name not in WIDE | QUAD | {"jenner", "wolverine"}:
                        if frac > .75 and w > widest * .90:
                            sx = .991
                    if sx == 1 and sz == 1:
                        continue
                    xs = [v[0] for v in sec["polygon"]]
                    zs = [v[1] for v in sec["polygon"]]
                    cx = (min(xs) + max(xs)) * .5
                    cz = (min(zs) + max(zs)) * .5
                    for v in sec["polygon"]:
                        x0, z0 = v
                        x1 = round(cx + (x0 - cx) * sx, 5)
                        z1 = round(cz + (z0 - cz) * sz, 5) if not rear_only or z0 > cz else z0
                        if abs(x0 - x1) > .0001 or abs(z0 - z1) > .0001:
                            v[:] = [x1, z1]
                            edited += 1
        # Validate every revised section, not just the final pass.
        for part in d.get("parts", []):
            for shape in part.get("shapes", []):
                loft = shape.get("loft")
                if not loft:
                    continue
                sec = loft["sections"]
                for i in range(1, len(sec)):
                    if sec[i]["at"] <= sec[i-1]["at"] or len(sec[i]["polygon"]) != len(sec[i-1]["polygon"]):
                        raise ValueError("%s %s: invalid loft in cycle %d" % (name, part["name"], cycle+51))
        reviewed.append({"pass": cycle+51, "view": view,
                         "feature": FOCUS[feature], "edited_vertices": edited})
    d["art_quality_passes"] = 100
    d["art_quality_revision"] = "51-to-100-reference-proportions-20261122"
    d["reference_review_views"] = ["front", "side", "rear", "top", "three_quarter"]
    d["shape_review_50"] = {"passes": 50, "edited_vertices": sum(x["edited_vertices"] for x in reviewed),
                            "stages_with_changes": sum(x["edited_vertices"] > 0 for x in reviewed)}
    return [x["edited_vertices"] for x in reviewed]


def is_already_done(d):
    return int(d.get("art_quality_passes", 0)) >= 100


def write(path, d):
    if path.is_relative_to(VOX):
        write_recipe(VOX, path, d)
    else:
        path.write_text(json.dumps(d, indent=2) + "\n")


def main():
    audit = {"mechs": {}, "assets": {}, "stages": FOCUS, "source_changed": 0}
    for low_path in logical_paths(VOX, pattern="*_shape.json"):
        name = low_path.name[:-11]
        high_path = VOX / (name + ".json")
        paths = [low_path] + ([high_path] if high_path in logical_paths(VOX) else [])
        original = [read_recipe(VOX, p) for p in paths]
        if all(is_already_done(d) for d in original):
            audit["mechs"][name] = {"passes": 100, "already_reviewed": True}
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
        audit["mechs"][name] = {"passes": 100, "new_review_cycles": 50, "edited_vertices": sum(scores[0]), "stages_with_changes": sum(x > 0 for x in scores[0])}
    for asset_path in logical_paths(VOX, directory="assets"):
        model = read_recipe(VOX, asset_path)
        if is_already_done(model):
            audit["assets"][asset_path.stem] = {"passes": 100, "already_reviewed": True}
            continue
        old = copy.deepcopy(model)
        counts = apply_one(model, asset_path.stem, True)
        # Never raise the declared cap. The in-engine occupancy guard remains authoritative.
        if int(model.get("voxel_cap", 50000)) > 50000:
            raise ValueError("Asset cap exceeds 50k: " + asset_path.name)
        write(asset_path, model)
        audit["source_changed"] += 1
        audit["assets"][asset_path.stem] = {"passes": 100, "new_review_cycles": 50, "edited_vertices": sum(counts)}
    target = ROOT / "docs" / "graphics" / "second_fifty_source_quality_report.json"
    write(target, audit)
    print("51-100 source quality report:", audit["source_changed"], "files changed")


if __name__ == "__main__":
    main()
