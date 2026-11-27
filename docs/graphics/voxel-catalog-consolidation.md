# Voxel catalog consolidation

The logical resource name remains `res://data/voxels/<relative-name>.json`
(including support subdirectories). Recipe IDs are not unique across variants
and shape studies, so never use the recipe's `id` as a storage key.

The physical layout is `data/voxels/_catalog/`: one shard per Mech chassis (following explicit source chains and the
_shape/_voxel suffixes; no arbitrary prefix matching), one shard each for assets, vehicles, battle armor, and an index.
Each shard is valid JSON, one compact object per line, sorted by logical path.
An entry holds the original dictionary under `recipe` and the relative path
under `path`. The index stores the shard filename, UTF-8 byte offset and
length. `VxRecipeStore` reads only the requested recipe, preserves legacy
fallback and directory ordering, and shares no mutable data across threads.
The runtime still uses the same VxModel, VxVariant and VxFineCatalog logic.

Stage and validate the complete catalog using:

    python3 tools/pack_voxel_catalog.py --output /tmp/voxel-catalog

The packer verifies exact compacted record bytes, index coverage, shard array
validity and sorting. It does not delete or modify sources. Keep the legacy
files during preflight. Before removing any, audit every direct path reader,
existence check, directory enumeration and authoring script in src, tests,
tools, experiments and CI. Update authoring workflows to extract/replace
individual records without dropping the other entries. Run the full unit
and mandatory smoke suite plus both voxel pipelines and compare recipe
coverage and geometry/rig/damage signatures to the original checkout.
Only then remove individual recipes, checkpoint and repeat verification.

The procedural catalog at data/graphics/voxel_chassis.json is already bundled
and uses a separate coordinate system. It is not included in this migration.
No mesh or damage data is changed by this preflight.

## Targeted authoring commands

All commands default to data/voxels/_catalog; use --catalog /tmp/voxel-catalog
for staged output. Logical paths are unchanged. Examples (run with python3):

    tools/pack_voxel_catalog.py list
    tools/pack_voxel_catalog.py parts atlas_shape.json
    tools/pack_voxel_catalog.py extract atlas_shape.json --part la --output arm.json
    tools/pack_voxel_catalog.py diff atlas_shape.json arm.json --part la
    tools/pack_voxel_catalog.py replace atlas_shape.json arm.json --part la
    tools/pack_voxel_catalog.py reindex

Without --part, extract/diff/replace operate on the entire recipe. For source
manifests, parts lists the source path; edit the owning source explicitly.
Variant overlays can be edited by their target part name. Replacements only
rewrite the relevant chassis shard and index, preserving other records byte
for byte. Source or recipe ID changes require a full repack. Run reindex if
an edit was interrupted between the two atomic file replacements. Avoid
concurrent writers. A full recipe edit should still be followed by geometry
and rig verification; the tool is not a sculpting validator.

## Migrated catalog maintenance

The original 633 recipes were byte-verified before removing their loose
files. The 295-file layout is stored in data/voxels/_catalog. All Godot
model tests and audit tools use VxRecipeStore instead of filesystem
enumeration. Python reference tools use logical_paths/read_recipe/write_recipe.

    python3 tools/pack_voxel_catalog.py verify
    python3 tools/pack_voxel_catalog.py unpack --output /tmp/editable-voxel-tree
    python3 tools/pack_voxel_catalog.py repack --output /tmp/new-voxel-catalog

Unpack extracts exact compacted recipe bytes. Repack stages the complete
catalog including any new or revised loose authoring overrides and validates
the result; it does not overwrite the live catalog. For source/ID changes or
adding a new recipe, use repack, review its output, replace the old catalog
as a whole and remove the incorporated loose files. Older repair trial tools
can still produce loose overrides; do not commit those overrides without
repacking. Ordinary part/recipe edits use replace instead.
