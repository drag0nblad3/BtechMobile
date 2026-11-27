# Voxel catalog consolidation — phase 1 preflight

The logical resource name remains `res://data/voxels/<relative-name>.json`
(including support subdirectories). Recipe IDs are not unique across variants
and shape studies, so never use the recipe's `id` as a storage key.

The proposed physical layout is `data/voxels/_catalog/`: alphabetic two-letter
Mech shards, one shard each for assets, vehicles, battle armor, and an index.
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
