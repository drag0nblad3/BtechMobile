# Shape-first third batch: six classic chassis (2026-11-21)

**Status:** Draft voxel art; low/high geometry authored and independently rendered.
Not a production sign-off: Godot rendering on device, rotating multi-angle silhouette
comparison and animation stress testing are still required. No APK was built.

All models follow the manually authored cross-sectional loft + articulated part
hierarchy in `data/voxels/`; the game combat unit data are unchanged. The
primary low-LOD loft contours are **exactly retained** in their high-LOD partners.
`subdivide: 3` provides fine damageable voxels, while selective hollow lofts,
interior cutouts and narrow structure-role supports conserve fine-grid density.

| Chassis | Official unit ID | Low-res file | High-detail file | Coarse silhouette voxels | Pre-bevel fine voxels |
| --- | --- | --- | --- | ---: | ---: |
| Awesome AWS-8Q | `awesome_aws8q` | `awesome_shape.json` | `awesome.json` | 13,297 | 173,340 |
| Griffin GRF-1N | `griffin_grf1n` | `griffin_shape.json` | `griffin.json` | 9,871 | 146,340 |
| Thunderbolt TDR-5S | `thunderbolt_tdr5s` | `thunderbolt_shape.json` | `thunderbolt.json` | 14,985 | 185,085 |
| Locust LCT-1V | `locust_lct1v` | `locust_shape.json` | `locust.json` | 7,012 | 105,354 |
| Centurion CN9-A | `centurion_cn9a` | `centurion_shape.json` | `centurion.json` | 12,490 | 175,473 |
| BattleMaster BLR-1G | `battlemaster_blr1g` | `battlemaster_shape.json` | `battlemaster.json` | 16,771 | 198,396 |

Counts above are offline raster estimates (occupied authored grid times 27 for
high LOD), **not** engine counts after beveling or per-device performance.
Heavy assault silhouettes exceed the 100–150k guideline in this first detailed
pass and should be optimized in later passes without changing the primary shape.

## Reference-specific shape priorities

- **Awesome:** Lower recessed face between high shoulder guards, broad breastplate,
  *two torso PPC muzzles* and one massive right-arm PPC. Left forearm retains a fist.
- **Griffin:** Single elevated right-shoulder LRM-10 housing, asymmetric cannon arm,
  narrow peaked canopy, jump jets, agile 55t shoulders and hips.
- **Thunderbolt:** Upper-right 15-tube launcher, chunky but separated shoulder
  armor, two distinct arms and a central cockpit; correct laser/SRM locations.
- **Locust:** Short 20t insectoid forward fuselage with extended beak/cockpit,
  two small hull-mounted MG pods with *no fists*, reverse-jointed legs and thin feet.
- **Centurion:** Right-arm AC/10, deep left LRM-10 rack, raised crested head,
  pronounced left forearm shield and explicit separate weapon muzzle contacts.
- **BattleMaster:** Large armored upper torso with wide visor, right PPC cannon,
  paired left-hand machine guns and six-tube left SRM pod.

## Passes performed

1. Manually drawn per-part primary front/side cross-sections, instead of one
   recycled generic template. Distinctive leg and shoulder massing per chassis.
2. Proportionality: torso height, shoulder width, hip/ankle spacing, weapon
   centerline. Insectoid versus humanoid animation rigs were kept distinct.
3. Mechanical connectivity: parent-child pivots, joint clearance and braces.
4. Fine geometry: port openings (10/15/10/6 as applicable), weapon outlets,
   surface recesses and internal spar supports, preserving low-res loft profiles.
5. Material and geometry audits: collisions and disconnected component islands
   removed; zero cross-part overlaps and no parent gaps remain in offline raster.
6. Offline VTK mesh render, from the *actual authored voxel grids* (not generative
   image approximation). Geometry must still be reviewed in Godot multi-angle.

### Validation and caveats

- Run `godot --headless -s tests/run_tests.gd -- vx_six_chassis` and a normal
  Claude Voxel Test smoke pass (`scenes/vx_showcase.tscn`). The new tests parse
  both JSON LODs, enforce source contour consistency and exclusive cell ownership.
- Use **NEXT MECH** in the showcase to cycle all new shape/detail variants.
- Six meshes remain a **first shape study**; adjust from front, side, overhead
  and three-quarter orthographic captures before declaring art final.
- All weapon/armor gameplay authority remains in `src/core/`; no combat rule
  edits, Android build, or merge accompanied this batch.

Reference image priorities: Catalyst 2019 *A Game of Armored Combat* plastics and
Beginner Box Griffin, plus front/three-quarter modern sculpt views. Primary
reference index: <https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs>.
