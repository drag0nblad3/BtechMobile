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
| Additional Sarna infobox images | 36 | 44 candidates indexed; 36 newly covered, 8 duplicates; new 3-batch GitHub Action launched |
| No qualified image lead | **12** | Reference discovery required |
| **Total BattleMechs** | **289** | 277 have a reference candidate, 12 do not |
| Support/vehicle/battle-armor recipes | **45** | Not part of Mech-photo coverage; require their own category-matched source art |

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

## Evaluation procedure for the 44 newly indexed candidate images

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
photo. They must not be silently counted as completed Mech scoring.
