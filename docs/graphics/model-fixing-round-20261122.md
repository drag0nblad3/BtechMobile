# Model fixing round — November 22, 2026

Status: **source and rig fixes on a review branch**, pending Godot CI and four-angle visual review. Not a claim of completed Catalyst miniature fidelity.

## Diagnosis and corrective changes

1. **Catalog-wide mirrored attachments.** A mirrored part without an explicit `parent` inherited the body root, even when the source was attached to a moving arm, shoulder, leg or head. `VxModel._add_part` now mirrors inherited part-name tokens (LA ↔ RA, LT ↔ RT, LL ↔ RL, left ↔ right), and preserves explicitly declared parents. This repairs right-arm fingers and shoulder plates on the Atlas, mirrored Jenner disc trim/exhausts, Wolverine cheek/leg details and other catalog variants with the same authoring pattern. Voxel ownership, pivots and hit locations are unchanged.

2. **Wolverine single cannon-arm silhouette.** Removed the separately articulated `ra_cannon_mount` loft that covered the already bent RA forearm and hand along the same diagonal. The upper arm, primary bent forearm, integrated hand/grip, AC/5 barrel shroud and muzzle remain. The removal reduces surplus source armor / duplicate-looking lower-arm mass without inventing a second weapon.

3. **Jenner flattened forward disc.** Reprofiled the two front sections of the head's longitudinal loft and kept its side rim and front window aligned. The forward tip now has a broader, rounded face instead of tapering to a narrow beak. The 20-grid-wide main disc at z=-31, its forward z=-36 landmark, shoulder laser nacelles and digitigrade leg chain remain intact.

## Validation and remaining gates

- Static checks: model JSON remains parseable; edited loft section vertex counts stay identical to neighbors; key pivots, weapon locations and muzzle arrays remain unchanged.
- Added source/regression tests in `tests/unit/test_vx_model.gd` for mirrored rig attachments, the Wolverine's single right cannon arm and Jenner disc proportions.
- Still required: **Godot import, full test suite, active animation/limb-loss test and front/side/rear/top visual approval**. Source-level review alone cannot certify all 151 models.
- No edits to `src/core/` gameplay rules. No Android APK and no fabricated renderer screenshot. No merge without approval.

## Generalized tests and whole-catalog integrity handling

- Regression assertions now use **proportional silhouettes, mirror-parent semantics, actual muzzle planes and structural invariants** instead of checking hard-coded vertex coordinates and fixed authored shape counts.
- `VxIntegrity` is called on the final occupied cells for any recipe opting into exclusive moving-part ownership, including ordinary shape-first BattleMechs, high-resolution direct loft voxelization and the 16 supported vehicles/infantry archetypes. The previous Raven/Shadow Cat-only special case is removed.
- The repair traverses each *part* separately, connects small nearby islands with a minimal, structure-colored route, and cautiously joins short explicit hinge/ankle/shoulder gaps to their parent. It does not combine two separately articulated parts.
- Source `erase` openings, the firing corridor around every muzzle and all cells owned by another part are **non-fillable**. Large/displaced islands and long articulation gaps are deliberately reported, rather than hidden with a broad rectangular support.
- A per-model `quality_report` contains disconnected components **before/after**, actual repaired islands, bridged mechanical contacts, inserted cells and fully empty parts. The topology tests translate and scale a synthetic defect, verify obstruction and cutout safety, and inspect the full catalog's source loft/mirror relationships.
- The repair is executed **after** `VxShapeRaster.rebuild`, because that stage replaces the coarse occupancy grid; fixing coarse cells alone did not reliably survive the fine visual pipeline.

**Limit:** Automated reconnection is intentionally not a promise that every deliberately detached shape has been made watertight. Remaining large or inaccessible disconnected components need source-specific inspection and a reference-based resculpt. Engine CI and multi-angle miniature comparison are required before final art approval.
