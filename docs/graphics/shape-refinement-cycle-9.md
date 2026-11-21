# Reference silhouette refinement — pass 9

**Review stage: low-resolution components only; not approved for detail.**
This branch changes the *geometry* of each mech, not voxel density, surface trim, damage, animation, or the APK. Keep one combined three-quarter Godot render per iteration.

| Chassis | Primary image | Secondary image | Geometry corrected |
| --- | --- | --- | --- |
| Atlas AS7-D | [Scull-and-shoulder reference, unpainted CAD](https://www.deviantart.com/lizzygibbs3d/art/FAN-ART-BattleTech-MechWarrior-AS-7-D-Atlas-551614099) | [Current tabletop sculpt, three-quarter](https://www.defiance-industries-wargaming.com/listing/4324190923/atlas-pmw-sculpt-multiple-variants) | Larger cranium, pronounced cheek/jaw taper, broad brow, sculpted dome/shoulder shells. Size relative to the 35t and 55t chassis. |
| Wolverine WVR-6R | [WVR-6R FSW technical artwork](https://www.sarna.net/wiki/File:Wolverine_WVR-6R_FSW.jpg) | [Multiple views of physical miniature](https://syzgames.com/products/wolverine-wvr-6r) | Front-leaning armored shoulder shields, an unmistakable pilot visor and slender antennas, chested armor plane replacing tube-like chest. |
| Jenner JR7-D | [Jenner technical drawing](https://mordel.net/tro.php?a=vtbm&id=188) | [Jenner three-quarter miniature](https://www.ebay.com/itm/205033594352) | Extended aircraft-like cab instead of central gun barrel, visibly raked canopy/front windshield, angular chin, horizontal fuselage, 35t scale. |

First review gate: head/cockpit, chest, left/right shoulder silhouettes and major negative space need to compare favorably to the above illustrations. Second gate: thigh/shin/hock/foot silhouettes and gaps, then a separate detail pass. Do not confuse the surface-only VxShapePreview with full game voxelized damage geometry: it does not render `erase` cuts.

After each actual in-engine render, log visible errors and resculpt the offending components before further refinement. **No increase to `subdivide` or target voxel counts before all three model shapes are approved.**

## Iteration and actual Godot review log

| Cycle | Visual finding from one in-engine gallery | Reference-driven change | Gate |
| --- | --- | --- | --- |
| 9 | Atlas head too small in the old baseline; Wolverine shoulders resembled hollow cannons; Jenner nose read as a turret | Enlarged Atlas skull, revised WVR shoulder and head, tapered Jenner cockpit, corrected 100t/55t/35t relative scale | Not approved |
| 10 | WVR large shoulder-front caps looked hollow; Jenner straight leg outlines hid reverse joints; Atlas missing signature apertures | Solid WVR arm shells and split chest shields; Jenner's knee and rear hock moved in actual cross-section profiles; separate five-opening Atlas launcher | Not approved |
| 11 | WVR armor caps remain too rounded; Jenner's bent legs lacked clear pivots and aircraft side windows; Atlas thighs looked generic | Hard-edged WVR pauldrons and long shin covers, Jenner side glass + hock/knee couplings, Atlas angular upper-thigh guards | Pending newest in-engine render |

Keep production gates unchanged: `subdivide: 1`, genuine per-chassis parts, **one** combined gallery image, no APK and no merge without instruction. Structural component contours must match both primary and secondary references and read correctly in isolation *before* fine details.

## Additional silhouette corrections

- **Pass 12 — armor plate directions:** WVR pauldron front caps changed to independent canted plates after fixing the preview's inward surface normals. Jenner's side-mounted paired laser nacelles use chamfered boxlike sections, not cylindrical pods. Atlas thigh guards are narrower and the upper-arm elbow linkage stays exposed.
- **Pass 13 — chassis proportions:** Atlas and Wolverine legs were elongated below the hip while the original individually sculpted upper assemblies were translated upward intact. This specifically targets the short-legged appearance in the prior Godot gallery; no global generic-mech mesh or fine-detail noise was introduced. Jenner's already-long digitigrade limbs were not stretched. Gallery labels are now derived from the models' actual heights.

The latest screen capture is a **single** gallery image; extra angle renders are not required for each ordinary iteration. Approval remains contingent on new visual inspection against the primary art—this is an active sculpting branch, **not** accepted final geometry.
