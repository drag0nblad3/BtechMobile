# Reference geometry — Batch 7 of 20 (23 November 2026)

Twenty additional imported BattleMech sources have been individually
refined without overlapping batches one through six:

Enforcer III, Eris, Exhumer, Falcon Hawk, Falcon, Fireball, Flashfire,
Gallowglas, Garm, Gravedigger, Grim Reaper, Ha Otoko, Hammerhands,
Hatamoto-Hi, Hatamoto-Kaze, Hatamoto-Ku, Hatamoto-Mizo,
Hercules, Hermes III, Hermit Crab.

## Model-specific handling

Source lofts were adjusted selectively for aft armor mass, shoulder depth,
arm shell depth, and rear-facing shin thickness. Each chassis uses its own
section thresholds; notably the lightweight Fireball and Falcon need
different profiles from the heavy Gallowglas and Hatamoto variants.
No authored distinct weapon housing, muzzle or parent rig was deleted.

The Garm and Hermit Crab left torso shells are box-and-shell recipes,
not primary lofts. Their shoulder armor and weapons were **not**
overwritten or forcibly converted to a generic torso loft. The Falcon
and Hermit Crab retain digitigrade articulation.

The Hatamoto-Hi/Kaze/Ku/Mizo designs are distinct independently
authored source recipes, not cosmetic skins; no rig or weapon
configurations were merged between them.

All detailed recipes that are source aliases remain source aliases;
the original low-level sculpt was edited rather than a runtime scale.

## Tests, limits and follow-up

`tests/unit/test_vx_reference_batch_seven.gd` checks all twenty
recipe files, nonzero polygon areas, source provenance, eight hit
locations and the special shell/leg rigs. Existing Godot CI and voxel
connectivity/silhouette workflows should also pass.

This is source-level geometric refinement, **not final visual likeness**.
Review front, profile and three-quarter renders with multiple Catalyst
miniature pictures before final signoff. No design record sheets,
core rules or Android APK were changed.

[Current plastic miniatures](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
