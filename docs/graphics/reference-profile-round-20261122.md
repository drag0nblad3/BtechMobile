# Source-led anatomy correction — 22 November 2026

This pass builds on merged PR #247's launcher and accessory fixes. **Source geometry**
was altered, not rendered sprite scale. Both low-poly and detailed recipes are edited
when both exist. No record-sheet, combat, dice, or unit-design files were changed.

| Chassis | Reference-led sculpt correction |
|---|---|
| Firestarter | Slim outer arm casings and calf depth, make the shoulder armor narrower behind the joint, retain arm flamers and backpack jets |
| BattleAxe | Remove the extraneous far-forward right shoulder slab and overlapping secondary arm cannon box, retain the high asymmetric launcher and two main arm barrels; seat the floating chest recesses against the face |
| Sagittaire | Trim aft torso mass and shoulder side armor, taper the *base* of the projecting prow, keep its long center beak, raised equipment, and separated heavy arm weapons |
| Rifleman | Shorten the rear armor of the trunk and broad gun arms while retaining paired projecting barrels and dorsal sensor hardware |
| Griffin | Narrow chest/arm rear profiles but keep the high right launcher, separated right arm cannon and left fist |
| Wolverine | Tighten the broad chest's upper lateral flare and rear bulk **in the shape study only**. The corresponding `wolverine.json` detailed file is absent on main; do not pretend it was edited |

Reference examples consulted: [Catalyst miniature catalog](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs),
[Firestarter reference](https://www.sarna.net/wiki/Firestarter_(BattleMech)),
[BattleAxe sculpt](https://www.wargamesemporium.co.uk/products/battletech-battleaxe-single-mech),
[Sagittaire miniature](https://mechpainters.org/miniature/sagittaire-davion-guards/),
and [Wolverine assembly](https://stonemonkey.com.au/products/battletech-wolverine-wvr-6r-wvr-6d-20-5197).

### Verification and limitations

A source-level correspondence check was made before commit for the CT/LT/LA
primary lofts on the five paired chassis. The new GDScript regression test
enforces tier parity, basic loader validity, all eight animated hit locations,
and the BattleAxe side-plate anti-regression. Existing full-catalog connectivity,
component support and multi-view tests still need to execute on this PR.

A perfect photo match **cannot** be inferred from loft parity or connectivity.
Reference angles, paint, and miniature sculpt vintages differ; manual
render review is needed. No Android APK built or requested.
