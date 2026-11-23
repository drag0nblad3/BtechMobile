# Record-sheet support voxel models — isolated import

This brings over the 29 distinct record-sheet visual recipes from #192/#242 without importing the 42 BattleMech models that currently fail the physical joint audit. It contains 22 vehicle and 7 battle-armor JSON models, each with a declared 50,000 occupied-voxel cap, and hooks them up through `VoxelAsset` for applicable record sheets. When a specific recipe is absent or fails validation, the existing placeholder remains in use.

## Safety and provenance

- No official unit design files, gameplay rules, RNG or damage decisions change.
- The original support-model JSON blobs are preserved byte-for-byte; this PR does not claim new model refinements or reference approval.
- The original #242/#244 Mech cohort is **not** safe to merge: its multi-angle audit reported 203 weak joints despite zero floating component islands. Those need part-by-part structural fixes, not relaxed tests or generic bulk inflation.
- Verify this batch with `tests/unit/test_voxel_record_sheet_models.gd`, the full Godot tests, UI smoke and stress performance checks before merging. No APK build.
