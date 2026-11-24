# Hard-surface reconstruction toolbox

Use facets.js for explicit polygon cross sections, unrounded faces, selective corner bevels, sharp wedges and piecewise planar steps. Do not default to uniform bevels. Preserve cylinders only where called for. Match the silhouette and component outlines before choosing the primitive; match local face slope, panel break and connection angle; separate armor from mechanical joints. Do not confuse voxel stair-steps with an actual sculpted angular feature. Test source shape with test_facets.js, then rasterize and audit seam ownership, backed attachments, islands, and sampled weapon openings. Preserve bilateral symmetry unless references/variant demonstrate asymmetry.

Five current plastic photos inspected, one scored view per chassis, plus actual Nightstar side view and an Ebon Jaguar secondary render for qualitative review. Photo regions and joint marks are approximate. Fixed camera and stance per control. No claim of true multi-view photogrammetry. Orion has especially poor registration (22.27 px rigid RMS, up to 47.71 px limb RMS); reject its unilateral leg trial despite a small numeric gain. Geometry candidates: five, all zero structural faults, 49/49 axial sample points clear. Candidate weapon visual layouts are not yet verified against game variants. Axial sample is not full bore validation.

| Chassis | Control | Full trial | Final | Decision |
|---|---:|---:|---:|---|
| Orion | 48.88% | 48.42% | 48.88% | retain control |
| Marauder II | 53.30% | 53.90% | 53.90% | major rebuild |
| Nightstar | 54.64% | 50.87% | 54.84% | torso/head only |
| Kit Fox | 48.61% | 48.78% | 48.78% | major rebuild |
| Ebon Jaguar | 56.83% | 55.82% | 58.69% | dorsal pods only |

These are mean visible region IoUs under estimated registration, not real accuracy percentages. Small gains are weak evidence. All geometry is experimental. Main, production models and rules unchanged; no Godot validation. Use final_selection.json and final_before_after.svg, not earlier intermediate selections. Full candidates retained for further reference work.