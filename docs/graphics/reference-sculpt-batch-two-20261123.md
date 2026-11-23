# Reference silhouette adjustments — second set of twenty (23 November 2026)

Source-level follow-up to [batch one](reference-sculpt-batch-one-20261122.md).
This batch uses twenty **previously untouched by these two batches** BattleMechs,
each reviewed for body-plan-specific geometry and adjusted in its authored
loft polygons. Most have low and high detail geometry files, but the **Hussar**
high-res JSON is an alias to its authored `hussar_shape.json` and was deliberately
left as an alias instead of accidentally replacing it.

## Edited source geometry

| Model | Sculpt intent and unique elements intentionally retained |
| --- | --- |
| Assassin | Aft CT, shoulder and arm mass; retain long spear-like head |
| Blackjack | CT and shoulder overhang; keep twin forward arm cannons |
| Bushwacker | Deep aft chassis and shoulder plates; preserve very long forward snout |
| Charger | Taper overdeep shoulder and fist casings but keep stocky assault silhouette |
| Cicada | Reduce rear engine pod slab and outer shoulder/leg flare; keep long insect nose and reverse legs |
| Clint | Avoid bulky suit appearance on shoulders and arms, retain thin AC |
| Crusader | Sharper aft shoulders and arms; preserve missile formations and launcher mouths |
| Dervish | Shoulder shell and forearm aft thickness; preserve paired missile-rack outline |
| Grasshopper | Slim rear torso and arms, preserving jump-capable midweight frame |
| Kintaro | Trim dorsal armor without trimming forward weapon packs |
| Ostsol | Reduce overlarge rear/limb thickness, retain long cockpit and narrow arms |
| Ostroc | Separate head/torso mass from bulky rear armor, preserve compact energy weapons |
| Cyclops | Preserve command head and independent weapons, reduce generic slab volume |
| Hatamoto-Chi | Retain narrow samurai head and high shoulders, lightly adjust back and arms |
| Mauler | Soften solid rear slab while preserving heavy quad-gun identity |
| Raven | Aft engine/hip mass only, preserve extreme beak and reverse joints |
| Cataphract | Subtle rear CT/shoulder/arm correction without eliminating lopsided cockpit |
| Spider | Leaner rear silhouette, no shift to thin head and long limb pivots |
| Whitworth | Sharper shoulder/torso silhouette, launcher faces unchanged |
| Hussar | Narrow aft engine silhouette; **preserve center laser, long head, complex digitigrade leg rig** |

## Test and approval state

Added `tests/unit/test_vx_reference_batch_two.gd` for source parity,
nondegenerate sculpt sections, all rig parts and distinct gait/weapon items.
Existing CI owns the headless Godot, game smoke, voxel integrity, connectivity
and silhouette checks. **This does not certify art-reference likeness**;
the next required stage is front/side/three-quarter renders against specific
modern plastic Catalyst miniatures, with more extensive resculpt if necessary.

Reference sources for this batch:
- [Catalyst miniature catalog and forcepack list](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
- [Somerset Strikers ForcePack (Mauler, Hatamoto-Chi, Bushwacker)](https://www.sarna.net/wiki/BattleTech:_Somerset_Strikers_ForcePack)
- [Catalyst current miniature range](https://store.catalystgamelabs.com/collections/miniatures)

No design sheets, game rules, or APK build changed.
