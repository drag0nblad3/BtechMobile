# Shape-first voxel modeling: eight-chassis batch

Status: **experimental art, not yet approved for production**. November 21, 2026.
Continuation of the new-chassis pipeline in draft PR #164.

## Scopes and references

Eight individually contoured chassis, each with a `<chassis>_shape.json` lightweight
silhouette sculpt (`subdivide: 1`) and matching `<chassis>.json` high-resolution
model (`subdivide: 3`). The source polygons, part pivots, parent hierarchy,
and locations remain aligned across each pair.

Prioritize the Catalyst Game Labs modern plastics and official record-sheet
weapon locations, using these supplemental visual reference pages:
- King Crab: https://www.sarna.net/wiki/King_Crab (broad domed armored carapace, concealed beak cockpit, two huge AC/20 arm claws)
- Stalker: https://www.sarna.net/wiki/Stalker (forward egg-like fuselage; left/right LRM-10 and laser arms)
- Rifleman: https://store.catalystgamelabs.com/products/battletech-rifleman-premium-miniature (paired long AC/5 and lasers on two arms; small pilot canopy and antenna)
- Phoenix Hawk: https://store.catalystgamelabs.com/products/battletech-phoenix-hawk-premium-miniature (winged jump-jet fins; extended right blaster; long slender legs)
- UrbanMech: https://www.sarna.net/wiki/UrbanMech (short rounded dustbin turret, right-side AC/10, tiny left gun and feet)
- Firestarter: https://www.sarna.net/wiki/Firestarter (dual-flamer nozzles and shoulder thruster packs)
- Black Knight: https://www.sarna.net/wiki/Black_Knight (helmet-and-breastplate center; PPC right gauntlet; tall humanlike stance)
- Vindicator: https://www.sarna.net/wiki/Vindicator (right PPC, five LRM-5 launcher apertures at left shoulder, long legs)

## Authoring and refinement

1. Draw unique large hull and head loft sections from multiple reference angles.
2. Position shoulders, gun housings, thighs, knee joints and feet with real
   adjacency; mirror only intentionally paired anatomy.
3. Check front/three-quarter silhouettes against the miniatures and make large
   corrections rather than burying bad proportions under more voxels.
4. Resolve all coarse-grid part overlaps and disconnected pieces by trimming
   conflicting authoring cells and connecting floating panels with internal
   **structure-role** braces.
5. Keep the same major contours in fine-detail models, replace invisible
   interior mass with thin hull surfaces, and use a threefold grid subdivision.
6. Cut actual empty fine-grid muzzle bores and align firing coordinates to them.
   King Crab has fifteen separate left torso LRM-15 ports; Stalker ten ports
   per LRM arm and six SRM ports per torso; Vindicator five LRM tubes.

## Static geometry audit

These measurements are from the independent authoring-grid voxel rasterizer;
high estimates are coarse occupied cells multiplied by 27, **before**
Godot's bevels and final fine-grid detail application. Do not present these
as Godot runtime measurements.

| Chassis | Official unit ID | Low coarse voxels | High pre-bevel projected |
|---|---|---:|---:|
| King Crab KGC-000 | `king_crab_kgc000` | 8,941 | 152,550 |
| Stalker STK-3F | `stalker_stk3f` | 10,151 | 156,735 |
| Rifleman RFL-3N | `rifleman_rfl3n` | 6,670 | 130,221 |
| Phoenix Hawk PXH-1 | `phoenix_hawk_pxh1` | 5,734 | 116,397 |
| UrbanMech UM-R60 | `urbanmech_umr60` | 8,135 | 125,064 |
| Firestarter FS9-H | `firestarter_fs9h` | 6,095 | 121,041 |
| Black Knight BL-7-KNT | `black_knight_bl7knt` | 7,790 | 148,527 |
| Vindicator VND-1R | `vindicator_vnd1r` | 7,064 | 131,625 |

For each pair the local audit reported **zero coarse-grid overlaps**, **no
disconnected part islands**, and **no parent-to-child contact gaps**.
Physical fine-grid launcher/gun bores were checked to be empty at the aligned
muzzle positions. Additional thin panel/seam treatment occurs at runtime in
`VxRefine`, which can change final voxel counts.

## How to review

Open `scenes/vx_showcase.tscn` (Claude Voxel Test), use **NEXT MECH**
to cycle each shape and high-detail version. Compare front, left/right,
rear, top, and three-quarter views with the miniatures. This batch includes
offline VTK renders from the actual generated geometry, **not** Godot
screenshots. Production visual approval, CI, and phone performance remain
pending, especially for wide shells and the high-density Stalker.

The official `data/units/` records and all `src/core/` combat logic remain
unchanged. No APK build is part of this work, and the branch remains unmerged.
