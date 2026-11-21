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

## Expanded reference set — revisions 14 and 15

These are additional views for **shape matching**, not material/texture guides. Do not mix in Atlas II, Wolverine 6D, Jenner F, or other chassis variants.

| Chassis | New secondary image/reference | What the shape must show |
| --- | --- | --- |
| **Atlas AS7-D** | [Official newer Atlas line art](https://www.sarna.net/wiki/Atlas) | Skull with visible lower jaw, recessed between high shoulder cowlings; chest-mounted AC/20, shoulder/torso LRM rack, elbow and knee breaks |
| | [Stock AS7-D resin sculpture, front and rear photographs](https://www.laserforgeminiatures.com/products/atlas-as7-d-mech) | Flat shoulder roofs and front chamfers; torso length, back shell, arm spacing and calf depth; do not copy minute panel seams |
| | [Modern Atlas CAD sculpture](https://www.deviantart.com/lizzygibbs3d/art/FAN-ART-BattleTech-MechWarrior-AS-7-D-Atlas-551614099) | Depth and scale of Death's Head skull vs shoulder armor, physical 3-D component overlaps |
| **Wolverine WVR-6R** | [WVR-6R FSW line art](https://www.sarna.net/wiki/File:Wolverine_WVR-6R_FSW.jpg) | Angled slab pauldrons, distinct breastplate halves, 2×3 launcher beside helmet, forearm cannon separate from armor |
| | [WVR-6R dual-pose resin sculpture](https://syzgames.com/products/wolverine-wvr-6r) | Shoulder cross-sections, knee-to-foot proportion and negative space, left/right asymmetry |
| | [Alternate WVR-6R sculpt, side and three-quarter](https://afterdarkprints.net/products/wvr-6r-wolverine-alternate-battletech-model-1) | Shoulder sweep from side, long arm weapon shroud and separate calf armor plates |
| **Jenner JR7-D** | [JR7-D technical readout linework](https://mordel.net/tro.php?a=vtbm&id=188) | Long cockpit prow with window faces, four-port dorsal SRM rack, two smaller stacked laser barrels per nacelle, reverse-knee articulation |
| | [Later Jenner line art](https://www.sarna.net/wiki/Jenner) | Cockpit and nose length from oblique side; forward knee vs rear hock; rear-facing drive deck |
| | [JR7-D 3-D side/front view miniature](https://www.ebay.com/itm/205033594352) | Narrow legs vs horizontal body, short rectangular side pods, angular foot contact |
| | [JR7-D two-angle model](https://syzgames.com/products/copy-of-kintaro-kto-19) | Overall front width and paired-laser offsets |

### Visual review 14–15

- **Pass 14** reshaped the root component volumes for all three chassis: flat Atlas shoulder cowlings/short upper-arm guards; sharper and smaller WVR shoulder/torso pieces; narrower Jenner laser nacelles and a projecting cockpit nose. Multiple directions per model, rather than one generic torso template.
- **Diagnostic correction** the Godot `SurfaceTool` preview was *averaging vertex normals*, making polygonal planes look like bulbs. Setting `set_smooth_group(-1)` before adding vertices gives properly flat-shaded faces (Godot 4.5 documented behavior). This does not alter game meshes, the source voxel grids, or the subdivision level.
- **Pass 15** revised the actual proportions after looking at the corrected rendering: Atlas AC-20 shoulder/upper-arm separation and skull brow/optics, Wolverine narrower arm shields and shallow chest plates, Jenner smaller separated laser barrels and reduced front canopy glazing.
- The preview uses subtle **component identity colors only in the diagnostic renderer**. Source materials and gameplay colors are unchanged. Do not confuse these colors with model-detail work.
- Re-evaluate the latest one-image Godot screenshot; silhouettes are still **not approved** for 100–150k voxel refinement.

