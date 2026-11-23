# Measured result of source-first sculpt experiment (2026-11-23)

**Status: first pilot successfully measured; target only partially met.**
PR #277 introduces a deterministic frozen before-sculpt baseline and one
first-pass geometry adjustment with **both** paired and independent
own-reference diagnostics.

## Conjurer (Hellhound) vs Dominator — single provisional quarter illustration

| Measure, 0–100 | Before | After | Goal / outcome |
| --- | ---: | ---: | --- |
| Official reference-pair silhouette similarity | 60.2 | 60.2 | **Fixed source target** |
| Game-model pair similarity | 67.8 | **60.8** | Within provisional [52.2, 68.2]; met |
| Conjurer vs its own official picture | 35.8 | **35.7** | Improve at least +5; **missed** |
| Dominator vs its own official picture | 32.8 | **33.9** | Improve at least +5; **missed** |
| Conjurer identity margin: own minus wrong source | +3.2 | +4.8 | Strongly positive; marginal improvement |
| Dominator identity margin | −0.8 | −0.6 | Must be positive; **missed** |

The model-to-model score fell **7.0 points** and now nearly equals the
rough-reference 60.2. This is **not** proof that either model resembles its
source. Reference-pair similarity without improved own-art fit is an
insufficient optimization objective.

### Specific independent sculpt changes

- **Dominator**: right-torso ER large laser replaced its too-short cuboid
  with a long, physically hollow, tapered **z-axis barrel**. Its muzzle
  position now follows the new RT barrel. Keep separate from the lower
  RA ER PPC, high asymmetric LT SRM-6 rack and recessed cockpit.
- **Conjurer**: narrower shoulder outer armor and angled paired horns
  extending beyond the shoulder crest. Existing LT two Streak SRM-2
  mounts, RT two ER medium lasers and RA large pulse laser remain unchanged.
- Both changes are **source-feature-specific**, not arbitrary separation
  by adding floating fins or changing mech height in a render.

### What to do next, before another geometry iteration

1. Match each reference **camera yaw, pitch, projection and subject pose**
   to the actually rigged game geometry. Export paired 64-pixel masks at
   the estimated *same* visual orientation. Try the repository's existing
   `tools/reference_camera_sweep.gd` for bounded candidates, then
   manually inspect and approve photographs/line-art camera metadata.
2. Record the largest **wrong regions** in each model's reference overlay:
   cockpit shape, arm-to-shoulder attachment, chest waist, leg bends,
   and front/rear projector length. Prefer the earliest genuinely
   mismatched moving mass, not another layer of armor.
3. Make a new separate source-level geometry change using the **same
   frozen source masks**, not a newly optimized target. Score before/after
   own-reference fit and wrong-reference identity, not pair similarity
   alone. Require high-confidence pose agreement before promoting
   to the permanent four-angle similarity scorecard.
4. Acquire matching-stance visual data for **HawkWolf vs Black Hawk
   Standard**; both TRO illustrations are accurate identities, but
   one is upright and the other deeply crouched. Its raw 38.4 reference
   score is diagnostic only, never a sculpt target.

## Method and limitations

Scores use the established **70% normalized IoU + 30% boundary F1**
over one coarse manually traced official-source illustration per model,
and the real exported Godot voxel occupancy masks (64×64). The broad
eight-point target tolerance reflects incomplete hand-traced silhouettes.
The official source drawings are not stored in git, only annotations.
**Neither pose nor camera is approved.** No values have been placed in
the verified four-view scorecard, and no claims are made about final
source-model likeness.

Artifacts for reproducibility: GitHub Actions `Pre-sculpt official-art
pair target trial` runs **45189419091** (before) and **45190240272**
(after). The pair manifest, contour polygons and score algorithm are
tracked in `docs/graphics/reference-pair-candidates.json` and
`tools/compare_reference_pair_targets.py`.
