# Six-chassis photographic resculpt round

Eight actual web image search thumbnails were inspected and manually outlined in 512×512 display coordinates. The exact source URLs and polygons are in observations.json. Nova and Nightstar have two views; Marauder II, Fire Moth, Timber Wolf and Longbow have one. Timber Wolf reference is a Catalyst 100mm release rather than a verified matching tabletop variant. Region groups are coarse and do not resolve all occlusions. Three or four rigid anchors per image; joint marks only where visible. Nightstar side and Longbow side have no pose registration. Camera and pose frozen across comparisons. These scores are diagnostic equal-weight visible-region IoU, not measured real-world fidelity.

Two major alternatives per chassis, followed by four component-group replacement trials per chassis and structural/axial sample checks. Major variants retained for Marauder II, Fire Moth and Timber Wolf; Nova and Nightstar selectively revised; Longbow unchanged because alternatives regressed and the side registration is poor. All final neutral-cell assemblies pass existing audit. Selected source files: selected_1.json and selected_2.json. Full major alternatives and camera/pose data in *_trials.json. [Before/after neutral source projections](before_after.svg), not in-engine renders.

| Chassis | View | Baseline | Selected | Camera RMS (px) |
|---|---:|---:|---:|---:|
| nova | 1 | 49.89% | 51.51% | 6.39 |
| nova | 2 | 51.49% | 53.21% | 2.79 |
| nightstar | 1 | 46.42% | 46.57% | 15.95 |
| nightstar | 2 | 14.29% | 14.87% | 13.86 |
| marauder_ii | 1 | 49.82% | 52.36% | 2.78 |
| fire_moth | 1 | 48.09% | 50.26% | 10.88 |
| timber_wolf | 1 | 52.36% | 52.95% | 1.87 |
| longbow | 1 | 32.30% | 32.30% | 39.66 |

115 components across six candidates; 123/123 three-cell axial sample points clear (not bore certification). No game variant validation or production edits. Longbow's nearly 40 px rigid RMS invalidates a confident photographic comparison; Nightstar side scores also too low for confident selection. Limb residuals reach roughly 32 px. Need additional independent angles, improved registration, further geometry work and Godot validation. 39 of the recent 48 chassis still have no individual photographic review in this sequence; nine reviewed including the three earlier chassis, not nine completed likeness reconstructions. Prior round 1/2 reference annotations have not been independently verified in this round; do not treat their scores as calibrated evidence. No changes to main.