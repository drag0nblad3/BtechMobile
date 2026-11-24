# Catalog 30 — isolated new chassis, with sharp-edged armor and prior-batch repairs

This experiment is stacked on #312. All 30 main model IDs were verified in data/voxels before authoring; main and production data remain unchanged. Profiles reference the [CGL catalog](https://jadedfalconer.com/Pages/6How/miniatures) by base number and intended sculpt variant. Catalog metadata and provisional anatomy profiles are not evidence that all 30 individual images have been inspected or registered. Some variants differ from the game units; validate actual variant weapons and catalog identifiers before integration.

## Previous batch repairs
Emperor and Griffin IIC have rebuilt weapon housings with all three formerly blocked axial sample points clear, no neutral structural faults. Full selected specs and 15 trials apiece in prior_batch_repairs.json. Flea: added a second tentative photographic registration to the previous review, tested 27 distinct core/head/leg geometry replacements, no candidate met both structural and per-view score guards. Retain #312's control; do not promote the failed alternatives. The new two-view score is not comparable to the old single-view score. The second reference's image identity and calibration need independent verification.

## Thirty new assemblies
Sharp corners are allowed and intentional. hard_edges.js retains square or near-square profile stations on angular armor and weapon housings, with chamfers of 0–4.5% on the targeted profiles, leaving genuinely curved parts intact. This touches 222 components across 18 chassis. New Goliath and Scorpion models have four separate articulated leg chains; Shiro has a separate blade and grip; Locust IIC has close-coupled gun pods rather than full humanoid arms. Rebuilt six weak weapon mounts and shifted Scorpion's rack clear of the cockpit. Neutral connectivity checks test exclusive cell ownership, contiguous parts and backed 2x2 interfaces; they are not posed collision or Godot tests.

Four new registered comparisons: one actual Avatar miniature photograph and three catalog render crops (Akuma, Shiro, Grand Dragon). Akuma's pictured variant differs; all four scores are approximate visible-region mask IoU against the experimental control, not main. They are not independently validated likeness measures. Shiro in particular needs sword pose and torso anatomy reconstruction. 26 chassis have profiles only, no individual calibrated comparison. Multi-view, weapon/variant completeness, engine integration and posed testing remain outstanding for all 30.

Final replay: 30 models, 563 parts, 248592 occupied source cells, 0 neutral structural faults, 280/280 modeled axial points clear (not a through-barrel test). Four registered models improved; mean 31.23% → 32.79%, 2874 changed cells. No APK or production changes.

| Chassis | Parts | Cells | Samples clear | Score |
|---|---:|---:|---:|---|
| akuma | 21 | 10513 | 13/13 | 36.75% → 38.34% |
| avatar | 20 | 10078 | 25/25 | 33.04% → 34.74% |
| grand_dragon | 18 | 7824 | 4/4 | 38.46% → 40.50% |
| shiro | 22 | 11147 | 41/41 | 16.69% → 17.59% |
| chimera | 20 | 7177 | 12/12 | Unregistered |
| venom | 19 | 6082 | 4/4 | Unregistered |
| bane | 19 | 14086 | 15/15 | Unregistered |
| firebee | 18 | 5658 | 4/4 | Unregistered |
| firefly | 18 | 5919 | 7/7 | Unregistered |
| gladiator | 18 | 8154 | 7/7 | Unregistered |
| goliath | 18 | 9655 | 2/2 | Unregistered |
| havoc | 19 | 6297 | 2/2 | Unregistered |
| highlander_iic | 19 | 12551 | 36/36 | Unregistered |
| hunchback_iic | 19 | 7959 | 2/2 | Unregistered |
| icarus_ii | 17 | 6987 | 1/1 | Unregistered |
| javelin | 19 | 6653 | 12/12 | Unregistered |
| jenner_iic | 21 | 7138 | 11/11 | Unregistered |
| lancelot | 18 | 8203 | 3/3 | Unregistered |
| linebacker | 19 | 8311 | 2/2 | Unregistered |
| locust_iic | 18 | 5426 | 9/9 | Unregistered |
| mackie | 19 | 11456 | 4/4 | Unregistered |
| mauler | 19 | 12106 | 34/34 | Unregistered |
| mercury | 19 | 5554 | 1/1 | Unregistered |
| merlin | 18 | 7985 | 6/6 | Unregistered |
| mongoose | 17 | 5291 | 2/2 | Unregistered |
| night_gyr | 17 | 10598 | 4/4 | Unregistered |
| ostroc | 19 | 8187 | 6/6 | Unregistered |
| ostscout | 18 | 5507 | 0/0 | Unregistered |
| ostsol | 19 | 8099 | 4/4 | Unregistered |
| scorpion | 18 | 7991 | 7/7 | Unregistered |

Selected source geometry is initial_1–6.json with repair_results.json replacements and muzzle map, overridden by full specs in mount_rebuilds.json then receiver_rebuilds.json, then matching photo_trials appendShapes. render.js implements this replay. Contact sheets show source-cell projections, not game screenshots. No Godot runtime tests available in this session; draft only.
