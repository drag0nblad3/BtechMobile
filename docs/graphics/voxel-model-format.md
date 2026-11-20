# Voxel model format (text, no editor needed)

Claude's voxel 'Mechs are plain JSON in `data/voxels/<id>.json`. They're written by
hand (by Claude, another AI, or a person) and built into meshes when the game loads. There
are no binary files and no outside editor: every change shows up as a readable diff.
Example: `data/voxels/hunchback.json`. Code: `src/view/vox/`. Test scene: launcher →
**Claude Voxel Test** (`scenes/vx_showcase.tscn`).

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
- **materials**: name, hex color and role. `armor` voxels are the plating that hits
  chip away first. `structure` voxels are the frame you see once the armor is gone.
- **muzzles**: where shots leave from, by hit location (grid coordinates).

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
| `joint` | `hip`, `knee`, `ankle` or `shoulder`, so the walk cycle and punches can find the limbs |
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
