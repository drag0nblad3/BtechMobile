# Jenner v12 torso and leg anatomy audit

**Scope:** Catalyst Game Labs 2021 Jenner (Inner Sphere Striker Lance CAT35729 / base 63) in the *isolated* 30-part miniature laboratory only. Comparison sources: the retailer's front and oblique side photographs and the earlier same-sculpt painted four-view reference set. Source image files and copyrights remain external. This is **not** a claim that neutral-pose source geometry must match every photograph.

## Why the present silhouette looks wrong

1. **A boxy, overcontinuous centre torso.** The CT's lower ring at y=1.12 is 0.627 wide, approximately **88%** of the upper ring at y=1.90 (0.713). At y=1.34 its front–rear thickness is 0.4485, about **83%** of the 0.540 upper thickness. Therefore the waist stays almost as wide/deep as the chest instead of forming the distinct narrow pelvic/hip transition behind the projecting disc cockpit. This is an issue in the authored loft, not a pose artifact.
2. **Few anatomical controls per leg.** The v12 left/right thighs use **3 eight-sided polygon sections** each, likewise the shins. The knee armor and calf plate are real, separately owned subassemblies, but are *mostly plane-claimed fragments of these same very simple convex lofts*. An increased subassembly count alone did not create the miniature's visible joint housings, angled knee armor, calf plate layering or distinct silhouette bends.
3. **The apparent shin zigzag is partly an articulation question.** The v12 default y=0.68 knee section spans z=-0.330 to -0.015, while the y=0.23 shin/ankle section spans z=0.000 to 0.240. This makes a pronounced front-then-back zigzag in the static side render. The published plastic miniature is itself posed. **Register camera yaw/elevation/roll, perspective/framing, hip and knee rotations, and visible foot contacts FIRST**; then decide whether knee centre and shin slope require revised geometry.
4. **Feet are too blocky.** The three toe separations are subtractive, but the bounding foot remains an eight-sided rectangular tapered shell. Reference toes have individually stepped tips and more separation in the angled perspective; simply lengthening one generic rectangular foot cannot replace three sculpted toes.
5. **Feature location beats raw density.** The torso grille/cockpit mass hierarchy must remain identifiable: high backed top-grille/upper armor, projecting **lower** cockpit disc, narrow compact lower torso, side weapons attached at the correct angle. Avoid building a big box behind the cockpit or extra mass inside the body to hide attachment problems.

## What is / is not fixed by the provisional v13 trial

`jenner_assembly_v13_review.json` is intentionally **unaccepted**. It adjusts the low CT taper and inserts intermediate leg loft sections with 16-point chamfered profiles while preserving all 30 separate subassemblies and exact joint pivots. An independent JavaScript source-level occupancy/contact check found **no detached components or unsupported joints** on this trial and roughly 14,750 occupied voxels versus 15,126 in the same rasterization of v12. This is a *geometry-only diagnostic*, not a photo score or Godot test; the Python regression tests and engine renderer are still required.

**Critical finding:** at the existing **0.04** pitch, the new intermediate thigh/shin control polygons alone do not materially change the leg voxel occupancy. That is not a genuine leg resculpt. Do **not** accept v13 based on polygon count or the lower voxel count. The next effective step is to author distinct knee housings, calf plate silhouettes and three separate toe tips, with actual >1-voxel surface differences supported by the same-edition photo views.

## Acceptance gates for continuing

- Identify the *exact physical miniature edition* and license/provenance of each image; give latest Catalyst sculpt the greatest weight. Reject older or alternate sculpts as shape-fitting targets.
- Calibrate camera extrinsics, perspective/crop and all visible rig pose to each photo. **Freeze registrations across candidate sculpts.** Mask base/occluded regions and refuse to score unreliable cameras or hidden legs.
- Match **front, three-quarter, true side and top/rear** with source-resolution masks. Report per-view/part landmarks, silhouette mismatch, volume/proportion metrics and image/camera confidence. A weakly calibrated side should not override a valid front.
- Make *large, deliberate volume changes* first: CT taper, hip shape, actual knee boss/recess and moving calf armor geometry, toe tip extrusion; add polygon detail only after major shapes match. Reject bloat, generic stacked slabs, repeated identical part shapes, fake painted grooves, duplicated limbs and new floating material.
- Recompute actual occupied voxels and compare the pose-matched renders, not just source polygon counts. Verify connected interiors, backed 2×2 face-contact patches, measured attachment normals, correct rig parent order and no inter-part overlaps or auto-added bridges. Preserve weapon bores and record-sheet hit locations.
- Preserve current accepted experimental candidate (v12) and **every merged production model**. Work only in `experiments/miniature_lab/`, create draft PRs, include tests, real-geometry front/3-quarter/side/top renders and honestly report regressions.

## Sources

- https://www.rpgminihunter.com.au/products/jenner-battletech-inner-sphere-striker-lance-set-catalyst-game-lab
- https://jadedfalconer.com/Pages/1Light/jenner
- https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs

**Status:** audit finished; new candidate intentionally unaccepted until registered per-view fit and runtime rig validation. No production models touched.
