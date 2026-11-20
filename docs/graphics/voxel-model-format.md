# Voxel model format (text, no editor needed)

Claude's voxel 'Mechs are plain JSON in `data/voxels/<id>.json`. They're written by
hand (by Claude, another AI, or a person) and built into meshes when the game loads. There
are no binary files and no outside editor: every change shows up as a readable diff.
Examples: `data/voxels/hunchback.json` (normal legs) and `data/voxels/catapult.json`
(reverse-jointed legs, missile racks, jump jets). Code: `src/view/vox/`. Test scene: launcher →
**Claude Voxel Test** (`scenes/vx_showcase.tscn`).

## Collaboration with the procedural Voxel Mech Lab

Both model systems belong to this repository; **any contributor or coding
agent may modify either**. This JSON format belongs to the standalone
**Claude Voxel Test** (`src/view/vox/`), while the higher-density procedural
lab uses `src/view/units/voxel_*.gd` and
`data/graphics/voxel_chassis.json`. The pipelines are deliberately separate
until the battle-unit integration is implemented.

Shared geometry conventions:
- Prefer **real 3D openings** over decorative dark squares. The Catapult's
  LRM-15 racks now have fifteen cutout tubes and fifteen aligned muzzle
  coordinates on **each** arm, brought over from the procedural lab's
  higher-detail Catapult. `VxVolley.MISSILES` is fifteen per rack.
- Mirror paired parts rather than copying two divergent versions. Confirm
  both arrays of muzzle positions match actual open cells, with clearance
  from adjacent torso sections.
- Use `armor` and `structure` material roles. The lab's
  `VoxelPart.MATERIAL_ROLES` and `role_counts()` follow the same vocabulary;
  neither system should make official game-rule decisions from those counts.
- **Do not copy raw cell positions** between the builds: Claude's files use
  a single global authoring grid with per-file voxel size; the lab authors
  local part grids and subdivides selected parts to 37.5 or 25 mm.

**Gameplay authority stays in `src/core/`.** In this format, `VxDamage`
renders the `Unit`'s armor and structure state; in the procedural lab,
`VoxelMech.hit_part` is a visual/stress-test interaction, not a replacement
for Total Warfare damage rolls. Shared visual conventions can be edited
without changing the rules engine. To change actual combat rules, add an
isolated `src/core` change with dedicated tests and a rules-coverage update.

Test both pipelines after cross-edits:
`godot --headless -s tests/run_tests.gd` and the respective lab/showcase
smoke tests. No APK build or screenshots unless specifically requested.

## The grid
- One shared grid for the whole 'Mech: **x right, y up, -z front**. A cell `[x, y, z]`
  fills the cube from `(x, y, z)` to `(x+1, y+1, z+1)`.
- `voxel_size` is world units per cell. 0.05 makes a 37-cell 'Mech about 1.85 units tall,
  just under one hex (2 units corner to corner).
- Every part is written in the same grid, so parts line up without any offsets.

## Top level
```json
{
  "id": "hunchback", "name": "Hunchback HBK-4G", "voxel_size": 0.05,
  "materials": [{"name": "armor", "color": "6b7a55", "role": "armor"}, ...],
  "parts": [...],
  "muzzles": {"RT": [7, 33, -14], "LA": [-13, 18, -9]}
}
```
- **subdivide**: fidelity multiplier (default 1). At 2, every authored cell becomes 2×2×2
  finer cells and `voxel_size` halves, so you keep writing at the coarse scale. The loader then
  rounds the outer edges of thick blocks (3+ authored cells) and draws faint panel seams on
  armor. A part's optional `detail` list holds shapes in the **fine** grid (rivets, vents,
  slits) painted after that.
- **unit**: the `data/units` id the test scene uses for its record sheet.
- **legs**: `plantigrade` (Hunchback) or `digitigrade` (reverse-jointed, Catapult). Draw
  digitigrade legs as straight vertical segments (thigh, shin, tarsus, foot) with `hip`,
  `knee`, `hock` and `ankle` joints; the leg solver bends the knee backward and keeps the
  tarsus upright, and the toes curl down mid-step.
- **punch**: `false` for designs without fists (the Catapult's arms are missile racks).
- **weapons**: buttons in the test scene, each `{"label", "locs", "kind"}`, where kind is
  `laser`, `cannon` or `missile`.
- **jets**: jump-jet nozzles by location; they flame during a jump.
- **materials**: name, hex color and role. `armor` voxels are the plating that hits
  chip away first. `structure` voxels are the frame you see once the armor is gone.
- **muzzles**: where shots leave from, by hit location (grid coordinates). Use one point
  or a list: a list fires from every point (two chin lasers), and missiles ripple out of the
  launch tubes in turn.

## Parts
```json
{"name": "la", "loc": "LA", "parent": "lt", "pivot": [-12, 28, 0], "joint": "shoulder", "shapes": [...]}
```
| Field | Meaning |
|---|---|
| `name` | Unique part name |
| `loc` | Hit location it belongs to: `HD CT LT RT LA RA LL RL`. Several parts may share one (thigh, shin and foot are all `LL`) |
| `parent` | Part it hangs from (it moves with it). Omit for parts on the body root, such as the hips |
| `pivot` | Joint point in grid coordinates; the part rotates around it |
| `joint` | `hip`, `knee`, `hock` (digitigrade only), `ankle` or `shoulder`, so the walk cycle and punches can find the limbs |
| `shapes` | Drawing steps, applied in order (later steps paint over earlier ones) |
| `mirror` | Copy another part flipped left↔right (`"mirror": "la"` makes the right arm); `loc` swaps automatically |
| `add` | Extra shapes painted after a mirror (the Hunchback's right torso is the left torso mirrored, plus the hunch) |

Every location needs at least one part, and a parent must be listed before its children.
The game logs warnings for anything wrong, and `tests/unit/test_vx_model.gd` checks the shipped models.

## Shapes
Corners are inclusive cell coordinates.

| Shape | Effect |
|---|---|
| `{"box": [[x1,y1,z1], [x2,y2,z2]], "mat": "plate"}` | Solid block |
| `{"shell": [lo, hi], "mat": "armor", "core": "frame"}` | Block with a one-cell outer layer in `mat` and the inside in `core`, so damage shows the frame beneath the armor |
| `{"erase": [lo, hi]}` | Carve cells out (gun bores, vents) |

## How damage shows
The rules engine stays the authority. `VxDamage` gives each location a fixed, seeded order
in which its voxels go, as a series of craters: front armor, rear armor (torsos, cells with
z > 0) and then structure. The share of armor and structure the record sheet has lost
decides how far along that order the location is. The same record sheet always gives the
same picture. Destroyed arms and legs drop off and stay on the ground, and a wreck turns dark.
Hits knock armor chips loose, and locations with damaged structure leak smoke; heavier
damage makes thicker smoke.

## Tips for drawing joints
Leave the cell row at each pivot empty in the parent, and fill it with a small `joint`
block in the child, centered on the pivot. That block stays covered when the joint bends,
so no gap opens up. Never let two parts fill the same cell: overlapping faces flicker.
