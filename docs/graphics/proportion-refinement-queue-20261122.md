# BattleTech voxel proportions: queue, source geometry, and assessment
2026-11-22

## Why this pass was necessary

The initial 151-shape topology audit proved the parts were connected, but that
does not prove a source sculpt looks like a modern BattleTech miniature. The
seven-mech render revealed particularly serious **side slabs**, short-looking
legs, and overly massive shoulders on the Battleaxe, Sagittaire, and Firestarter.
Name-blind silhouette overlap cannot measure reference fidelity by itself.

This pass is the first **physical contour and stance correction**. Changes
reside in actual `data/voxels/*_shape.json` and matching gameplay-resolution
`data/voxels/*.json` recipes; they are not rendering transforms.

## First source-reference anchors

- Battleaxe: current plastic/photo showing compact shoulder caps, a single
  raised left launcher, clearly separate forearms, narrower side body:
  https://www.wargamesemporium.co.uk/products/battletech-battleaxe-single-mech
- Sagittaire: current Catalyst plastic in Eridani Light Horse Hunter Lance;
  distinctive central prow and side weapons, not a round torso shield:
  https://www.sarna.net/wiki/Eridani_Light_Horse_Hunter_Lance
- Firestarter: current plastic Inner Sphere Recon Lance / FS9-H. This is an
  agile 35-ton infantry-hunter, not a heavy block of armor:
  https://www.sarna.net/wiki/BattleTech:_Inner_Sphere_Recon_Lance
- The Phoenix Hawk's differentiated upright shoulder and jet silhouette is
  compared against the current Catalyst Premium Miniature:
  https://store.catalystgamelabs.com/products/battletech-phoenix-hawk-premium-miniature

These are **anchors** and do not establish independently verified optical
ground-truth measurements for every other chassis. Each other chassis remains
subject to further miniature reference review.

## 151-model triage system

`tools/voxel_multiangle_audit.gd` now exports:

- Whole-model occupied bounds, total height and actual torso-cell bounds
- Robust 5th-to-95th-percentile **torso Z-depth / whole height**
- Hip-pivot height fraction of whole height
- Torso side-view projected area and slab fill ratio
- A non-binding risk score for prioritizing manual reference comparisons
- Existing blind four-view similarity and strict connected-mass/joint faults

**Do not automatically score all models against the same body archetype.**
Correctly deep/protruding noses (Jenner, Locust, Raven), very large dedicated
weapon mounts (Hunchback IIC, Hollander, Pack Hunter), squatting designs
(UrbanMech, King Crab), and quadrupeds (Goliath, Scorpion, Tarantula,
Thunder Stallion) are exceptions to narrow-humanoid proportions.

## Completed first sculpt queue — 41 chassis

**P0 direct miniature-feedback cases:** Battleaxe, Sagittaire, Firestarter,
Phoenix Hawk.

**P1 common stocky/slab-sided forms:**

- Spartan; Crockett; Katana; Quickdraw; Cataphract; Grizzly; Akuma;
  Merlin; Excalibur
- Whitworth; Ymir; Albatross; Exterminator; Helios; Hatamoto-Chi; Cyclops
- Clint; Assassin; Kintaro; Starslayer; Hellspawn; Chimera; Firefly
- Firebee; Shockwave; Malice; Hermes II; Howler; Venom; Dragon
- Ostroc; Grasshopper; Black Knight; Shadow Hawk; Griffin; Javelin; Commando

Every entry has individually selected **front/rear reduction and stance
extension amounts**; the geometry pass adjusts named part contours, mesh
primitives, hip and articulation pivots, and weapon/jump attachment points.
Extreme forward weapon extensions are explicitly preserved rather than
clipped along with the torso. The game remains free to damage or detach each
articulated part.

### Before / after measurements on the 41 edited actual voxel models

| Statistic | Pre-edit | First post-edit audit |
|---|---:|---:|
| Mean torso robust Z-depth / total height | 0.5119 | 0.4035 |
| Mean hip-pivot height / total height | 0.4812 | 0.5187 |
| Battleaxe robust torso depth fraction | 0.419 | 0.319 |
| Sagittaire robust torso depth fraction | 0.523 | 0.417 |
| Firestarter robust torso depth fraction | 0.441 | 0.263 |
| Chassis with improved depth metric | — | 41 / 41 |
| Chassis with improved hip-height fraction | — | 41 / 41 |

These figures are dimensionless ratios of voxel occupancy and **are not
claims of accurate plastic-miniature likeness**. The comparison reflects an
intentional stance change: more visible leg length, narrower torso mass and
less rear-body slab. Some weapon-forward or body-sled designs must retain depth.

## Connectivity follow-up

The initial 41-chassis pass introduced three strict-topology regressions:
Albatross right-arm decorative attachment, one Malice torso voxel, and
Griffin's left shoulder contact patch. These were fixed at source with a
proper internal support socket / explicit stray-voxel cleanup, not hidden
from the audit. **The latest full 151-chassis 0/0 result must be confirmed
by the workflow before this round is accepted.**

The CI review now also renders all 41 edited chassis from **front and side**
(`tools/capture_proportion_review.gd`) in addition to the seven-chassis
three-view example and Atlas/Wolverine/Jenner four-angle sheet.

## Next manual-reference queue

- **P2 — deliberately atypical geometry, needs individual sculpt study:**
  Hunchback IIC, Pack Hunter, Hollander, Thunder Hawk, Caesar, Pillager,
  Axman, Legionnaire, Dire Wolf, Turkina, Mauler, Stalker, Kodiak, Mad Dog,
  King Crab, Raven, Locust, Jenner, Cicada, Piranha, Shadow Cat, Fire Moth,
  and UrbanMech.
- **P3 — remaining unreviewed lower-risk roster:** review side photos
  and 3/4 miniatures; a low risk score does not mean reference likeness.
  Do not automatically narrow MWO-style or older designs toward a single
  human-shaped template.

## No game build

This is an art/source-geometry QA round only. No APK was requested or built.
