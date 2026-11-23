# Fifth batch — twenty more BattleMech silhouette sources (23 November 2026)

Refined the next twenty as distinct authored 3D source profiles:
Adder, Kit Fox, Fire Moth, Ice Ferret, Stormcrow, Shadow Cat, Gargoyle,
Warhawk, Crossbow, Mad Dog, Viper, Mist Lynx, Grendel, Piranha, Night Gyr,
Linebacker, Hunchback IIC, Supernova, Howler, Ostscout.

**40 JSON files**: each model has separately authored low/high geometry.
The same primary loft edits were committed to both tiers, leaving
weapons, muzzle positions, part parenting and gameplay sheets unchanged.

## Reference/geometry priorities

- The light Clan scouts (Adder, Kit Fox, Fire Moth, Ice Ferret, Viper, Mist
  Lynx, Grendel, Piranha, Howler) need distinct, trim hull envelopes; light
  armor does not justify a big generic rear slab.
- Stormcrow and Shadow Cat retain their prominent narrow/snouted cockpit
  shapes and reverse-jointed stride.
- Gargoyle and Warhawk retain large characteristic weapon shoulders; cut
  aft mass selectively rather than shrinking everything.
- Crossbow and Mad Dog preserve their paired launcher housings, frontal
  missile ports and relatively minimal forward arm extensions.
- Night Gyr and Linebacker have distinct gait/torso profiles despite
  similar heavy tonnages. Both keep their established per-chassis rig.
- The Hunchback IIC retains its signature heavy dual cannon supports.
- Supernova's wide energy gun stance remains broad, Ostscout's much lighter
  chassis receives relatively stronger rear-envelope corrections.

## Validation / next art step

`tests/unit/test_vx_reference_batch_five.gd` checks all 20 model
recipes and high-vs-low contour parity, noncollapsed loft polygons, all
eight hit locations and correct reverse-jointed rig subparts.

The art is **not signed off on miniature likeness** without front/side/
three-quarter render review against Catalyst plastic references. A
silhouette regression workflow cannot by itself prove correct weapon
length, armor panel detail, relative scale, or absence of coincident parts.

References:
- [Official Clan ForcePack catalog](https://store.catalystgamelabs.com/products/battletech-forcepack-clan)
- [BattleTech miniatures documented by Catalyst series](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)

No Android builds, unit sheets or rules edits.
