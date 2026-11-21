# Shape-first Marauder and Timber Wolf models

Status: **art prototypes, pending real Godot screenshots and multi-view visual approval**.

Two popular 75-ton 'Mechs have separate coarse and high-resolution files in Claude's
editable JSON/rig pipeline, without altering any battle rules or replacing the
other procedural lab's models.

| Design | Shape study | Detailed model | Official record |
| --- | --- | --- | --- |
| Marauder MAD-3R | `data/voxels/marauder_shape.json` | `data/voxels/marauder.json` | `marauder_mad3r` |
| Timber Wolf Prime | `data/voxels/timber_wolf_shape.json` | `data/voxels/timber_wolf.json` | `timber_wolf_prime` |

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

## Second modeling batch — Warhammer, Archer, Shadow Hawk (2026-11-21)

The next three classic chassis also have independent low and high recipes in
`data/voxels/`: `warhammer_shape.json` / `warhammer.json`,
`archer_shape.json` / `archer.json`, and
`shadow_hawk_shape.json` / `shadow_hawk.json`. Their linked official records
are `warhammer_whm6r`, `archer_arc2r`, and `shadow_hawk_shd2h`.

The low-detail polygons and the high-detail silhouettes are identical. The
high versions use 3× subdivision and an optional `hollow: 1` flag on each
loft: this retains **only its exposed original cells** before subdivision and
avoids adding solid, invisible interior mass. There are still darker
structure-role supports and ordinary armor/structure sections.

Static geometry checks (before Godot's fine bevel pass):

| 'Mech | Low shape voxels | Fine voxels | Colliding component cells |
| --- | ---: | ---: | ---: |
| Warhammer WHM-6R | 9,223 | 138,721 | 0 |
| Archer ARC-2R | 11,139 | 149,132 | 0 |
| Shadow Hawk SHD-2H | 6,845 | 119,513 | 0 |

These counts were generated by an offline rasterizer against the JSON shapes.
The render is an **offline voxel-geometry preview**, not a Godot screenshot.
Run Godot tests and capture front/side/top/three-quarter angles before visual
approval. In particular, the current sculptures remain at **initial art pass**;
the Archer's paired recessed 20-hole shoulder racks, the Warhammer's PPC
arm silhouettes, and the Shadow Hawk's asymmetrical weapons must be refined
against Catalyst miniatures before production.

The Claude Voxel Test showcases both LODs of all three; the new test file
`tests/unit/test_vx_three_chassis.gd` checks authoring-layer cell overlap,
record-sheet IDs, LRM tube openings, preserved hull contours and 3× voxel
budgets. No APK was produced and game-rule state remains independent.

## Five-pass proportionality and connectivity sweep (2026-11-21)

All five new 'Mechs received **five coordinated shape-first passes** on both the
`_shape.json` silhouettes and the high-detail JSON: proportion study, major
silhouette changes, joint and contact geometry, unique armaments, and structural
validation. References weighted the current Catalyst miniatures alongside other
angles, not generic humanoid templates.

| Design | New emphasis | Mechanical and signature features |
| --- | --- | --- |
| Marauder MAD-3R | Longer beaked cockpit, broad flat wing-like shoulders | Dorsal AC/5 cradle separated from the CT; PPC cheek/arm mounts; digitigrade knees and tarsi |
| Timber Wolf Prime | More forward oval nose; visually separate elevated twin missile towers | Shoulder-rack supports and twin arm laser housings; 20 physical ports per rack retained; digitigrade ankles |
| Warhammer WHM-6R | Lower cockpit between distinctive shoulder modules; shorter paired arm PPC housings | PPC barrels attached to forearms; SRM-6 pod, ankle plates and contact joints |
| Archer ARC-2R | Lower cockpit and shallower, narrower, paired vertical missile banks | Both LRM-20 banks retain their own 4×5 bore pattern; arm fists and rack/body contact |
| Shadow Hawk SHD-2H | Lower head and strong shoulder asymmetry | Slender left AC/5 mount, **five** right LRM-5 apertures (not six), visible fist housings and bridge mounts |

**Verification:** A separate offline authoring-grid raster confirmed **zero
overlaps between different articulated parts** in the edited models. Additional
connectors were inserted where contact was missing, and a fine-grid connected
component scan of the locally refined Warhammer, Archer and Shadow Hawk shows
no detached voxel islands. Offline high-detail geometry previews of the latter
three were generated; these are **not Godot screenshots** and their
finishing/edge treatment is not the engine's final output. The draft PR should
still be visually reviewed in Godot using front, side, rear and overhead views.

Approximate low-to-fine counts for the offline iteration (before Godot bevels):

| Design | Coarse silhouette | Fine geometry |
| --- | ---: | ---: |
| Marauder | ~7,865 | ~147,500 projected |
| Timber Wolf | ~9,045 | ~148,500 projected |
| Warhammer | ~9,100 | ~139,200 |
| Archer | ~10,500 | ~146,800 |
| Shadow Hawk | ~6,430 | ~112,500 |

Counts from the local raster and mathematical subdivision are useful budget
estimates but not official Godot runtime readings. Combat unit rules and stats
were not changed, no Android build was made, and the PR remains unmerged.
