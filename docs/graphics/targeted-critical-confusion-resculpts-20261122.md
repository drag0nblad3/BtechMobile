# Critical silhouette-confusion chassis: targeted source resculpts

**22 November 2026 — identity-resculpt draft.** Scope: 31 chassis classified **critical** by `docs/graphics/critical-identity-confusion-after.json`, in both low-resolution `*_shape.json` authoring models and their matching detailed `.json` versions (62 recipes). This changes physical source loft-section polygons, not merely surface paint, decoration or the similarity report.

## Chassis-specific identity work

| Confusion group | Geometric change and intended signature |
| --- | --- |
| Chameleon / Lancelot | Different helmet projections, shoulder-width rise, arm mass and leg taper; preserve weapons |
| Icarus II / Sentinel / Starslayer | Icarus higher broad shoulder yoke; Sentinel narrow beaked center and lighter lower legs; Starslayer squared yoke |
| Guillotine / Thanatos | Different brow, shoulder and asymmetric arm envelopes; maintain authentic weapon architecture |
| Ostwar / Shogun | Slender Ost-series center/limbs versus Shogun's bulkier missile-bearing shoulders and paired ports |
| Crockett / Katana / Spartan | Crockett and its Katana derivative **remain intentionally related**; Spartan gets a different long armored brow and shoulder profile |
| Goliath / Tarantula / Scorpion | Heavy Goliath four-leg carapace vs Tarantula's light pointed spider hull vs Scorpion's long wedge; all preserve four articulated legs |
| Thug / Zeus | Bilateral heavy Thug profile vs taller asymmetric Zeus armor/missile pattern |
| Awesome / BattleMaster | Different shoulder PPC mass, center chest and officer-profile head heights |
| BattleAxe / Ymir / Kintaro / Flashman | Reduce inflated side plating; distinguish elevated asymmetric Ymir shoulder missile, Kintaro brawler mass and Flashman smooth laser chassis |
| Grasshopper / Quickdraw / Orion / Valkyrie | Tall light Grasshopper legs; compact fast Quickdraw; broader Orion weapon torso; much narrower Valkyrie frame |
| Gunslinger / Penetrator / Sagittaire | Deliberately different sniper shoulder gun architecture, narrow forward Penetrator yoke and Sagittaire armor envelope |
| Stormcrow | Low pointed body and lean reverse-jointed legs; separate from bulky upright assault forms |

## Source and quality requirements

Every edited model records `reference_identity_resculpt` with its confusion neighbor, specific anatomy goal, reference page and actual number of contour vertices modified. Reference lookup starts with the individual [Sarna BattleMech encyclopedia](https://www.sarna.net/wiki/BattleMech), [Catalyst miniature index](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs), and the [official tabletop site](https://battletech.com/tabletop/). Favor recent Catalyst plastic sculpt shapes where available and use front / side / quarter / top / rear sources before accepting each likeness. These are **interpretive source-level anatomy changes**, not a claim of photographic or miniature approval.

The pre-change audit reported 31 critical and 97 high-risk nearest-neighbor chassis (out of the 151 measured) and the highest pair at 0.9825 for genuinely related Crockett/Katana. These numbers are **not post-edit measurements** and represent normalized silhouette similarity, **not recognition percentages**. The additional high-risk cohort is not automatically part of this critical 31-model PR.

## What the geometry pass does and does not validate

Primary loft polygons differ on each independently authored chassis. Materials, component ownership, official visual weapon manifests, muzzle origins, jump jets, rig pivots, parent chains, moving-part list, mirror definitions, hit locations and gait settings were preserved. Source-tier parity and polygon area were inspected during edits. A data-driven Godot regression test checks the 31 paired recipes, polygon structure and spot-loading across hit locations.

**Still required before merging:** run the full Godot 4.5 test suite and voxel showcase/smoke; run all-chassis multi-angle connectivity/solid-backed socket/zero-island audit **after** final rasterization, not merely bounding-box contact; check all weapon bores and mirrored guns for obstruction; render blind front, side, three-quarter, top and rear comparisons against current Catalyst miniature reference angles; recompute nearest-neighbor rank; reject work that fails visual likeness even when a numeric score improves. Other active art PRs (#264, #265, #266) overlap specific chassis; reconcile their newer source contours instead of overwriting them.

No official unit records, core combat rules, damage outcomes, game RNG, or Android APK changed. This PR is **draft** until the checks above are satisfied.
