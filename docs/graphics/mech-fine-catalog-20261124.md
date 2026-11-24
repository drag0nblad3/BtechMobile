# Mech fine-detail display/export tier

The normal battle recipe and low-resolution source stay untouched. The new
opt-in tier enumerates the top-level `data/voxels/*.json` directory, including
unit-specific weapon overlays. Paired `_shape` studies resolve to their existing
normal recipe; a future shape-only file is eligible directly. Assets, vehicles
and battle armor live in subdirectories and are not processed.

The builder resolves source chains and loads the actual occupied model, then
chooses a measured uniform lattice scale toward **150,000 occupied cells**.
Existing versions at or above the target are retained at their authored density.
New versions never inflate the physical size or use fake cell counts. Each old
cell maps to a complete nonempty cuboid on shared integer boundaries: holes,
material ownership, bilateral symmetry, and attached geometry are preserved.
This is topology-preserving upsampling of the existing voxel sculpt, not a new
continuous photographic reconstruction. Fine-cell rounding can change the
physical surface by a fraction of one voxel.

The separate backed surface-detail pass chooses flat patches on each individual
torso, helmet rear, limb or greave. Broad torso plates receive two short shallow slots with an uncut rib; limbs receive inspection-panel seams. Every cut has two solid backing layers. Larger plates can receive multiple nonoverlapping details. It never creates floating parts, edits forward weapon
faces, or replaces authored optics, barrels and launch holes. A part with no
safe patch is skipped rather than inventing one. Existing authored fine
details stay present. This automatic pass is not a hand-reviewed miniature
detail match.

## Use

In Claude Voxel Test, toggle FINE 150K to build the selected model at the new
tier. The original mode remains the default. Fine meshes and damage orders are
not retained in the normal battle cache.

For actual offline occupied-cell files and per-model counts:

```sh
godot --headless --import
godot --headless -s tools/vx_fine_catalog_build.gd -- /tmp/fine 0 1
```

The dedicated PR workflow builds eight nonoverlapping shards and uploads
compressed `.vx150` native Godot Variant payloads, including every occupied
cell, material, part hierarchy, socket, and model pitch. Each shard contains
a JSON count and topology report. To read a payload use
`FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)`
and `get_var(false)`. The showcase can rebuild from source without these CI
artifacts. Audit warnings, missing safe detail sites or low counts must be reviewed rather than called a successful 150k conversion; original geometry may already contain islands. The builder reports source and final islands independently, and rejects any topology regression or new budget overrun.
No render, APK, or gameplay-rule changes are involved.

Verification: synthetic topology and backed-recess unit tests, Hunchback
occupied-cell target test, full directory export and per-model topology reports.
The exact catalog counts and visual quality require a real Godot run and
reference-aligned review before acceptance.
