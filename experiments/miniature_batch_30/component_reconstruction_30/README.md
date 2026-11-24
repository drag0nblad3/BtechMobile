# Independent component reconstruction — 30-model batch

This pass evaluates 30 distinct experimental chassis, none from PR #307's 30-model cohort (ten were in earlier contour pilots). It creates alternative occupied armor shells from independent rounded, faceted, wedge, bell and projected photo-mask volume families, rather than scaling the original polygons. It identifies up to three weakest annotated regions' eligible components; for unannotated models it tries core, head and left lower leg. The original non-armor cells, two-cell joint collars, other-part occupancy and previously clear three-cell axial muzzle samples are protected. The photo-hull variant clips candidate cells against approximate frozen projections only when camera RMS is <=18 pixels. Shape candidates must change at least 35 cells or 12% of a component, fit bounded volume limits, retain connected shells and backed interfaces, and round-trip through the existing voxel source rasterizer. Annotated replacements also need a positive local and global score with bounded per-view and per-region regression. No silhouette score is fabricated for unannotated models; independent structural alternatives are retained but unranked. The most changed unranked example is not a likeness recommendation. Previous reference outlines and geometry inherited; no newly checked photos, symmetry pairing, unseen-side validation, complete cavity preservation, posed validation or Godot runtime test. Single-view clipping can overfit and produce one-sided geometry. Coarse axial samples are not weapon certification.

## Results

30 models (30 unique), 21 photo-scored, 19 improved and 2 controls retained. 9 without masks, 20 structurally checked independent alternatives. 423 attempted replacements, 42 accepted component shells, 7124 selected changed cells plus 3593 cells across independent unranked alternatives (not additive within a model). 28 photo views. Mean scored model IoU 47.54% -> 48.68%. 0 final neutral audit faults, 0 final roundtrip failures, 381/385 clear axial samples -> 381/385. Existing blocked samples remain. 6 scored models have a camera RMS >15 px. No production edits or wall-clock benchmark.

| Chassis | Baseline | After | Selected changed cells | Status |
|---|---:|---:|---:|---|
| mad_dog | 33.10% | 33.49% | 918 | photo-scored replacement |
| hellbringer | 44.55% | 45.71% | 403 | photo-scored replacement |
| kit_fox | 47.53% | 51.77% | 551 | photo-scored replacement |
| cougar | 25.75% | 26.47% | 225 | photo-scored replacement |
| shadow_cat | 46.08% | 47.58% | 354 | photo-scored replacement |
| viper | 53.80% | 53.80% | 0 | retained control |
| gargoyle | 60.94% | 62.82% | 689 | photo-scored replacement |
| executioner | 56.08% | 58.15% | 746 | photo-scored replacement |
| grendel | 56.01% | 56.80% | 233 | photo-scored replacement |
| turkina | 42.59% | 43.49% | 529 | photo-scored replacement |
| nova | 53.38% | 54.76% | 217 | photo-scored replacement |
| timber_wolf | 57.08% | 57.16% | 78 | photo-scored replacement |
| fire_moth | 50.94% | 51.68% | 149 | photo-scored replacement |
| dire_wolf | 48.55% | 48.67% | 102 | photo-scored replacement |
| warhawk | 48.34% | 48.34% | 0 | retained control |
| summoner | 49.82% | 50.54% | 159 | photo-scored replacement |
| stormcrow | — | — | 0 | unranked structural alternatives |
| mist_lynx | — | — | 0 | unranked structural alternatives |
| ice_ferret | — | — | 0 | unranked structural alternatives |
| nova_cat | — | — | 0 | unranked structural alternatives |
| crossbow | — | — | 0 | unranked structural alternatives |
| ebon_jaguar | — | — | 0 | unranked structural alternatives |
| huntsman | — | — | 0 | unranked structural alternatives |
| kingfisher | — | — | 0 | unranked structural alternatives |
| king_crab | 49.17% | 50.11% | 302 | photo-scored replacement |
| bushwacker | 56.32% | 57.09% | 168 | photo-scored replacement |
| marauder_ii | 52.08% | 55.05% | 509 | photo-scored replacement |
| nightstar | 33.95% | 36.00% | 422 | photo-scored replacement |
| longbow | 32.30% | 32.84% | 370 | photo-scored replacement |
| orion | — | — | 0 | unranked structural alternatives |

All per-trial outcomes in summary_1–6.json; selected source specs saved as *_selected.json. Unranked independent delta sets and example full specs saved separately. Do not merge any experimental source into production without visual comparison and engine QA.
