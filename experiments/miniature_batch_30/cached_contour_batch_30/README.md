# Cached contour search: 30-model batch

Reuses existing approximate annotated miniature reference photos and their associated experimental selected source geometries (not production geometry, and not necessarily the most recent alternative from other branches). No newly traced or independently verified photos. Camera and pose frozen per model. Generates local width/depth/offset alternatives for body, arm links, legs and feet. Rejects structural faults, newly blocked sampled muzzle cells, and final per-view mean IoU loss greater than 0.5 percentage points. The per-trial gate also caps per-view and region regression. Results are provisional, not verified likeness. Sample clearance is not bore certification. The cache counts avoided rasterizations, not wall-clock speedup. No production files or runtime tests changed. 8 models have at least one camera alignment RMS above 15 pixels; all need visual review, especially low scores. Existing obstructed muzzle samples are not repaired by this trial.

30 distinct chassis (30 unique); 30 improved, 0 retained, 0 rejected, 0 blocked; 46 registered views; 708 variations; 10152 changed cells; 0 final structural faults; 157/291 initially clear axial samples, 157/291 after. Mean model score 47.53% -> 48.12%. Cache reuse 84.1%. No elapsed performance benchmark.

## Per model

| Model | Control IoU | Candidate IoU | Changed cells | Status |
|---|---:|---:|---:|---|
| catapult | 58.04% | 58.45% | 368 | provisional improvement |
| adder | 61.43% | 62.24% | 188 | provisional improvement |
| blackjack | 48.94% | 50.29% | 538 | provisional improvement |
| locust | 41.87% | 42.58% | 192 | provisional improvement |
| archer | 32.33% | 33.12% | 652 | provisional improvement |
| awesome | 53.97% | 54.92% | 426 | provisional improvement |
| banshee | 50.25% | 52.02% | 406 | provisional improvement |
| battlemaster | 41.87% | 42.29% | 270 | provisional improvement |
| centurion | 48.28% | 49.42% | 534 | provisional improvement |
| atlas | 68.79% | 68.89% | 156 | provisional improvement |
| charger | 37.80% | 38.51% | 420 | provisional improvement |
| enforcer | 53.02% | 53.84% | 451 | provisional improvement |
| hatchetman | 36.52% | 36.98% | 180 | provisional improvement |
| highlander | 46.18% | 47.23% | 448 | provisional improvement |
| hunchback | 49.52% | 50.31% | 450 | provisional improvement |
| jagermech | 42.68% | 42.85% | 390 | provisional improvement |
| phoenix_hawk | 43.82% | 44.44% | 156 | provisional improvement |
| trebuchet | 43.63% | 44.05% | 234 | provisional improvement |
| warhammer | 57.31% | 58.42% | 809 | provisional improvement |
| crab | 55.27% | 55.50% | 188 | provisional improvement |
| dragon | 53.85% | 53.93% | 104 | provisional improvement |
| cyclops | 53.23% | 53.35% | 48 | provisional improvement |
| griffin | 45.86% | 46.72% | 498 | provisional improvement |
| wolverine | 51.73% | 51.92% | 344 | provisional improvement |
| firestarter | 36.61% | 36.85% | 224 | provisional improvement |
| shadow_hawk | 47.57% | 47.85% | 214 | provisional improvement |
| thunderbolt | 35.32% | 35.45% | 388 | provisional improvement |
| marauder | 24.15% | 24.49% | 335 | provisional improvement |
| stalker | 49.80% | 50.07% | 272 | provisional improvement |
| panther | 56.17% | 56.56% | 269 | provisional improvement |

See summary_1–3.json, trials_1–3.json and batch_summary.json for full audit results. Changed source specs saved separately. For blocked/rejected/unchanged models, retain inherited control. No production adoption.
