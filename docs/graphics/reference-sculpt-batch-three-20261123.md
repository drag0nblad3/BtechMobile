# Reference sculpting: twenty-chassis third batch (23 November 2026)

This branch modifies twenty more previously untreated chassis:
Axman, Wolfhound, Hermes II, Sentinel, Panther, Wasp, Stinger, Firefly,
Mercury, Mongoose, Vulcan, Hatchetman, Wraith, Watchman, Crab,
Exterminator, Zeus, Victor, Flashman and Guillotine.

### Model-specific geometry priorities

The Wasp, Stinger, Mercury, Mongoose and Wolfhound have prominent slab-like
rear armor and front shoulder width relative to their light frames. Their
aft torso shells and some outer shoulder contours were tapered. The Panther
retains its asymmetric right PPC casing. The Axman and Hatchetman retain
their separate right-hand melee tools and the lower-arm/shoulder attachments,
while their main armored bodies were refined. The Crab keeps independently
articulated claw arm assemblies. The Victor keeps its forward right-arm
cannon and the Flashman's oversized rear torso is reduced more aggressively
than other assault chassis. The other entries receive individual loft and
limb-shape corrections rather than identical all-over scaling.

Changes exist in the authored `_shape.json` and `.json` source when both
are independent. `wraith.json` and `watchman.json` source their `_shape`
recipes and inherit the update without rewriting alias files.

This is **not** a full visual approval. A source-limited geometry pass cannot
prove likeness. Perform multi-angle renders and verify weapon placement,
contact patches and scale under CI and visual review before final signoff.

Regression suite: `tests/unit/test_vx_reference_batch_three.gd`
checks paired sculpt lofts, cross-section nondegeneracy, all core hit
locations, and preserved axe / arm PPC / claw components.

Reference sources:
- [Catalyst plastic miniatures catalog](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
- [Catalyst miniature store](https://store.catalystgamelabs.com/collections/miniatures)

No combat rules, unit construction JSON, or APK builds touched.
