# Photo-led resculpt: Bushwacker and King Crab

Two actual Catalyst plastic photographs per chassis, manually traced visible component masks and estimated rigid/joint landmarks, saved in annotations.json. Camera and articulated arm/leg pose fitted to the prior source assembly, frozen across comparisons. The registration is approximate, not photogrammetry: two mostly frontal oblique angles, 2.36–4.58 px rigid anchor RMS, up to 20.29 px limb landmark RMS. Rear-fin region is grouped and includes the gap; no rear or true side photograph yet. Scores are equal-weight mean visible-region IoU, not a percentage of real-world accuracy.

| Model | View | Control | Selected |
|---|---|---:|---:|
| Bushwacker | Lower front quarter | 48.65% | 56.57% |
| Bushwacker | Elevated front | 43.74% | 54.92% |
| King Crab | Elevated front | 39.80% | 39.86% |
| King Crab | Lower quarter | 42.83% | 43.53% |

Bushwacker: rebuilt the narrow sloped body, cockpit nose, cylindrical shoulders, mechanical arm links, elevated rack and forward pod; reattached nose gun mount, removed small disconnected head remnants and reopened nine sampled muzzle channels. 21 parts, zero neutral structural faults, 12/12 sampled three-cell channels clear. Exact variant weapon mapping not established. King Crab: rejected both major replacements for structural and/or photo score regressions. Retained slimmer mechanical arm links; other alternatives remain recorded, including unaccepted fins and carapace. 19 parts, zero neutral structural faults, 2/2 sampled channels clear. Further major resculpt required.

[Registered reference outlines and before/after projections](registered_comparison.svg) (no source photos redistributed; their URLs are in annotations.json). [Bushwacker neutral views](bushwacker_before_after.svg), [King Crab neutral views](king_crab_before_after.svg). Final selected specs: bushwacker_final.json and king_crab_selected.json. Prior experimental source controls unchanged. No production assets, game rules, Godot runtime tests or APK changes. Two of 48 chassis in the recent cohorts reviewed here, remaining 46 not completed in this pass.