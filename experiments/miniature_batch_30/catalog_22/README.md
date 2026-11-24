# Catalog 22 — new isolated source sculpts

These 22 distinct chassis were selected from main's model inventory, excluding the known prior experimental chassis cohorts. Current Catalyst plastic miniature photos were inspected from the Jaded Falconer catalog; exact photo URL, intended main unit and chassis-specific profile recorded in profiles.json and each source spec. The Exterminator and Griffin IIC photo variants differ from the intended game unit; weapon placements are not certified. All files are under experiments; main remains unchanged.

The author uses a shared loft construction scaffold with bespoke armor profiles, independent gun and rack assemblies, custom head and shoulder geometry, and explicit armless topology for Cicada, Flea, and Hoplite. The first pass repairs overlap and backed seams. The second pass trims small detached slivers, rebuilds Devastator mounts, and tests aperture recuts. Ten fresh hand-traced catalog photos are used to register frozen camera and articulated stance and test directional panel changes. Scores compare against each model's repaired experimental control, not main or independent validation photos.

## Results

22 models; 428 separate components; 175813 occupied source cells; 0 neutral structural faults; 163/166 modeled axial samples clear; 14 second-pass repair actions; 10 single-view registered models, 10 provisional improvements, 5133 selected changed cells. Mean component-mask IoU 45.64% → 47.83%.

| Chassis | Parts | Cells | Axial clear | Experimental control → candidate |
|---|---:|---:|---:|---|
| annihilator | 19 | 10402 | 6/6 | 41.57% → 43.99% |
| assassin | 21 | 5654 | 8/8 | 47.94% → 50.39% |
| battle_cobra | 21 | 8157 | 4/4 | 58.31% → 60.85% |
| black_lanner | 21 | 8702 | 19/19 | 39.67% → 41.45% |
| cicada | 15 | 4160 | 2/2 | 48.18% → 51.17% |
| clint | 19 | 6127 | 1/1 | Not registered |
| crockett | 19 | 11194 | 14/14 | Not registered |
| dervish | 21 | 8545 | 24/24 | 45.52% → 48.22% |
| devastator | 21 | 11493 | 4/4 | 53.65% → 55.65% |
| emperor | 19 | 10062 | 2/4 | Not registered |
| exterminator | 20 | 8070 | 6/6 | Not registered |
| flea | 16 | 3005 | 2/2 | 22.59% → 24.53% |
| caesar | 19 | 8407 | 2/2 | Not registered |
| chameleon | 23 | 6862 | 4/4 | Not registered |
| griffin_iic | 21 | 7695 | 11/12 | Not registered |
| grizzly | 19 | 10963 | 12/12 | Not registered |
| gunslinger | 17 | 9744 | 2/2 | Not registered |
| hatamoto_chi | 25 | 10274 | 16/16 | Not registered |
| helios | 19 | 7997 | 5/5 | Not registered |
| hermes_ii | 20 | 5545 | 2/2 | Not registered |
| hoplite | 13 | 6675 | 2/2 | 43.52% → 45.23% |
| howler | 20 | 6080 | 15/15 | 55.41% → 56.85% |

## Outstanding defects

Two Emperor and one Griffin IIC sample remain obstructed; simple recuts failed neutral structural checks and were not selected. Flea has particularly low overlap, and Black Lanner and Annihilator need more substantial geometry changes. All 22 need additional independent views, explicit weapon/loadout verification, runtime rigging, posed collision and Godot validation. Twelve have photo-guided profiles only, no registered score; ten have one approximate manual registration, not multi-view reconstruction. No APK, production changes, or assertion of verified likeness. Selected geometry is reproduced by applying repair_results.json full part replacements and muzzle map to initial files, then the matching photo_trials appendShapes. The two contact sheets are neutral source-cell projections, not engine screenshots.
