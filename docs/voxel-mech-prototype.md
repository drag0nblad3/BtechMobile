# Voxel mech prototype 01 — isolated art and destruction lab

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

The reference for this pass is Claude's Catapult: real, separately modeled
weapons, layered armor, actual negative-space ports and structural machinery.
All six procedural **Voxel Mech Lab** models now contain over 100,000 **actual
occupied voxel cells** and remain below 150,000. These are mesh-free Godot
geometry measurements after the material, bevel and cavity sculpting passes:

| Visual chassis | Occupied voxels | Recognizable 3D features |
| --- | ---: | --- |
| Original test mech | 132,577 | Split sensor canopy, twin raised engine banks, hollow test cannon, dorsal antenna, piston joints |
| Atlas AS7-D | 119,114 | 25 mm skull-like cockpit, layered cheek plates, inset eye glazing, shoulders, heat-exchanger recesses |
| Hunchback HBK-4G | 147,655 | Off-center canopy, massive **hollow** right-shoulder AC/20, recoil rails, separate manipulator, rear vents |
| Wolverine WVR-6R | 149,578 | Swept cockpit and shoulder cowlings, six genuinely recessed SRM tubes, **bored** right-arm autocannon, left hand |
| Jenner JR7-D | 122,212 | Fine wraparound windshield, four-port SRM, two independent laser muzzles per side, digitigrade piston channels |
| Catapult CPLT-C1 | 108,080 | Distinct cockpit and jet housings, two detailed 15-tube LRM racks with physical cavities, exposed hock linkages |

The counts are not display multipliers or more precise destruction pixels.
`VoxelRosterSculpt` authors distinct 3D hull/limb/weapon structures *before*
sealing each part, then adds 25/37.5 mm grooves, frames and exposed mechanisms
after voxel subdivision. Real gaps stay empty and are ray-pickable; hidden
interior voxels are still culled from the surface mesh. Existing armor versus
structure material roles agree with Claude's JSON modeling conventions.
Gait IK and all official game combat rules remain unchanged.

The 25 mm voxels are concentrated in high-value regions: most cockpit
hulls, the Jenner's laser muzzles and the Catapult's missile racks. Outer legs
and less detailed weapon surfaces usually retain 37.5 mm cells. This preserves
the recognizable silhouette and helps contain CPU/GPU rebuild cost. **The
geometry is still experimental**: no render previews were requested, and
mobile FPS, memory footprint and heat remain unmeasured.

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
available chassis (currently **Wolverine WVR-6R, 149,578 occupied voxels**).
It creates actual destructible meshes **one per frame** to spread loading cost:

- **20:** centered 5×4 formation, 3.65 m spacing, 31.5 m camera fit and
  **2,991,560 initial occupied voxels** with the current Wolverine.
- **60:** centered 8-column formation spanning eight rows (four mechs centered
  in the final row), same 3.65 m spacing, 52 m camera fit and
  **8,974,680 initial occupied voxels** with the current Wolverine.

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

**60 full-detail Wolverines may overwhelm mobile RAM, GPU resources, or CPU**,
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
