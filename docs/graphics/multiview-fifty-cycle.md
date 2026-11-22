# Fifty-pass orthographic and oblique silhouette review (2026-11-22)

Status: **source geometry changes staged for review; NOT an approved sculpt set**.

## Scope

Applied 50 ordered, deterministic review cycles to **151 BattleMech shape studies** and **16 vehicle/infantry/emplacement assets**. There are 148 low/detail mech pairs and three source-driven specialty mechs (Atlas, Jenner, Wolverine) whose detail manifests refer to their shape studies. Marauder and Timber Wolf have normal low/detail pairs. For paired models, the same contour-transform algorithm is applied to low and high recipes; specialty features are protected.

The pass focuses deliberately on **views other than head-on**:

1. Side waist depth
2. Rear upper-body overhang
3. Top-view shoulder taper
4. Side-elevation roofline
5. Rear knee and shin profile
6. Side-view heel projection
7. Forearm mass seen from behind
8. Top-view pelvis width
9. Lateral thigh profile
10. Oblique head clearance

The above ten factors repeat in five reducing-strength cycles, for 50 checks per model. Several checks leave a model unchanged when the relevant geometry or safe target is absent. **This is not 50 manual sculpt approvals per model**.

## Preservation rules

- Do not move equipment/muzzle coordinates, alter barrels or bore holes, append generic shoulder slabs, shift joint pivots, or change gameplay locations.
- Preserve fixed weapon/module shapes, authored cuts and knockout geometry, Catalyst-specific distinctive head/nose arrangements.
- Especially preserve recessed Atlas skull, forward Jenner disc, and Wolverine single integrated gun-and-hand assembly.
- Skip fragile contours with large numbers of explicit erase regions; make limited sub-cell surface refinements elsewhere.
- For support assets, retain the **50,000-voxel hard cap** and runtime guard; no new asset types or combat-stat changes.

## Review/validation status

The local source-side preview ran 50 passes on 146 paired models and 16 assets (8,100 review iterations, 4,556 with actual vertex edits, 22,816 vertex events). Repository-side changes are applied to the latest branch files rather than replacing them with an older offline backup. The three source-driven specialty sources are included in the repository-side review.

Tests check the 50-pass annotations and asset cap declarations. Godot unit tests and final voxel-count measurements must still validate the branch. **The last merged main CI baseline was already failing**, including mirror parity, model joints, and weapon-port checks. These contour edits do not claim to repair those failures. Multi-angle Catalyst comparison and scene-render approval remain outstanding.

This branch is for review only: **no merge and no APK build**.
