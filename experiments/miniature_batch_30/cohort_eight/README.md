# Eight-chassis independent miniature reconstruction — draft

Stacked on #296; prior 30-model experimental branch remains untouched except for the explicitly requested follow-on refinement on #296. This cohort is independent source geometry, not a production data replacement.

| Chassis | Parts | Cells | Initial mask IoU | Selected mask IoU | Changed cells | Neutral audit faults | Render |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| dragon | 28 | 11050 | 53.41% | 53.85% | 84 | 0 | [Four views](dragon_views.svg) |
| cyclops | 27 | 12012 | 53.23% | 53.23% | 0 | 0 | [Four views](cyclops_views.svg) |
| griffin | 26 | 8531 | 45.79% | 45.86% | 26 | 0 | [Four views](griffin_views.svg) |
| wolverine | 26 | 9530 | 51.58% | 51.73% | 52 | 0 | [Four views](wolverine_views.svg) |
| firestarter | 24 | 5798 | 35.79% | 36.61% | 182 | 0 | [Four views](firestarter_views.svg) |
| shadow_hawk | 26 | 8178 | 47.25% | 47.57% | 122 | 0 | [Four views](shadow_hawk_views.svg) |
| thunderbolt | 27 | 11932 | 35.25% | 35.32% | 96 | 0 | [Four views](thunderbolt_views.svg) |
| marauder | 22 | 12372 | 24.02% | 24.15% | 89 | 0 | [Four views](marauder_views.svg) |

## Method
- Inspected actual current CGL plastic catalog and painted photographs; 19 distinct photos reviewed, two manually annotated views per chassis (16 scored registrations). The author.js contains the independent source loft construction and seam-repair code. Seven upright chassis use a common assembly topology but individually specified body and limb profiles and separate weapon housings; Marauder has independent digitigrade geometry.
- Four initial builds needed supported hardpoint repairs. Dragon snout, Cyclops launcher/cannon, Shadow Hawk rack, Thunderbolt rack/SRM were explicitly reattached or shifted; repaired JSON records are authoritative controls. 206 separate components across eight selected assemblies; 57 alternate contour trials. Seven selections improved the diagnostic relative to the repaired initial controls, Cyclops retained the control. A final part-name verification corrected back-armor masks and recomputed frozen comparisons; the correctedSelection field supersedes original scores. No score is a comparison against production main.
- All eight pass the source-cell audit (one connected component per part, exclusive occupancy, >=1 two-layer backed 2x2 parent joint). This does not validate posed geometry, Godot, game rigging, mesh fidelity or weapon aperture certification. No production files or rules changed. Experimental pitches, pivots and muzzle coordinates need adaptation before any integration.
- References and design observations are in references.json. Cyclops CP-11-A photographs guide a CP-10-Z body; Thunderbolt second photo is tagged TDR-7S, with same plastic family but uncertain variant match. Grouped torso masks still include visible weapon housing outline; do not interpret as independently confirmed weapon fit. Wolverine detailed recipe path did not resolve on main; low-resolution recipe was available. Weapon/location metadata needs review. Source-cell renders are not in-engine captures.
- Some leg registration residuals remain large; Marauder opposite elevated view has especially poor rigid and arm/leg fit. Its low score and Thunderbolt and Firestarter scores warrant further anatomy/pose work, not production approval. Camera fitting uses manual estimated landmarks and limited roll/elevation search. Region scores are diagnostic, not calibrated physical accuracy.

## Prior three-chassis follow-up
Two additional passes on each of Crab, Stalker, Panther were committed to #296 using the pre-existing masks. Crab 55.27→55.77%, Stalker 49.80→50.27%, Panther 56.17→57.15%. All three retained zero source-cell faults. No new photo acquisition for those three. See next_reconstruction/*_passes_3_4.json and *_passes_3_4_views.svg.
