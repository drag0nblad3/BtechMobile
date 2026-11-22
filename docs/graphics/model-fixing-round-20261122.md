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
