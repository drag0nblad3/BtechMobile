# Earlier-model slab-body correction pass

Status: **source geometry changed; production visual approval still pending.**

## Scope

This pass updated **57 previously modeled chassis**, in both their editable coarse shape studies and detailed JSON recipes (114 files). The three standalone high-fidelity source sculpts **Atlas, Jenner, and Wolverine** were also reprofiled in their source recipes; their `_voxel.json` descriptors already generate from those sources and were not overwritten. The first-party Catapult and Hunchback example models are left intact as strong reference-faithful examples, not silently rewritten.

## Geometry, not paint

Edits change the actual horizontal cross-section polygons, with separate rules for broad assaults, Clan/avian bodies, and slimmer humanoid frames:

- Chest / waist: sharpen the transition between narrow waist, full chest, and tapered roof instead of an equally wide slab at every height.
- Shoulder: pull the outer upper armor inward while retaining the mount and arm-root support cells.
- Arms: increase outward-to-inward taper from forearm through upper arm, leaving their existing weapon barrels, fists, elbows, and pivot coordinates alone.
- Shins: reduce mid/upper calf thickness slightly without forcing human-style legs onto digitigrade frames.
- Back depth: reduce selected rear protrusions on the central chest to counter overly deep, bloated profiles.

**Important exceptions:** Keep Atlas's skull head recessed between level shoulders, preserve Jenner's forward disc and Wolverine's angular cockpit and SRM placement. The three specialized source sculpts are treated independently; Wolverine's already narrow waist is intentionally not narrowed further. The deliberately broad King Crab, Turkina-class assault carapaces are not forced into narrow human torsos. Existing muzzle positions, weapon modules, official unit IDs, leg joint hierarchy, gameplay rules, and subdivision settings are unchanged.

This is a **silhouette-level automated art correction, not final reference matching**. It cannot verify all reference-specific angles, weapon clearances during walk/fire animations, or mobile frame rates. Existing tests and pending Godot CI must still run. New art may require manual per-mech changes after real orthographic front/side/top and three-quarter comparisons.

## Validation

`tests/unit/test_vx_prior_slab_art_pass.gd` checks all modified source pairs carry the same revision tag and retain identical primary loft polygons; it also checks the three generated source sculpts. Existing voxel overlap and mechanics tests remain in force. The model shape-first source remains the authoritative editable representation; detailed files never define a separate, incompatible primary silhouette.

No APK created and no core battle rules modified.