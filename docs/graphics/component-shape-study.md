# Component silhouette studies — reference lock

**Status: shape-only prototypes.** These are NEW low-resolution manual cross-section sculptures; no data or geometry from the abandoned PR #80 is used. No 100–150k target, procedural body generators, subdivision, armor panel seams, or cosmetic damage work is permitted until individual component shapes and the assembled silhouettes are approved.

Each `loft` is a polygon profile drawn explicitly for its chassis and component. The geometry loader merely rasterizes the individual outlined sections into the existing `VxModel` grid.

## Atlas AS7-D
1. [Classic AS7-D model, front-three-quarter](https://www.laserforgeminiatures.com/products/atlas-as7-d-mech) — rounded skull head under broad rising shoulder hoods; heavy arms end in fists; upper body tapers toward waist.
2. [Atlas alternate detailed sculpture](https://www.defiance-industries-wargaming.com/listing/4324190923/atlas-pmw-sculpt-multiple-variants) — torso-shrouded gun, exposed knee joints, broadened feet.
3. [BattleTechWiki Atlas](https://www.sarna.net/wiki/Atlas) — variant distinction. Target stock AS7-D, not Atlas II or a kitbash.

Shapes to approve independently: skull/cranium, jaw and ocular openings; tapered chest and narrow abdominal linkage; independent left/right torso hoods; upper arms/elbows/forearms/fists; hip, long tapered thigh, jointed knee, slender calf, split toe boots. Five visible LRM launch apertures, not twenty duplicate holes.

## Wolverine WVR-6R
1. [WVR-6R FSW illustration](https://www.sarna.net/wiki/File:Wolverine_WVR-6R_FSW.jpg) — reference silhouette. Tall narrow visor head; dorsal 2x3 missile rack beside head; asymmetric forearm gun and fist; knees/knee shields.
2. [WVR-6R multiple-angle miniature](https://syzgames.com/products/wolverine-wvr-6r) — side silhouette, arm and leg depth, broad but not boxlike shoulders.

Shapes to approve independently: chest taper, helmet, offset missile tower, AC/5 arm shroud and bore, other arm hand, angular thighs and narrow knee-to-ankle segments.

## Jenner JR7-D
1. [Jenner official TRO line art](https://mordel.net/tro.php?a=vtbm&id=188) — wide horizontal back/engine block; enormously protruding cockpit; short separate paired laser nacelles and top-mounted SRM cluster.
2. [Jenner miniature front/side angles](https://syzgames.com/products/copy-of-kintaro-kto-19) — mechanical profile, split feet, narrow joint shafts.

Shapes to approve independently: forward prow and sloped canopy, wide level engine fuselage, compact side pods, narrow reverse-knee femur and shin, hock link, splayed toes.

## Required visual gate
Render front, left/right profile, rear, and three-quarter views. Confirm the outline of **each disconnected component** and all negative spaces against source images. If any component silhouette is wrong, resculpt that component *before* adding any voxels for bevels/details. Whole-chassis voxel count at this point is intentionally small.

## First visual evaluation (Godot front/three-quarter/side/rear)

**Gate result: NOT APPROVED.** The test architecture and capture pipeline work, but correct body-part silhouettes are not established. Do not subdivide, add surface detailing or integrate into the main game.

- **Atlas:** Skull face is more identifiable after the second shape pass, but shoulder hoods, arm gauntlets and thigh armor still read as generalized bulbous forms rather than the stock AS7-D's independently shaped components. Chest weapon housings need tighter reference placement and scale.
- **Wolverine:** Offset shoulder missile tower and forearm gun are located, but torso, upper-arm guards, chest depth and limb armor are still insufficiently reference-specific.
- **Jenner:** Broad horizontal body and projecting prow are present, but nose glazing, flank nacelle integration, hock linkage and toe shapes still differ from the technical readout and miniature.

**Next required work:** For each part, replace coarse symmetric cross-sections with explicit reference-traced front/side/plan polygons; verify those polygons isolated and assembled; repeat the four orthographic-perspective capture angles. The shared octagonal profile helper is a drafting shortcut, not acceptable as a final component shape. Keep this draft PR unmerged.

## Reference-driven iteration log (current branch)

**Fixed primary image per chassis (secondary images check volume, not a change of design language):**
- **Atlas AS7-D:** [Untextured three-quarter AS7-D sculpture](https://www.deviantart.com/lizzygibbs3d/art/FAN-ART-BattleTech-MechWarrior-AS-7-D-Atlas-551614099), plus [front, side and rear concept projections](https://ca.pinterest.com/pin/19844054593742889/).
- **Wolverine WVR-6R:** [WVR-6R FSW ink illustration](https://www.sarna.net/wiki/File:Wolverine_WVR-6R_FSW.jpg), plus [WVR-6R miniature front/side angles](https://syzgames.com/products/wolverine-wvr-6r).
- **Jenner JR7-D:** [JR7-D technical-readout illustration](https://mordel.net/tro.php?a=vtbm&id=188), plus [JR7-D multi-angle miniature](https://syzgames.com/products/copy-of-kintaro-kto-19).

The four-axis front/three-quarter/side/rear test remains compulsory for *each* change to a silhouette.

| Round | Changed geometry | Review finding |
| --- | --- | --- |
| Original | Shared octagonal body/limb sections | Rejected: too smooth/generic |
| 3 | Distinct hand-traced ten-point head, chest, and shoulder sections | Better articulation of frontal planes; silhouettes still insufficiently distinct |
| 4 | Separately profiled pauldrons, forearms, knuckles, thighs, knees, greaves and feet | Visible improvement to long-leg proportions; still some rounded armor masses |
| 5 | Distinct Atlas/Wolverine pelvis/codpiece, Jenner undercarriage and lower SRM housing | Removed pointed chest-to-thigh gap; reduced misleading vertical launcher |
| 6 | Hollow Atlas right-torso AC/20 frame, 2×3 open Wolverine missile rack, four separate Jenner laser barrels and projecting windshield | New weapon silhouettes are physically authored; inspect isolated parts and refine anything that remains off reference |

**Acceptance status remains FAILED/PENDING**, not "done": the skull face, upper-leg armor, shoulder blocks, torso side profiles, and Jenner hull-to-hip connections still need further reference comparison. Source files continue to use `subdivide: 1`. No high-resolution/detail pass is permitted.

**Important renderer distinction:** `VxShapePreview` is a faceted surface proxy for shape approval. It does not perform Boolean cuts for `erase` operations, although the updated weapon apertures are built as open bar assemblies where possible. Actual cutouts must also be verified by the coarse `VxModel` loader and its tests. Its digitigrade review pose uses real authored pivots and does **not** change the game's gait solver.
