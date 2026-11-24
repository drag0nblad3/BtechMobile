# All pending experimental chassis: paired, multi-view and assembly reconstruction

Scope is the union of the original 30-model intake and both 24-model Inner Sphere and Clan cohorts, deduplicated. All 78 distinct chassis are covered. Sources are the latest selected experimental spec available in the stacked PRs #307/#308 (or their inherited controls), not arbitrary unranked alternatives. Exact base path and optional JSON selector is recorded per model in deltas_01–11.json. Preserve existing weapon bindings and pivots. Production files remain untouched.

## Method

The runner generates new faceted and wedge armor shells and confidence-weighted/strict photo projection candidates. Unannotated models also test rounded shells. It reconstructs arm pairs, leg pairs, and multi-part central torso assemblies simultaneously, in a common baseline occupancy frame. Symmetric mode applies only matched mirrored edit deltas to sufficiently similar pairs; joint mode may preserve preexisting asymmetry and rejects material degradation of existing near-symmetry. Candidate selection is frozen-camera/pose, uses every stored registered view for scoring and filters unreliable projections by camera and limb pose residual. All accepted scored assemblies must increase global and local component mask overlap, stay within view and region regression bounds, maintain exclusive ownership/connected parts/backed neutral interfaces and preserve previously clear sampled muzzle cells. Source shape deltas are rerasterized and re-audited before saving. The unranked candidates are independent alternatives from the unchanged control, not combined or promoted. They lack a calibrated photo target and must not be called fidelity improvements.

## Results

- 78 distinct models; 51 scored using 74 existing views (61 with camera RMS <=18 px). 21 scored models have two or more views; 14 have two or more passing the camera cutoff (individual limb projections can still be excluded).
- 44 improved; 7 retained controls; 0 rejected final result; 0 blocked.
- 73 accepted assemblies, 282 component replacements, 56 symmetric assembly edits, 26 photo projection assemblies (14 on models with at least two camera-qualified views), 21146 selected changed cells.
- 27 unannotated chassis, 78 independently checked alternatives, 26077 cell changes across separate alternatives, not additive selected changes.
- 1425 attempted assembly alternatives; average scored model overlap 48.35% -> 49.05%. 0 final neutral structural faults; 0 final raster roundtrip failures; 652/790 initially clear axial samples, 652/790 afterward.

## Caveats

Existing approximate reference outlines only; no new photo acquisition, independent visual review, variant confirmation, production build, posed geometry collision test, engine runtime validation or wall-clock benchmark. Registered views with poor camera/pose fits still limit score interpretation; multi-view projection is only as good as alignment and region ownership. Group masks may include multiple components; occluded surfaces and intentional asymmetry are not fully determined. Source occupancy audit is not weapon bore certification. Stored deltas append voxel box runs to experimental source shapes and require further compaction/engine validation before production. No evidence of verified 3D likeness for the 27 unannotated models. All generated candidates remain experiments.

| Chassis | Before | After | Changed cells | Status |
|---|---:|---:|---:|---|
| catapult | 58.45% | 58.55% | 293 | photo-scored assembly |
| adder | 62.24% | 62.96% | 222 | photo-scored assembly |
| blackjack | 50.29% | 50.29% | 0 | retained control |
| locust | 42.58% | 42.82% | 173 | photo-scored assembly |
| archer | 33.12% | 33.54% | 680 | photo-scored assembly |
| awesome | 54.92% | 55.30% | 378 | photo-scored assembly |
| atlas | 68.89% | 69.97% | 852 | photo-scored assembly |
| banshee | 52.02% | 52.81% | 584 | photo-scored assembly |
| battlemaster | 42.29% | 42.29% | 0 | retained control |
| centurion | 49.42% | 50.02% | 232 | photo-scored assembly |
| charger | 38.51% | 38.83% | 268 | photo-scored assembly |
| enforcer | 53.84% | 54.77% | 462 | photo-scored assembly |
| hatchetman | 36.98% | 37.77% | 160 | photo-scored assembly |
| highlander | 47.23% | 47.23% | 0 | retained control |
| hunchback | 50.31% | 51.21% | 572 | photo-scored assembly |
| jagermech | 42.85% | 42.85% | 0 | retained control |
| phoenix_hawk | 44.44% | 44.65% | 80 | photo-scored assembly |
| trebuchet | 44.05% | 44.39% | 136 | photo-scored assembly |
| warhammer | 58.42% | 59.15% | 246 | photo-scored assembly |
| crab | 55.50% | 57.74% | 450 | photo-scored assembly |
| stalker | 50.07% | 50.30% | 844 | photo-scored assembly |
| panther | 56.56% | 57.26% | 208 | photo-scored assembly |
| dragon | 53.93% | 57.20% | 1258 | photo-scored assembly |
| cyclops | 53.35% | 53.71% | 476 | photo-scored assembly |
| griffin | 46.72% | 46.84% | 338 | photo-scored assembly |
| wolverine | 51.92% | 52.15% | 324 | photo-scored assembly |
| firestarter | 36.85% | 36.92% | 140 | photo-scored assembly |
| shadow_hawk | 47.85% | 49.44% | 687 | photo-scored assembly |
| thunderbolt | 35.45% | 35.45% | 0 | retained control |
| marauder | 24.49% | 24.49% | 0 | retained control |
| mad_dog | 33.49% | 34.50% | 616 | photo-scored assembly |
| hellbringer | 45.71% | 46.49% | 994 | photo-scored assembly |
| kit_fox | 51.77% | 53.65% | 298 | photo-scored assembly |
| cougar | 26.47% | 26.47% | 0 | retained control |
| shadow_cat | 47.58% | 50.20% | 591 | photo-scored assembly |
| viper | 53.80% | 54.06% | 162 | photo-scored assembly |
| gargoyle | 62.82% | 62.95% | 198 | photo-scored assembly |
| executioner | 58.15% | 58.32% | 324 | photo-scored assembly |
| grendel | 56.80% | 57.10% | 210 | photo-scored assembly |
| turkina | 43.49% | 44.06% | 1014 | photo-scored assembly |
| nova | 54.76% | 56.94% | 503 | photo-scored assembly |
| timber_wolf | 57.16% | 57.99% | 472 | photo-scored assembly |
| fire_moth | 51.68% | 52.76% | 300 | photo-scored assembly |
| dire_wolf | 48.67% | 50.44% | 1088 | photo-scored assembly |
| warhawk | 48.34% | 48.55% | 466 | photo-scored assembly |
| summoner | 50.54% | 52.17% | 392 | photo-scored assembly |
| king_crab | 50.11% | 51.72% | 1052 | photo-scored assembly |
| bushwacker | 57.09% | 57.45% | 196 | photo-scored assembly |
| marauder_ii | 55.05% | 55.32% | 695 | photo-scored assembly |
| nightstar | 36.00% | 36.08% | 422 | photo-scored assembly |
| longbow | 32.84% | 33.59% | 1090 | photo-scored assembly |
| stormcrow | — | — | 0 | unranked structural assemblies |
| mist_lynx | — | — | 0 | unranked structural assemblies |
| ice_ferret | — | — | 0 | unranked structural assemblies |
| nova_cat | — | — | 0 | unranked structural assemblies |
| crossbow | — | — | 0 | unranked structural assemblies |
| ebon_jaguar | — | — | 0 | unranked structural assemblies |
| huntsman | — | — | 0 | unranked structural assemblies |
| kingfisher | — | — | 0 | unranked structural assemblies |
| orion | — | — | 0 | unranked structural assemblies |
| crusader | — | — | 0 | unranked structural assemblies |
| grasshopper | — | — | 0 | unranked structural assemblies |
| wolfhound | — | — | 0 | unranked structural assemblies |
| zeus | — | — | 0 | unranked structural assemblies |
| cataphract | — | — | 0 | unranked structural assemblies |
| axman | — | — | 0 | unranked structural assemblies |
| victor | — | — | 0 | unranked structural assemblies |
| thug | — | — | 0 | unranked structural assemblies |
| spider | — | — | 0 | unranked structural assemblies |
| valkyrie | — | — | 0 | unranked structural assemblies |
| stinger | — | — | 0 | unranked structural assemblies |
| wasp | — | — | 0 | unranked structural assemblies |
| black_knight | — | — | 0 | unranked structural assemblies |
| guillotine | — | — | 0 | unranked structural assemblies |
| flashman | — | — | 0 | unranked structural assemblies |
| sentinel | — | — | 0 | unranked structural assemblies |
| vindicator | — | — | 0 | unranked structural assemblies |
| kintaro | — | — | 0 | unranked structural assemblies |

See batch_summary.json and summary_01–11.json for complete trial/audit details, deltas_01–11.json for exact source shape additions. Source delta application: deep-clone the specified base spec (array records selected by id and .spec, or explicit object property); append each appendShapes array to the part with matching name; rerasterize/audit. Unranked alternatives must each be applied independently, not concatenated.
