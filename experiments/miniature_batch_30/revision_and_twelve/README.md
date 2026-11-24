# Revision and twelve-model independent experimental cohort

Stacked on #297. No production game files, rules, rigs, or previously merged assets modified. This is a draft, not a release candidate.

## Revisions to the prior eight-model cohort
New actual photographs and manual outlines added to Marauder, Firestarter, and Thunderbolt (three registered views each). Two major anatomy alternatives per chassis were authored and evaluated. Each failed the neutral attachment audit and/or frozen-reference score; original alternatives and failure reports are retained. Subsequent structurally gated local trials improved Marauder 28.7425% → 28.8233% and Firestarter 42.695% → 42.7467% on the new three-view registration. Thunderbolt 33.4123% retained the control. The new scores are NOT directly comparable to #297's old two-view scores. No big anatomy alternative selected; those still need redesign. See *_major_revision.json, *_safe_revision.json and *_safe_views.svg. Photographs and source URLs embedded in records; no third-party image files redistributed.

## Twelve independently authored model candidates
254 subassemblies; 14 scored photo views in final comparison records. All twelve selected neutral-cell assemblies have one connected component per part, exclusive cell occupancy, and two-layer backed 2x2 parent contacts (within the existing audit). Seven required explicit seam/mount repairs. The Charger detached chest-plate sliver (22 cells) was removed after re-cutting the breast plate. Others included the Hatchetman grip, Phoenix Hawk and Trebuchet upper-arm interfaces, Warhammer rack/light mounting, UrbanMech laser housing, Rifleman head/radar mounting.

| Chassis | Parts | Photo views | Initial frozen fit | Selected fit | Audit faults | Render |
|---|---:|---:|---:|---:|---:|---|
| banshee | 22 | 1 | 61.44% | 61.48% | 0 | [Four views](banshee_views.svg) |
| charger | 23 | 1 | 54.76% | 54.77% | 0 | [Four views](charger_views.svg) |
| enforcer | 20 | 1 | 49.37% | 49.50% | 0 | [Four views](enforcer_views.svg) |
| hatchetman | 23 | 1 | 58.54% | 58.61% | 0 | [Four views](hatchetman_views.svg) |
| highlander | 23 | 1 | 62.50% | 62.72% | 0 | [Four views](highlander_views.svg) |
| jagermech | 19 | 1 | 46.88% | 47.26% | 0 | [Four views](jagermech_views.svg) |
| phoenix_hawk | 24 | 1 | 41.79% | 41.93% | 0 | [Four views](phoenix_hawk_views.svg) |
| trebuchet | 21 | 1 | 50.02% | 50.50% | 0 | [Four views](trebuchet_views.svg) |
| warhammer | 23 | 1 | 52.72% | 52.97% | 0 | [Four views](warhammer_views.svg) |
| raven | 20 | 2 | 46.72% | 46.72% | 0 | [Four views](raven_two_view_views.svg) |
| urbanmech | 17 | 2 | 57.95% | 58.14% | 0 | [Four views](urbanmech_two_view_views.svg) |
| rifleman | 19 | 1 | 49.62% | 49.69% | 0 | [Four views](rifleman_views.svg) |

For Raven and UrbanMech, scores use the additional two-view registration, starting from the previously selected single-view candidate; Raven first-view landmark labels and near-side mask/pose labels were corrected. The earlier first-photo score is preserved in its original review file. All other ten models have one manually outlined catalog photo, not a multi-view reconstruction. Individual meshes use bespoke dimensions, armor/weapon assemblies and three body architecture families: ordinary biped, high weapon batteries, and specialized UrbanMech/Raven. The score is an approximate visible-component IoU, not a calibrated likeness percentage and not a comparison to production main. Some leg-pose errors are very large; low confidence scores must not be optimized as proof of fidelity. Several catalog photos show different variants (Banshee, Charger, Enforcer, Highlander) and only body/weapon envelope, not exact weapons, can be compared. Exact weapon bores, rig motion, runtime render and variant match require verification before integration. No Godot tests run. Source snapshots and four-view SVGs are experimental; never promote directly.
