#!/usr/bin/env python3
"""One-time migration: verify all packed recipes, adapt audited path consumers."""
import re
import tempfile
from pathlib import Path
from pack_voxel_catalog import pack, source_files

PATHS = [
    "tests/unit/test_advanced_unit_models.gd",
    "tests/unit/test_melee_voxel_sculpts.gd",
    "tests/unit/test_missing_mech_joint_backing.gd",
    "tests/unit/test_new_cohort_sculpts.gd",
    "tests/unit/test_new_mech_art_coverage.gd",
    "tests/unit/test_new_source_sculpts.gd",
    "tests/unit/test_new_source_voxels.gd",
    "tests/unit/test_sculpt_review_lineage.gd",
    "tests/unit/test_source_pair_goal_sculpt.gd",
    "tests/unit/test_source_resculpt_nov23.gd",
    "tests/unit/test_source_sculpt_profile_invariants.gd",
    "tests/unit/test_source_variant_resculpt_nov23.gd",
    "tests/unit/test_voxel_assets.gd",
    "tests/unit/test_voxel_detail.gd",
    "tests/unit/test_voxel_record_sheet_models.gd",
    "tests/unit/test_vx_camera_resculpt_next20.gd",
    "tests/unit/test_vx_critical_identity_mass.gd",
    "tests/unit/test_vx_fine_catalog.gd",
    "tests/unit/test_vx_imported_joint_sockets.gd",
    "tests/unit/test_vx_integrity.gd",
    "tests/unit/test_vx_livery.gd",
    "tests/unit/test_vx_missing_chassis.gd",
    "tests/unit/test_vx_model.gd",
    "tests/unit/test_vx_reference_anatomy_spotchecks.gd",
    "tests/unit/test_vx_reference_camera_resculpt.gd",
    "tests/unit/test_vx_reference_catalog_profiles.gd",
    "tests/unit/test_vx_reference_critical_confusion.gd",
    "tests/unit/test_vx_reference_distinctive_eight.gd",
    "tests/unit/test_vx_reference_final_seven.gd",
    "tests/unit/test_vx_reference_profiles.gd",
    "tests/unit/test_vx_reference_remaining_fourteen.gd",
    "tests/unit/test_vx_reference_resculpt.gd",
    "tests/unit/test_vx_reference_signatures.gd",
    "tests/unit/test_vx_resculpt_next20.gd",
    "tests/unit/test_vx_sculpt_ports.gd",
    "tests/unit/test_vx_second_fifty.gd",
    "tests/unit/test_vx_silhouette.gd",
    "tests/unit/test_vx_silhouette_identity.gd",
    "tools/capture_component_shapes.gd",
    "tools/capture_divergent_sculpts.gd",
    "tools/capture_full_voxels.gd",
    "tools/capture_melee_resculpt.gd",
    "tools/capture_new_source_review.gd",
    "tools/capture_proportion_review.gd",
    "tools/capture_silhouette_review.gd",
    "tools/export_reference_review_masks.gd",
    "tools/reference_camera_sweep.gd",
    "tools/reference_pose_sweep.gd",
    "tools/voxel_battle_bench.gd",
    "tools/voxel_multiangle_audit.gd",
    "tools/vx_catalog_integrity_audit.gd",
    "tools/vx_inherited_fragment_diagnostics.gd",
    "tools/vx_repair_inherited_sculpts.gd",
    "tests/unit/test_unit_voxel_paths.gd"
]

def adapt(repo):
    changed = []
    for rel in PATHS:
        path = repo / rel
        old = path.read_text(encoding="utf-8")
        # The view-only reader accepts existing physical files too. Leave
        # official unit-data calls alone: they have their own migration.
        new = re.sub(r'JsonFile\.read\((?!\"res://data/(?:units|vehicles|battle_armor)/)', 'VxRecipeStore.read(', old)
        new = new.replace("FileAccess.file_exists(", "VxRecipeStore.exists(")
        new = re.sub(r'DirAccess\.get_files_at\(("(?:res://data/voxels[^"]*)"|VxFineCatalog\.ROOT)\)',
                     r'VxRecipeStore.files(\1)', new)
        if path.name == "test_sculpt_review_lineage.gd":
            new = new.replace(
                '\t\t\tvar file := FileAccess.open(path, FileAccess.READ)\n'
                '\t\t\tcheck(file != null, "Missing voxel recipe: " + path)\n'
                '\t\t\tif file == null:\n\t\t\t\tcontinue\n'
                '\t\t\tvar data: Variant = JSON.parse_string(file.get_as_text())',
                '\t\t\tcheck(VxRecipeStore.exists(path), "Missing voxel recipe: " + path)\n'
                '\t\t\tif not VxRecipeStore.exists(path):\n\t\t\t\tcontinue\n'
                '\t\t\tvar data: Variant = VxRecipeStore.read(path)')
        if new != old:
            path.write_text(new, encoding="utf-8")
            changed.append(rel)
    print("VOXEL_PATH_CONSUMERS|" + str(len(changed)))
    for rel in changed:
        print(rel)


def migrate(repo):
    root = repo / "data/voxels"
    sources = source_files(root)
    out = root / "_catalog"
    if out.exists():
        raise ValueError("catalog already migrated")
    with tempfile.TemporaryDirectory() as tmp:
        staged = Path(tmp) / "catalog"
        count, shards = pack(root, staged)
        if count != len(sources):
            raise ValueError("recipe coverage mismatch")
        # Copy only after exact compacted byte comparison of every record.
        out.mkdir()
        for path in staged.iterdir():
            (out / path.name).write_bytes(path.read_bytes())
        for path in sources:
            path.unlink()
        print(f"VOXEL_MIGRATION_OK|recipes={count}|files={shards}")
    adapt(repo)


if __name__ == "__main__":
    migrate(Path(__file__).resolve().parents[1])
