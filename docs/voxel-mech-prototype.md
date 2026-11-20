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

- **Jenner JR7-D:** selectable chassis profile now uses a genuine **37.5 mm**
  voxel lattice, compared with the standard 75 mm cells. Resolution is 2× per
  dimension (up to roughly 8× the original occupied cell count), plus fine
  one-voxel canopy seams, micro-bevels, engine vents and piston color accents.
  Shape is unchanged at mech scale; tiny details are genuinely detachable
  cells, not texture-only decorations.
- The other five profiles retain their 75 mm grid until they receive model-
  specific detailed geometry and Android performance profiling. Each profile's
  `voxel_detail` field controls its build density (1 or 2).
- **All chassis voxel counts** appear in the lab catalog. The selected model
  also reports original count, current count, number of removed voxels and
  current voxel pitch. Counts come directly from occupied cells (no estimates)
  and are measured one model per frame using mesh-free construction to avoid
  building six render meshes during startup.
- **Variable damage:** every tap or scripted shot uses seeded, asymmetric,
  jagged local erosion and smaller secondary chips. Scripted blast locations
  also vary slightly. Tests can pin the random seed to reproduce failures.
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

## 20-mech GPU/damage stress test

Press **STRESS TEST x20** in Voxel Mech Lab. The lab chooses the profile
with the highest **actual intact voxel count** (currently Jenner JR7-D at
52,830 voxels), removes the solo mech, and progressively spawns **20** of that
profile's real rendered voxel rigs on a 4-column by 5-row grid. The first
loading stage shows **building N / 20**; it only starts firing after all 20
are present. The scene camera widens to show the group.

Once populated, the test randomly selects mechs and articulated parts and
fires five irregular crater hits per second against *actual exposed voxel
surfaces*. The live HUD shows:

- **FPS**, and the lowest observed FPS after the first second of active stress;
- loaded mech count and chassis name;
- attempts, successful damaging hits, total voxels removed and remaining;
- elapsed time.

The test exercises live mesh rebuilds and visible geometry destruction;
stopping it releases all 20 models and restores the normal single-mech lab.
Touch, orbit and zoom still work; unrelated single-mech controls are disabled
during stress. The button becomes **STOP STRESS TEST** to make cleanup easy.

This is intentionally demanding. Twenty detail-2 Jenners start with
approximately **1,056,600 occupied microvoxels**. Rendered face counts,
CPU rebuild spikes, GPU memory, battery impact and heat are not the same as
voxel counts; measure actual FPS on your target Android device. Spawning is
progressive so the initial allocation is spread across frames, not a
guarantee that all phones can sustain the load.

The headless test checks highest-count selection, a complete 20-mech
population, actual randomized voxel erosion, the live FPS status text and
stop cleanup without generating screenshots:

```bash
godot --headless -s tools/voxel_stress_smoke.gd
```

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
