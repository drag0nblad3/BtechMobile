# Clan cohort — 24 experimental sculpts

Stacked on #300; production assets, rigs, game data and rules untouched. This batch uses five current Catalyst miniature pack overview images as visual design guidance. The anatomy profiles and source page links are in profiles.json. These are provisional shared-loft constructions with chassis-specific profiles, not independent multi-photo calibrated reconstructions. No individual photo outlines, fitted cameras, pose registration or similarity scores were obtained this round. Exact variants, game weapon layouts and rig coordinate mapping are not yet validated; apparent launch tubes and barrel counts are illustrative.

## Final neutral-cell checks

24 models, 441 separate source parts, 216612 occupied cells. All 24 pass the existing audit for exclusive cell ownership, one connected component per part and backed parent joints. Fire Moth's first shoulder pass failed six checks because its forearm masses overlapped the raised shoulders; the source was rebuilt forward and audited again. Fifteen split-barrel trials passed the structural gate. Five blocked muzzle sample points recut successfully; two Mad Dog rack sample points remain blocked, and the attempted changes were rejected. 288/290 sample points clear in the final coarse diagnostic. This is not a ray-through-barrel or weapon certification.

| Chassis | Parts | Cells | Structural faults | Clear muzzle samples |
|---|---:|---:|---:|---:|
| Timber Wolf | 21 | 12998 | 0 | 42/42 |
| Executioner | 17 | 9562 | 0 | 1/1 |
| Nova | 19 | 8786 | 0 | 12/12 |
| Grendel | 19 | 6929 | 0 | 2/2 |
| Dire Wolf | 18 | 13945 | 0 | 9/9 |
| Stormcrow | 17 | 7561 | 0 | 3/3 |
| Shadow Cat | 19 | 6729 | 0 | 2/2 |
| Mist Lynx | 17 | 4965 | 0 | 2/2 |
| Summoner | 18 | 10377 | 0 | 17/17 |
| Gargoyle | 17 | 9586 | 0 | 4/4 |
| Hellbringer | 18 | 9435 | 0 | 8/8 |
| Mad Dog | 21 | 10804 | 0 | 42/44 |
| Ice Ferret | 17 | 7073 | 0 | 2/2 |
| Viper | 17 | 5591 | 0 | 2/2 |
| Warhawk | 18 | 11944 | 0 | 14/14 |
| Nova Cat | 17 | 8669 | 0 | 5/5 |
| Cougar | 21 | 8115 | 0 | 22/22 |
| Kit Fox | 19 | 5473 | 0 | 2/2 |
| Fire Moth | 17 | 5033 | 0 | 8/8 |
| Crossbow | 19 | 10352 | 0 | 42/42 |
| Ebon Jaguar | 19 | 9382 | 0 | 2/2 |
| Huntsman | 18 | 7711 | 0 | 8/8 |
| Kingfisher | 17 | 10724 | 0 | 3/3 |
| Turkina | 21 | 14868 | 0 | 34/34 |

[Three-angle contact sheet](contact_sheet.svg) contains 72 approximate orthographic source-cell projections, not in-engine renders. Initial records retained in initial_1–3.json, with Fire Moth's failed initial trial preserved. Final candidates are selected_1–3.json overridden by aperture_repairs.json for Nova, Mad Dog and Nova Cat. final_summary.json is authoritative. sculpt.js and refine.js use the inherited reconstruction_lab.js and cohort_eight/author.js repair helper. No Godot tests, production comparison, posed validation, or APK build performed.

Next: obtain individual multi-angle plastic photographs, trace components, register camera and pose, replace incorrect anatomy and weapons, address Mad Dog rack occlusion, and validate against game variants before any production adoption.