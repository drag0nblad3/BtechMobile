# Shape-first Marauder and Timber Wolf models

Status: **art prototypes, pending real Godot screenshots and multi-view visual approval**.

Two popular 75-ton 'Mechs have separate coarse and high-resolution files in Claude's
editable JSON/rig pipeline, without altering any battle rules or replacing the
other procedural lab's models.

| Design | Shape study | Detailed model | Official record |
| --- | --- | --- | --- |
| Marauder MAD-3R | `data/voxels/marauder_shape.json` | `data/voxels/marauder.json` | `marauder_mad3r` |
| Timber Wolf Prime | `data/voxels/timber_wolf_shape.json` | `data/voxels/timber_wolf.json` | `timber_wolf` |

## Method

1. **Silhouette sculpt first.** Each low-resolution JSON is authored in a shared
   grid, with independently defined loft sections for its cockpit, torso,
   shoulder or arm guard, and key leg surfaces; no global scaled humanoid
   template. The joint chain is authored separately and mirrored deliberately.
2. **Preserve major contours.** The detailed files retain those identical loft
   polygons and the same pivots but use `subdivide: 3` with new armor/structure
   details, fine-grid etching, recesses and physical weapon mouths.
3. **Put voxels on visible detail.** Hollow selected wholly internal regions and
   reintroduce sparse structure-role supports, rather than filling the entire
   hull at 27x the original volume.
4. **Verify assembly.** A recipe-level voxel raster audit found zero cells
   shared between different articulated parts. Unit tests enforce that invariant
   and that the 20 ports in each Timber Wolf launcher stay open.
5. **Only then inspect a real render.** Run the Claude Voxel Test from the
   launcher, cycle through the shape and detail versions, and inspect front,
   side, back, overhead and three-quarter views. These visual gates have **not**
   been performed in this change: do not treat the silhouettes as approved.

## Silhouette targets

**Marauder:** Low forward beak/canopy; stretched low carapace; distinctive
twin horizontal PPC forearms and their narrow shoulders; high dorsal AC/5
housing with an actual bore; thin waist above reverse-jointed lower legs.
It is deliberately not a humanoid in broad torso armor.

**Timber Wolf:** Small, sharply forward cockpit pod; compact central fuselage;
paired boxy shoulder LRM-20 housings above slim arm-mounted laser cannon;
narrow midsection; reverse-jointed legs with a distinct tarsus and splayed feet.
The high-resolution model cuts a 4-column by 5-row array of genuine launcher
channels into **each** rack, with twenty aligned muzzle coordinates per side.

## Budgets and workflow

A coarse-grid static raster check (before subdivision and beveling) reported:

| Model | Coarse occupied cells | Subdivision | Pre-bevel projected cells |
| --- | ---: | ---: | ---: |
| Marauder shape | ~7,760 | 1 | ~7,760 |
| Marauder detailed | ~5,350, with internal voids | 3 | ~144,450 |
| Timber Wolf shape | ~8,890 | 1 | ~8,890 |
| Timber Wolf detailed | ~5,340, with internal voids | 3 | ~144,180 |

**These are estimates, not Godot-measured final voxel counts.** The loader
also bevels exposed edges and draws seams. The new tests check a broad
100,000–160,000 range for the real loaded detailed models. Avoid making
performance claims until the Godot showcase has been profiled on a phone.

To compare both levels of detail, start `scenes/vx_showcase.tscn` and use
**NEXT MECH**. The four added entries follow Catapult and Hunchback:
Marauder shape → Marauder detailed → Timber Wolf shape → Timber Wolf detailed.
The 20-port salvo uses the launcher-count-aware `VxVolley.salvo_count`;
the Catapult still fires 15 missiles per launcher.

Run `godot --headless -s tests/run_tests.gd -- vx_new_chassis` and the
showcase smoke test; then take orthographic and three-quarter captures,
compare with Catalyst's current plastic miniatures, refine wrong primary
proportions, and only then approve for production.

References for shape comparison:
- [Marauder overview and miniature variations](https://www.sarna.net/wiki/Marauder)
- [Timber Wolf overview and miniature variations](https://www.sarna.net/wiki/Timber_Wolf)

## Constraints

The models use **only** `data/voxels/` and `src/view/vox/`. Neither the
core unit statistics nor the procedural lab and existing chassis were changed.
Voxel damage remains cosmetic and record-sheet driven. No Android build
is part of this work.
