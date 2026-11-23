# Imported BattleMechs — geometry batch ten (23 November 2026)

The next twenty imported source recipes from the 42-BattleMech integration
PR #242 have been refined in **both low and high detail files**:

Jenner IIC, Jinggau, Kingfisher, Locust IIC, Mad Cat Mk II, Marauder II,
Peacekeeper, Raptor, Rattlesnake, Rattlesnake II, Shadow Hawk IIC, Shiro,
Stealth, Sunder, Tempest, Templar, Thunder, Thunderbolt IIC, Tian-zong,
and Tiburon.

Selective aft torso, shoulder and arm contours were altered at the authored
geometry source. Individual amount/threshold per chassis avoids uniform
whole-model scaling. Left and right geometries are authored independently in
these models and have been modified independently while keeping their
different weapon shapes. Major arm cannons, missile racks, forward cockpit
projections, the Jenner IIC/Locust IIC/digitigrade leg rigs, muzzles, and the
original #242 physically backed joint accessory recipes were left in place.

## Remaining work

This is *source-level contour refinement*; automated parity and integrity
checks do not guarantee visual miniature likeness. The original backed
sockets may be indirectly affected by changed armor envelopes. All existing
imported-geometry strong-contact audits, Godot CI and multi-view silhouette
checks must pass before merging.

Added `tests/unit/test_vx_reference_batch_ten.gd` for twenty chassis:
tier parity, valid polygon area, eigth hit locations and gait identities.
Do not build an Android APK. No combat rules or record sheets changed.
