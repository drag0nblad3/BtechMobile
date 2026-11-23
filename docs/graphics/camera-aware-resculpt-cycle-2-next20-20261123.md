# Camera- and stance-aware sculpt cycle 2 — 20 chassis, 23 November 2026

This twenty-chassis sculpt batch builds on the measured-yet-unverified reference
and camera work in [PR #268](https://github.com/drag0nblad3/BtechMobile/pull/268).
The linked catalog includes 158 modern Catalyst plastic miniature photographs;
these are **unverified candidate masks and fitted cameras**, not approved
orthographic front/side/quarter/top views. Before interpreting any numeric
fit, verify background/base segmentation, body pose, lens and source version.

## Geometry changes and regional rationale

The following **existing authored source cross sections** are modified in
both quality tiers. These are conservative regional changes, not global
scaling. Joint centers, pivots, art poses, exact muzzle positions, open bores,
head/cockpit, weapons and unique silhouettes are retained.

| Chassis | Prior provisional photo fit, 0–100 | Candidate yaw/pitch | Region observed in report | Resculpted source anatomy / protected elements | Source cross-section area reduction |
|---|---:|---|---|---|---|
| turkina | 37.0 | 15.0°, 12.0° | Model's hip/leg assembly appears 49% wider than photographed silhouette in matched viewport | Narrow the mid-thigh and rear hock shells; retain saucer torso, symmetric missile towers, and actual joint locations | ll 5.4%; shin 5.4% |
| crossbow | 38.2 | 0.0°, 12.0° | Model's hip/leg assembly appears 33% wider than photographed silhouette in matched viewport | Pull in the overwide thigh and shin silhouette; preserve paired missile rack apertures and digitigrade structure | ll 4.5%; shin 4.4% |
| hunchback iic | 39.1 | 0.0°, 0.0° | Model's upper frame and shoulder racks appears 41% wider than photographed silhouette in matched viewport | Reduce aft central shell and the outer shoulder transition; deliberately keep raised twin weapon housings full size | ct 3.6%; shoulder 2.3% |
| uziel | 40.3 | 15.0°, 0.0° | Model's torso and cannon arms appears 61% wider than photographed silhouette in matched viewport | Taper the rear high chest and outboard shells on both distinct shoulders; leave arm cannon mounts and cockpit untouched | ct 3.9%; shoulders 3.6% |
| cyclops | 42.7 | 0.0°, 12.0° | Model's upper frame and shoulder racks appears 37% wider than photographed silhouette in matched viewport | Shorten rear upper armor and the outer left shoulder edge; keep head/sensor and launcher shape | ct 3.8%; shoulder 4.0% |
| jagermech | 43.6 | 0.0°, 12.0° | Model's torso and cannon arms appears 74% wider than photographed silhouette in matched viewport | Trim aft torso and outer shoulder armor without narrowing the intentional widely spaced cannon barrels | ct 3.7%; shoulder 3.7% |
| dragon fire | 43.8 | -15.0°, 12.0° | Model's torso and cannon arms appears 37% wider than photographed silhouette in matched viewport | Taper broad aft shoulder transitions while keeping separately authored left/right arm weapons | ct 3.3%; shoulders 4.9% |
| nightstar | 43.9 | 0.0°, -12.0° | Model's hip/leg assembly appears 33% wider than photographed silhouette in matched viewport | Thin the flared thighs and hock armor; protect long AC and PPC arm profiles | ll 5.3%; shin 5.8% |
| charger | 44.6 | 15.0°, -12.0° | Model's hip/leg assembly appears 78% wider than photographed silhouette in matched viewport | Reduce tree-trunk thigh/calf outer volumes around fixed hip/knee sockets; keep full-size physical fists | ll 7.8%; shin 6.2% |
| highlander iic | 44.6 | -15.0°, -12.0° | Model's upper frame and shoulder racks appears 54% wider than photographed silhouette in matched viewport | Lower aft armored upper-body mass and tame upper shoulder overhang on both distinct side shells | ct 2.9%; shoulders 5.2% |
| banshee | 44.7 | 15.0°, -12.0° | Model's hip/leg assembly appears 94% wider than photographed silhouette in matched viewport | Retaper the over-broad thigh and lower calf armor while preserving brawler shoulder and hand scale | ll 6.2%; shin 5.8% |
| warhammer | 44.8 | -15.0°, 0.0° | Model's upper frame and shoulder racks appears 31% wider than photographed silhouette in matched viewport | Taper the PPC-arm outer armor around the unchanged shoulder pivot; restore full central chest backing after connectivity QA; independently mounted SRM rack and PPC bores intact | la 2.3% |
| ostsol | 46.4 | 15.0°, 12.0° | Model's upper frame and shoulder racks appears 40% wider than photographed silhouette in matched viewport | Flatten excess aft armor at the upper body and narrow outer shoulder shell without moving laser mounts | ct 4.4%; shoulder 3.0% |
| victor | 45.1 | -15.0°, 12.0° | Model's hip/leg assembly appears 75% wider than photographed silhouette in matched viewport | Narrow mid-leg armor while maintaining leg rig and distinct main cannon arm | ll 6.4%; shin 6.5% |
| devastator | 46.8 | 0.0°, -12.0° | Model's hip/leg assembly appears 64% wider than photographed silhouette in matched viewport | Taper over-bulky mid-leg armor; retain long barrel silhouette and shoulder support | ll 5.9%; shin 6.0% |
| pillager | 47.5 | 0.0°, -12.0° | Model's hip/leg assembly appears 79% wider than photographed silhouette in matched viewport | Reduce tree-trunk thigh and calf contour while keeping both Gauss barrels and hip centers | ll 7.0%; shin 6.0% |
| enforcer | 49.3 | -15.0°, 12.0° | Model's hip/leg assembly appears 63% wider than photographed silhouette in matched viewport | Narrow broad knee and calf armor, preserving asymmetric arm hardpoints | ll 6.0%; shin 6.6% |
| annihilator | 47.0 | 0.0°, 12.0° | Model's hip/leg assembly appears 32% wider than photographed silhouette in matched viewport | Thin legs under the heavy upper cannon frame; preserve its intentionally massive torso and four guns | ll 4.7%; shin 4.9% |
| argus | 45.0 | 0.0°, -12.0° | Model's torso and cannon arms appears 59% wider than photographed silhouette in matched viewport | Remove aft torso and outer shoulder slab excess without relocating weapon sockets | ct 3.6%; shoulder 2.8% |
| archer | 45.9 | 0.0°, 12.0° | Model's upper frame and shoulder racks appears 30% wider than photographed silhouette in matched viewport | Reduce rear central body volume without narrowing either full-size 20-tube missile assembly | ct 3.1% |

Area reductions refer only to the average **modified planar loft cross
sections**, not total part mass, emitted voxel count or a re-scored
photographic similarity. Large discrepancies in the photographic scorecard
also depend on camera pose, printed bases and background masking; the
mesh changes are not asserted to improve a verified likeness score.

## Connectivity regression resolution

The initial attempt to reduce Warhammer's chest rear contour weakened its
left torso / central torso backed 2×2 solid joint. The central torso loft
has been restored exactly to main, and the Warhammer correction moved to
the outer PPC-arm armor, preserving its shoulder-side interface and the
independent right torso SRM module. Rerun both quality-tier audits after
this correction before relying on the result.

## Rules and validation gates

- Edited source `data/voxels/*_shape.json` and detailed
  `data/voxels/*.json` together for twenty corresponding visual models.
  Preserve independent right-hand contours where they exist (Uziel, Dragon
  Fire and Highlander IIC); mirrored rigs inherit their left-hand shape.
- The authoring edit asserts that no non-primary shapes, material roles,
  parent links, named parts, head/hip/knee/ankle pivots, equipment manifests,
  jets, muzzles or weapon metadata change. It tests polygon validity before
  committing, and that corresponding modified main lofts match exactly.
- Automated Godot regression:
  `tests/unit/test_vx_camera_resculpt_next20.gd`, checking matching tiers,
  section ordering, no degenerate/reversed contours, model load with all
  record-sheet locations, and valid mirrored-source references.
- Still required before approval: Godot full test/smoke suite; shape/detail
  all-catalog integrity and backed-contact checks; compare posed 3D models
  with independent Catalyst front, side, quarter and overhead references
  (camera alignment before any additional geometry edits). Review missile
  apertures, hardpoint offsets, and mobile-size renders. Do not import
  exploratory fit numbers into approved score fields.

## Reference indexing and excluded high-risk leads

Photo index: `docs/graphics/plastic-reference-refined-158.csv` on audit
PR #268; individual modern plastic photo URLs are listed there and in
`docs/graphics/catalyst-photo-reference-index.json`.
As a known catalog reference, the [CGL miniature index](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
lists the Turkina, Crossbow and other plastic releases.
The Hunchback IIC's shoulder weapon towers and Turkina's very wide missile
nacelles remain intentionally prominent.

Deliberately deferred: Hatchetman, Locust IIC, Kodiak, Valkyrie and
Black Lanner (photo-fit yaw at the grid boundary); Rakshasa
(detached image-foreground subject segmentation). Foot/base width flags
alone do not justify increasing foot geometry. Other overlapping sculpt
PRs (#264–#267) were not included.

No game rules, dice, save/replay behavior, official unit loadout data,
or Android builds are changed.
