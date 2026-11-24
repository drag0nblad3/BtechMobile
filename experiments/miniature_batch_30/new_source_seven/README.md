# New-source seven: independent experimental reconstruction

Selected seven main chassis introduced in #269, absent from #309's 78-chassis scope and the known sibling experimental cohorts. Read main's docs/graphics/new-source-review.md and current model metadata. All work is isolated under experiments; existing models and rules remain untouched.

7 models, 140 components, 54875 cells, 0 neutral structural faults, 118/118 clear three-cell axial muzzle samples. Four newly hand-traced preview references (two miniature photos, two line illustrations) have frozen camera and articulated pose registration; all four improved versus their own first-pass experimental controls. No scores against main; no secondary registered views. First-pass geometry shares the prior Clan loft scaffold and uses chassis-specific replacements and separate weapon assemblies; not all parts independently hand-authored. Exact production variant binding, weapon muzzle placement, posed topology and runtime remain unverified. Main's extra CT/HD visual muzzles on Solitaire, Vulture Mk IV and Dominator have not been reconstructed in this pass. Black Hawk leg geometry and Vulture Mk IV pod geometry need particular review. The Vulture third-party three-view sculpt is only a secondary guide; the new Catalyst Core Box pack photo is a lead for the same generation, not an individually calibrated reference. No Godot tests or APK.

| Model | Parts | Cells | Faults | Axial samples | Initial → selected IoU |
|---|---:|---:|---:|---:|---|
| solitaire | 20 | 5441 | 0 | 3/3 | Unscored |
| vulture_mk_iv | 21 | 9991 | 0 | 26/26 | Unscored |
| hellhound_conjurer | 21 | 7382 | 0 | 7/7 | 46.86 → 49.39% |
| koshi_standard | 19 | 6459 | 0 | 16/16 | 48.76 → 50.13% |
| hawkwolf_hwk4f | 19 | 8435 | 0 | 40/40 | 28.37 → 30.55% |
| black_hawk_standard | 21 | 7369 | 0 | 18/18 | Unscored |
| dominator | 19 | 9798 | 0 | 8/8 | 48.83 → 51.05% |

Reproduce selected geometry by applying reference_trials_1–2.json appendShapes to matching parts in initial_1–4.json. final_summary.json is the rerasterized audit. contact_sheet.svg renders neutral source cells. Source photos are not redistributed; source links in profiles.json and reference_annotations.json. Add variant-matched front and side photographs, recalibrate stance/camera, and make larger independent anatomy replacements where overlap is poor before any promotion.
