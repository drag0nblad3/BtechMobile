# First reference-photo silhouette scores: camera and rig hypotheses

**Status:** exploratory two-photo scoring, NOT approved shape fidelity. The main
334-recipe scorecard intentionally leaves final reference-fit and overall fields
blank until every required photo/pose/camera match is verified.

The results below were produced by the `Reference camera and pose silhouette QA`
GitHub Actions workflow on 23 November 2026. The workflow ran successfully for
both models, 18 total camera hypotheses, the four camera tests, three stance
tests and six Python scoring tests:
https://github.com/drag0nblad3/BtechMobile/actions/runs/45115637685

| Chassis | Source | Angle | Baseline after subject masking | Best nearby camera | Camera (yaw°, pitch°) | Approval |
| --- | --- | --- | ---: | ---: | --- | --- |
| Battleaxe | 2023 Catalyst plastic photo, retailer | front | 45.3/100 | **47.8/100** | +7, +2, perspective, 4.8 height-distances | **Provisional** |
| Phoenix Hawk | Catalyst painted Premium Miniature | quarter | 39.9/100 | **41.1/100** | +18, -27, perspective, 4.0 height-distances | **Provisional** |

Method: each candidate image is temporarily downloaded and segmented, the
whole authored 3D voxel shape is posed through the existing articulated
component pivots, and each projected voxel is filled from its **eight projected
corners**. Scoring is 70% occupied-mask intersection-over-union plus 30% boundary
F1. A restricted 3 × 3 camera yaw/pitch grid around a photo-estimated viewpoint
is tested without changing geometry. Initial camera/pose numbers are
**hypotheses**, not visually approved measurements. Camera search may compensate
for incorrect masks, so never promote a numerical winner directly to the main
scorecard.

## Battleaxe: front

Reference: https://www.wargamesemporium.co.uk/products/battletech-battleaxe-single-mech

- The upper launcher is at broadly the correct location, and the frontal gun
  arms and torso are recognizably asymmetric. The mask still shows a heavier
  continuous midsection and less clear shoulder/arm separation than the plastic.
- Initial raw test without a good base mask scored 43.4; dark-base exclusion
  improved the *same photographed stance* to 45.3 before a camera adjustment
  produced 47.8. This change is partly **segmentation quality**, not sculpt
  improvement. The photo's hex base overlaps the feet; the lower-body mask
  still contains contamination and is not reference-approved.
- Geometry or rig refinement: independently back the asymmetrical shoulder
  racks, expose negative space under their lower edges, check arm cannon angles
  and leg stance. Do not add extraneous massive side shields. Reacquire a
  cleaner view or manually mask the base/feet before an accepted front score.

## Phoenix Hawk: three-quarter

Reference: https://store.catalystgamelabs.com/products/battletech-phoenix-hawk-premium-miniature
Current painted image: https://store.catalystgamelabs.com/cdn/shop/files/upload_20221116-013936.png?v=1790075417

- Source image has a background-free view of Catalyst's articulated premium
  figure, with one raised knee and an extended cannon arm.
- First rough pose/image-mask comparison was 38.8 (best nearby camera 40.5).
  I then revised the pose hypothesis to raise one knee more sharply, keep the
  other leg in a planted/descending posture, and extend the cannon arm; its new
  raw score is 39.9, with a bounded camera candidate at **41.1**.
- The actual logged side-by-side masks still show the model's upper armor and
  jet towers too broad/connected versus the reference and the raised-knee
  negative space not fully captured. Geometry must not be crushed to improve a
  wrong pose: inspect real rendered shoulder width, twin jet roots, arm weapon
  extension, hip chain and the height of the raised knee together.
- Calibrated-candidate pitch -27° was the best of only nine tested images.
  This is a **search result**, not a verified statement about the photo's lens
  or exact viewing angle.

## Remaining steps

1. Manually approve segmentation (especially Battleaxe's hex base), handedness,
   camera projection and pose for each individual photo.
2. Run a second rig adjustment where the Phoenix Hawk knee and cannon still
   deviate; change hull geometry only when camera/stance error is eliminated.
3. Expand photo collection to front, side, quarter, top. No full overall score
   can be reported from one angle; no lower-confidence source gets an
   artificially boosted numerical match.
4. Continue the 334-model scorecard one chassis at a time. Source plastic
   miniature links and per-view comments should remain traceable.

The linked external photos are *not* checked into the repository. The QA
artifact contains only source identifiers, derived silhouette masks and
exploratory numerical fit results. No game assets, core rules, or live rig
defaults were modified.
