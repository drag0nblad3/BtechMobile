| Catapult CPLT-C1 | 107,746 | Narrow beaked fuselage, widely spaced paired 15-tube LRM pods, birdlike hocks and widened toes |

This prototype is a rendering experiment, not a change to Total Warfare damage rules.
It lives under `src/view/units/` and `scenes/` and does not modify the
`src/core/` simulation, game-state mutation, force-builder or battle scene.

## Launch in the full BtechMobile project

Open `project.godot` and press Play; choose **Voxel Mech Lab** instead of
**Play Battle Game** on the launch screen. Use **Main Menu** in the lab to
return to the mode selector. The battle game remains available.

Direct scene launch is also available:

```bash
godot --path . --editor # open scenes/voxel_mech_lab.tscn, F6
# or directly run the scene:
godot --path . --scene res://scenes/voxel_mech_lab.tscn
```

Godot 4.5+ standard build. Tap or left-click the mech to shoot the actual
occupied voxel closest to the camera ray. Use the on-screen hit buttons to
inspect damage to named components, SEVER RIGHT to test falling physics, WALK
TEST to repeat alternating steps, and RESET to restore armor. Right-drag or
swipe to orbit; mouse wheel to zoom.

## Chassis refinement pass (02)

The lab now includes a **chassis selector** and an **Upper stability** slider.
It loads six profiles from `data/graphics/voxel_chassis.json`: the original
reference mech plus Atlas AS7-D, Hunchback HBK-4G, Wolverine WVR-6R,
Jenner JR7-D, and Catapult CPLT-C1. These are initial **procedural blockout
silhouettes**, not yet exact miniature/technical-readout representations.

- Humanoid mechs retain the original two-link walk.
- Digitigrade mechs (Jenner and Catapult) have **three distinct links**: thigh,
  rearward shin, and sloping metatarsal/hock-to-toe link. Analytic IK positions
  the toe on the ground through stance and raises it during swing.
- Both leg styles are phase-opposed; the mech's upper chassis and weapons are
  stabilized independently of leg poses. Default stability is 90% (slight
  residual sway); set the slider to 100% for a locked torso.
- Each shape uses different torso/arm voxel layouts: Atlas broad heavy armor,
  Hunchback asymmetric right shoulder cannon, Wolverine medium body,
  Jenner compact head and laser mounts, Catapult oversized side missile pods.
- All parts remain voxel-damageable. The lab is still independent of combat
  rule events and battlefield UnitView models.

Profile IDs match `data/units/*.json`; as new chassis art is refined, add
geometry profiles without changing the core rules. CI also captures
`digitigrade_a.png` and `digitigrade_b.png` at opposite walk phases.

## High-fidelity voxel pass (03)

- **Jenner JR7-D:** now mixes genuine **25 mm** cockpit and laser-pod cells
  with 37.5 mm digitigrade leg geometry. Its forward canopy, four SRM ports,
  separate twin laser emitters per side, engine grilles and piston channels
  all have true microgeometry and damageable cells, not texture-only accents.
- **Atlas AS7-D** now has **119,114 real voxels**, including a 25 mm torso
  with dark inset visor, layered cheek armor and rear cooling recesses.
  **Catapult CPLT-C1** has **108,080 real voxels**, including 25 mm LRM pods
  with fifteen truly recessed missile tubes per side, and a 37.5 mm hull.
  The other chassis are also individually sculpted at 25/37.5 mm; see below.
  The `voxel_part_detail` setting can override the chassis's `voxel_detail`
  for especially detailed parts; the rest of the chassis keeps its planned
  physical proportions. The above counts are from a headless Godot run.
- **All chassis voxel counts** appear in the lab catalog. The selected model
  also reports original count, current count, number of removed voxels and
  current voxel pitch. Counts come directly from occupied cells (no estimates)
  and are measured one model per frame using mesh-free construction to avoid
  building six render meshes during startup.
- **Variable damage:** every tap or scripted shot uses seeded, asymmetric,
  jagged local erosion and smaller secondary chips. Scripted hits now ray-pick
  the **entire exposed surface** of the selected body part instead of a tiny
  region near its center. The crater radius scales with part size (0.25–0.49 m)
  for broader visible damage. Tests can pin the random seed to reproduce failures.
  Intact distant parts are never altered by a hit.
- **Fast ray picking:** a bounded voxel-grid traversal replaces an O(total
  voxels) scan for every shot. Erosion visits only a bounded neighborhood
  around the impact and rebuilds only the changed component once.
- Voxel erosion remains **view-only**; official armor and equipment damage
  continue to be determined by the rules simulation. High-detail geometry
  is an art prototype and still needs profiling on physical Android devices.

To avoid generating unsolicited previews, GitHub CI renders screenshots only
when started explicitly with **Actions → CI → Run workflow**. Normal push and
pull-request checks still run unit tests and headless scene smokes.

## Sculpted six-chassis roster (05)

A second **reference-guided silhouette pass** followed actual BattleTech
technical art, recorded in [the reference study](graphics/voxel-reference-study.md).
It avoids a universal rounded biped shape: the Atlas uses narrow shoulders-to-
hip armor and a distinct skull/cannon configuration; the Hunchback has a
dominant squared shoulder-mounted gun; the Wolverine has a tall cockpit and
raised SRM; the Jenner has a long aircraft nose; the Catapult has paired racks
and no humanoid weapon arms. The experimental prototype remains intentionally
asymmetric. Hip widths and weapon mounting points were revised per chassis.

The default visible models now use **boundary-only surface nets** instead of
square faces for every voxel. Mesh facets follow the actual sampled armor
volume with smoothed normals, while ray picking, voxel damage, the 20/60-mech
stress test and counted occupied microcells continue to use the same sparse
voxel dictionary. The original cube renderer remains available for isolated
unit tests. Each chassis receives a different neutral showroom armor finish;
the colors are purely visual, never tactical or faction rules. The new
geometry and surface-net regression tests also cover hollow openings and
damage counts. The high-resolution models are still experimental, and Android
GPU/RAM/thermals remain unverified.

The reference for this pass is Claude's Catapult: real, separately modeled
weapons, layered armor, actual negative-space ports and structural machinery.
All six procedural **Voxel Mech Lab** models now contain over 100,000 **actual
occupied voxel cells** and remain below 150,000. These are mesh-free Godot
geometry measurements after the material, bevel and cavity sculpting passes:

| Visual chassis | Occupied voxels | Recognizable 3D features |
| --- | ---: | --- |
| Original test mech | 122,909 | Swept paired sensor canopy, tapered instrumented chest, separate cooling nacelles, a bored test cannon and articulated gauntlets |
| Atlas AS7-D | 139,111 | *Rounded skull head with recessed glowing red eyes and jaw*, tapered pectoral plates, curved pauldrons, torso AC/20 and missile tubes; 25 mm gauntlets |
| Hunchback HBK-4G | 149,808 | Seriously asymmetric shoulder hump, recessed left cockpit, circular bored AC/20, offset arms, rounded armor and vented rear equipment |
| Wolverine WVR-6R | 140,707 | Wedge nose, distinct shoulder armor, six genuine SRM holes, a right-arm open cannon, left manipulator and tapering breastplates |
| Jenner JR7-D | 124,561 | Long wedge cockpit, large contoured rear engine fairings, four SRM ports, paired laser emitters and exposed three-link digitigrade mechanics |
| Catapult CPLT-C1 | 113,387 | Sloped bird-like beak and reactor, vented rear jets, twin 15-cell recessed LRM pods and rounded reverse-jointed leg armor |

These counts are not display multipliers or extra damage pixels.
`VoxelAnatomyV2` now **replaces the old rectilinear skeleton** with
superelliptic tapered torso lofts, curved volumetric shoulders and forearms,
physically sculpted skull/visor shapes, three-dimensional weapon bores,
separate armor plates and piston/knuckle joints. `VoxelRosterSculpt` and
`VoxelFineDetail` still provide surface recesses and detail. The new
smoothing removes only nonessential outer corners; it does **not** eat thin
missile rims or isolated test voxels. All voxels remain destructible and
carry the same `armor`/`structure` visual roles as Claude's JSON models.

Each chassis has its own anatomical blockout, instead of sharing one silhouette
and merely varying voxel pitch. High-value subassemblies get 25 mm cells
(especially the Atlas's weapon arms, Jenner's laser nacelles, Catapult
launchers, and smaller cockpits). The Atlas's larger sculpted torso uses
37.5 mm cells to stay within a **150k real-voxel** budget without sacrificing
its heavy proportions. Humanoid neutral poses are straighter, exposing more
leg armor; walking gait IK and combat rules are unchanged.

Actual Godot mesh renders (not concept art) have been used for QA on all
six models. These are **still prototype art**, not final shipping assets:
mobile performance, target-device memory/heat and close-up visual acceptance
must still be checked. **No APK export was run.**

For actual geometry rather than estimated budgets, run
`godot --headless -s tools/voxel_count_report.gd`. This reports each model
and all individual part totals, with no rendering or APK export. The roster
regression tests require **100,001–150,000 real occupied cells per model** and
check visible features such as carved weapon bores, SRM ports and vents.

## Selectable 20/60-mech performance stress test (04)

The **Voxel Mech Lab** has a touch-sized **COUNT: 20** button. Tap it to toggle
between **COUNT: 20** and **COUNT: 60** before starting, then press **STRESS TEST**.
The count selector locks during the run; **STOP / CLEAR** cancels even while the
models are still spawning, releases the loaded models, and unlocks selection.

The test computes real voxel counts and always selects the highest-detail
available chassis (currently **Hunchback HBK-4G, 147,398 occupied voxels**).
It creates actual destructible meshes **one per frame** to spread loading cost:

- **20:** centered 5×4 formation, 3.65 m spacing, 31.5 m camera fit and
  **2,947,960 initial occupied voxels** with the current Hunchback.
- **60:** centered 8-column formation spanning eight rows (four mechs centered
  in the final row), same 3.65 m spacing, 52 m camera fit and
  **8,843,880 initial occupied voxels** with the current Hunchback.

The arena has a **36×36 m** ground plane and grid, with room for either
formation and its outermost mech armor. All models stand still to isolate
geometry and repeated damage-mesh rebuild cost from gait CPU load. Once the
selected population is fully spawned, a random mech and a ray-picked position
on the full exposed surface of a random surviving body part are damaged about
every 0.3 seconds. Each broad irregular crater remains confined to the
selected part.

The on-screen readout shows loading progress **N / 20** or **N / 60**, current
FPS, average and minimum sampled FPS, frame time, hit counts, destroyed and
remaining voxels. Average/minimum sampling begins only after loading finishes.

**ZOOM +**, **ZOOM −**, and **FIT VIEW** work with both populations, along
with mouse wheel and touch pinch. Stress camera zoom ranges from 7–58 m for
20 models and 7–90 m for 60. Single-finger orbit still works.

**60 full-detail Hunchbacks may overwhelm mobile RAM, GPU resources, or CPU**,
particularly on older phones. This is deliberate device stress testing—not
a performance promise. You can stop partway through loading. The CI smoke
checks a **partial 60-mech load and cancellation**, then a **full 20-mech
test with rendered meshes**, random damage, FPS UI and cleanup. It does
not try to instantiate all sixty high-resolution models in CI.

## Mechanics demonstrated

- Two 0.70m bone segments per leg, knee/ankle pivots and analytic IK.
- Left and right feet 180 degrees out of phase: each becomes forward and rear.
- Flat, contact-height stance (60% cycle), raised swing (40%).
- Local visible voxel removal. Render meshes omit internal faces and rebuild
  only the changed component. Armor shells have darker internal voxels.
- Joint-region damage can sever shoulders, hips and knees. Detached hierarchies
  fall as rigid bodies with approximate box collision proxies.
- CPU side accurate ray–occupied-cube picking; no physics collider per voxel.
- Deterministic scripted weapon bursts for visual inspection.

## Boundaries and next steps

- `VoxelMechLab` is an isolated art/prototype scene; `UnitView` still uses its
  current sprite/placeholder path. Integrate once animation and mobile profiling
  are accepted, rather than replacing all units at once.
- Voxel loss is visual-only: **do not** use voxel counts to mutate `Unit` or
  `GameState`. Future combat events should map the rules engine's hit location,
  armor and crit result to an appropriate visual impact on this view.
- Detached fragments use simple collision shapes, not exact voxel collisions.
- Current mesher culls hidden faces but does not greedily merge coplanar faces.
  Constrain mesh rebuilds and debris count on Android. Profile before scaling
  to battle maps and multiple units.
- This lab is intended for desktop and Android, but still requires an actual
  Godot runtime and hardware validation; these files alone cannot prove fps.

## Test

```bash
godot --headless --import
godot --headless -s tests/run_tests.gd -- voxel_gait
godot --headless --quit-after 45 --scene res://scenes/voxel_mech_lab.tscn
```

CI captures `gait_a.png`, `gait_b.png`, `armor_before.png` and `armor_after.png` from Godot via `tools/capture_voxel_lab.gd` for visual review.
