# Retained-control directional reconstruction

This experimental follow-up to #309 targets all seven retained controls. Exact original experimental source paths and append-only part deltas appear in results_1.json and results_2.json. Existing frozen annotated photo registrations are reused, not newly reviewed. Directional face strips independently reshape torso panels, heads, paired shoulder shells, forearms, thighs, shins and feet while protecting non-armor cells, backed interfaces, and previously clear axial muzzle samples. The search tests trimming and extension on all three axes; bilateral x changes are mirrored. Each accepted geometry is rerasterized and compared cell-for-cell before selection, with final audit and per-view/region regression guards. Production files remain untouched.

## Results

7 models, 7 provisional improvements, 486 scored or structurally rejected trials, 41 selected group changes, 3962 final changed cells, 0 neutral audit faults; 60/66 sampled axial points clear before and 60/66 after. Mean per-model visible component mask IoU 38.44% → 40.45%.

| Chassis | Before | After | Changed cells | Views |
|---|---:|---:|---:|---:|
| blackjack | 50.29% | 52.18% | 409 | 1 |
| battlemaster | 42.29% | 44.86% | 651 | 1 |
| highlander | 47.23% | 50.20% | 521 | 1 |
| jagermech | 42.85% | 45.00% | 546 | 1 |
| thunderbolt | 35.45% | 37.01% | 714 | 2 |
| marauder | 24.49% | 25.79% | 682 | 2 |
| cougar | 26.47% | 28.10% | 439 | 1 |

## Limits

These are source-cell panel changes, not a fresh independent full anatomy reconstruction. No newly acquired photos; five models have only one annotated view; camera and pose residuals for Marauder and Thunderbolt are substantial, and BattleMaster exceeds 18 px camera RMS. Low absolute IoU remains. Neutral structural audit cannot certify posed geometry, runtime animation or weapon bores. No Godot tests, production integration or APK. No candidate should be considered visually approved. Preserve the controls and compare against new variant-matched miniature photographs before promotion.
