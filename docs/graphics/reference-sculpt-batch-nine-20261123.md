# Reference geometry batch nine — imported chassis (23 November 2026)

Twenty newly integrated source sculpts were selected from the 42 units in
merged #242, specifically avoiding the 160 chassis in earlier batches.

Arctic Wolf, Avatar, Bane, Battle Cobra, Black Lanner, Cerberus, Champion,
Cougar, Dragon Fire, Ebon Jaguar, Galahad, Gladiator, Glass Spider,
Grand Dragon, Griffin IIC, Gunsmith, Hermes, Highlander IIC, Huntsman
and Jackalope.

Source-level geometric adjustments modify the CT, left/right torsos and both
arms independently in each **low-resolution and detailed** source model.
Imported designs frequently author both right and left assemblies explicitly,
unlike older mirrored models. Sides were therefore corrected explicitly.
Individual thresholds, tapers and shoulder-outboard factors depend on chassis
rather than a global mesh-wide scale. Key muzzle, cockpit, dedicated racks and
joint/socket accessory recipes were retained without changing the authored
rig, hit locations, weapon list, or official unit data.

## Review limits and follow-up

This is a shape contour correction of primarily rear and outer geometry;
it is **not** yet a Catalyst plastic-miniature multi-angle likeness approval.
The #242 solid-backed joint sockets were not intentionally modified, but
changes to loft volume can alter their contact patch. Run the existing
imported joint backing tests and voxel connectivity/silhouette CI; fix any
regression before merging. Further front/side render-by-reference sculpting
remains necessary.

New regression tests: `tests/unit/test_vx_reference_batch_nine.gd`.
No changes to gameplay rules, RNG, record sheets or Android export.
