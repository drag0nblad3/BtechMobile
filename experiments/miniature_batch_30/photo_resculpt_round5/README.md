# Six photo-inspected reconstruction candidates

Ten individual photos were retrieved and visually inspected for six chassis. The approximate hand-traced visible regions, landmark observations and source URLs are in annotations.json. For Grasshopper and Zeus this pass evaluates the already present round4/rebuild.js source; other rebuilds are authored in this folder. Two major candidates per chassis were compared with fixed camera and fitted pose; for cases that regressed, individual assembly groups were tested, followed by a further mount reconstruction for Longbow and Wolfhound. No original controls modified.

| Chassis | Selection | Mean region IoU by view (control → selected) | Source cells changed | Sampled channels |
|---|---|---|---:|---:|
| grasshopper | partial | 41.59 → 43.05%; 27.97 → 29.16% | 890 | 1/1 |
| wolfhound | major | 37.25 → 38.92%; 25.96 → 26.85% | 1664 | 4/4 |
| longbow | major | 44.04 → 54.46%; 8.86 → 9.02% | 9926 | 50/50 |
| nightstar | partial | 44.13 → 45.55%; 50.89 → 51.42% | 2560 | 4/4 |
| zeus | major | 34.83 → 39.21% | 3742 | 7/7 |
| crusader | partial | 49.56 → 51.51% | 574 | 30/30 |

The selected major Longbow replaces low forearm missile boxes with large round shoulder-height pods and raises the small head. Wolfhound has a projecting head with paired fins, narrowed torso and rebuilt waist weapon mounts. Zeus has broad cylindrical shoulders, shaped forward head armor and a rounded six-port housing. Grasshopper accepts forearm and leg armor, Nightstar weapon clusters, Crusader circular missile housings. Crusader uses the Kell Hounds variant reference, not guaranteed identical to the base plastic sculpt. Zeus and Crusader have only one scored photo. Longbow side-view fit is poor (pose landmark error up to 76 px); its frontal score is informative but side score is not reliable. Several other poses have large residuals. Scores are coarse mean component-mask IoU, not percentage fidelity; not a proof of exact weapon configuration or variant. All selections pass neutral structural checks and sampled three-cell channel checks, which do not guarantee full-depth bores. No Godot validation or production changes. See final_before_after.svg for 36 actual source projections. Unselected candidates remain in trial and selection JSON files. Prior photo claims and masks outside this folder were not independently reverified in this pass.