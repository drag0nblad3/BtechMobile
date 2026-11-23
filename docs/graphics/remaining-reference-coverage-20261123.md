# Remaining reference silhouette coverage — 23 November 2026

## Inventory and provenance

The canonical scorecard has **334** visual recipes: **289 BattleMech** recipes and
**45 non-Mech** recipes (support archetypes, vehicles and battle armor).
A numerical **reference fidelity** score is only defensible where the model
and a recognizable reference image depict the same chassis and where camera,
pose, cropping and foreground are reviewed.

| Source track | Distinct Mech recipes | Measurement status |
| --- | ---: | --- |
| Catalyst plastic photography | 159 | Existing provisional front/off-axis camera+pose trials |
| Legacy official TRO scans (nonoverlapping) | 82 | Existing provisional camera trials |
| Additional Sarna infobox images | 36 | 44 candidates indexed: 36 new Mechs and 8 non-Mech family candidates; 43/44 exploratory masks measured (Tsunami contour rejected) |
| No qualified image lead | **12** | Reference discovery required |
| **Total BattleMechs** | **289** | 277 have a reference candidate, 12 do not |
| Support/vehicle/battle-armor recipes | **45** | 8 family-level illustration candidates are in the same Sarna index; 37 still lack this source track |

**Important:** A source candidate does not imply verified angle, plastic
generation, pose or clean contour. The source-qualified final four-angle
scores and weighted overall values remain unapproved. Do not copy the
best camera-grid score into the approved reference-fit column.

## 12 BattleMech source gaps

| Recipe | Next source or verification action |
| --- | --- |
| `hatamoto_hi` | Find exact Hatamoto-Hi variant art; do not substitute generic Hatamoto-Chi |
| `hatamoto_kaze` | Find the exact Hatamoto-Kaze sculpt or Recognition Guide depiction |
| `hatamoto_ku` | Find Hatamoto-Ku-specific image; variant identity needs validation |
| `hatamoto_mizo` | Find Hatamoto-Mizo-specific image; avoid false equivalence to parent chassis |
| `hel` | Disambiguate Hel BattleMech artwork from other uses of name |
| `hermes_iii` | Locate Hermes III-specific art, not Hermes II |
| `nova_t` | Identify Nova T distinct from Nova or Nova Cat |
| `rattlesnake` | Locate exact Rattlesnake variant art and validate naming |
| `rattlesnake_ii` | Locate Rattlesnake II, not original Rattlesnake |
| `suburbanmech` | Locate SuburbanMech art rather than UrbanMech art |
| `titan` | Disambiguate Titan BattleMech from other Titan units |
| `von_rohrs_hebi` | Find a named von Rohrs (Hebi) illustration or qualified historical art |

The Sarna infobox discovery tool tried named pages for these 12 and did not
verify matching illustrations. Missing images are recorded explicitly; no
numeric reference-fit scores are invented.

## Evaluation procedure for the 44 newly indexed candidate images (36 BattleMechs, 4 vehicles and 4 battle-armor variants)

1. The matrix job `voxel-sarna-remaining.yml` exports authored voxel
   silhouettes, then projects each through a bounded camera search
   (orthographic and perspective) with **no sculpt or gameplay rig changes**.
2. The scorer isolates inked source contours, checks gross foreground
   coverage and computes exploratory IoU+boundary-F1 similarity.
3. Review **each** photo/artwork for exact chassis identity, foreground,
   handedness, camera angle and limb pose. The automatic best fit is only a
   candidate. A 2D line-art source cannot validate 3D back/top silhouette.
4. For each failing angle, adjust the *rig pose first*, then camera, and
   resculpt only confirmed geometry discrepancies. Maintain solid connected
   joints and avoid torso/arm bloating.
5. Never claim a complete four-view overall until front, side, quarter and
   top references and pose/camera verification exist.

The 45 non-Mech assets should use reference material appropriate to each
vehicle, battle armor, or support archetype rather than a BattleMech plastic
photo. Four vehicles and four Elemental battle-armor variants have family-level
art leads in the 44-image Sarna batch. These 8 are not counted as Mechs and
must not be marked as exact-variant matches.

## Measured results from the remaining-source batch

The GitHub Actions matrix run [45166256559](https://github.com/drag0nblad3/BtechMobile/actions/runs/45166256559) exported **44/44** projected source models with **zero projection failures** and **792 camera candidates** (360 + 360 + 72). The reference contour extractor returned **43 provisional scores**, comprising **35 BattleMechs** and **8 vehicle/battle-armor family examples**. The remaining `tsunami` illustration was **rejected** because ink/background extraction covered 76.7% of the image and failed the contour sanity threshold; it must be manually isolated, not forced through a permissive cutoff.

Per-model measurements, provisional camera yaw/pitch, source URL and rejection reasons are recorded in [sarna-reference-first-pass-44.csv](sarna-reference-first-pass-44.csv). No per-angle or overall *approved* score was written. This batch did not optimize joint poses to the photographed/illustrated stance, and the reference viewpoints have not been manually approved. Numerical fit alone must not be treated as proof of sculpt accuracy.
