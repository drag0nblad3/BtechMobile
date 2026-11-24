# Second-round independent reconstruction refinement

All ten previously reconstructed chassis now have a changed second-round selected source assembly, approximate photo-mask comparison, compiled experimental recipe, and four-view SVG. Atlas received six stages / 19 candidate trials in round two plus four stages / 12 trials in round three. The 20 other chassis in the 30-model intake batch are not part of this round.

| Chassis | Fixed-registration before | Round 2 after | Changed component cells | Alternatives evaluated | Source faults | Render |
|---|---:|---:|---:|---:|---:|---|
| atlas | 61.39% | 68.10% | 1080 | 19 | 0 | [Four views](atlas_round2_views.svg) |
| blackjack | 58.42% | 59.29% | 306 | 11 | 0 | [Four views](blackjack_round2_views.svg) |
| locust | 38.56% | 39.33% | 119 | 11 | 0 | [Four views](locust_round2_views.svg) |
| catapult | 63.74% | 64.57% | 365 | 9 | 0 | [Four views](catapult_round2_views.svg) |
| awesome | 56.45% | 56.84% | 326 | 9 | 0 | [Four views](awesome_round2_views.svg) |
| battlemaster | 62.47% | 63.63% | 236 | 9 | 0 | [Four views](battlemaster_round2_views.svg) |
| archer | 47.03% | 47.75% | 206 | 10 | 0 | [Four views](archer_round2_views.svg) |
| adder | 59.16% | 59.62% | 246 | 10 | 0 | [Four views](adder_round2_views.svg) |
| centurion | 60.25% | 60.57% | 8 | 12 | 0 | [Four views](centurion_round2_views.svg) |
| hunchback | 71.37% | 71.78% | 124 | 9 | 0 | [Four views](hunchback_round2_views.svg) |

Atlas round three: 68.10% → 68.79%; 544 additional changed component cells; zero structural faults; [final render](atlas_round3_views.svg). Final Atlas increase from the new round-two fixed-registration baseline: 7.41 points. The trial review stores every candidate result; round two additionally preserves selected skull/shoulder alternatives. Round three was reproduced from the original control and accepted round-two steps; score matched round two before further edits.

## Method and limits

Reused the existing hand-marked component masks and camera landmarks, registered a fresh camera once per photo and improved joint-only stance search (rigid housings locked; independent shoulder/hip/elbow/knee/hock bounds). Freeze camera and actual joint poses across all geometry candidates in each round. Candidate edits insert extra loft stations, change component contour profiles, and where justified recut explicit parent sockets rather than leave interpenetration. Reject any candidate with disconnected parts, overlaps, insufficient two-layer backed parent contact, newly occupied sampled muzzle-neighborhood cells, no cell change, or degraded overlap objective. Preserve original muzzle coordinate records. Structural check is a neutral source-cell audit; it is not a rig deformation, weapon aperture certification, Godot smoke test, or game-runtime check. Scores are diagnostic regional IoU, dependent on prior approximate annotations and residual camera/stance error. Not a comparison to production main, and not independently verified miniature fidelity. No new photo acquisition or Godot validation in this round. Main untouched.

See the per-chassis *_round2_review.json and atlas_round3_review.json for exact accepted/rejected candidate geometry operations, per-view regional scores, registration residuals, and compiled selected recipes. Round-two code: round2_lab.js. Earlier review JSON may have more than one candidate or contain prior scores from a different pose solver; do not compare those scores as if they were obtained under the same registration.
