# Full reconstruction pass — progress checkpoint

This extends the earlier 30-model regional contour batch; the remaining regional trials are not counted as full reconstructions. Main is unchanged.

| Chassis | Independently rebuilt parts | Registered photo views | Part-mask IoU proxy (v1 → candidate) | Selected |
|---|---:|---:|---|---|
| Blackjack | 21 | 5 | .58759 → .58915 | v2 |
| Locust | 20 | 4 | .38218 → .38203 | v1 |
| Catapult | 25 | 4 | .63364 → .63406 | refined |
| Awesome | 24 | 3 | .56930 → .56936 | refined |
| BattleMaster | 28 | 3 | .61857 → .61815 | v1 |
| Archer | 26 | 3 | .47218 → .47349 | v2 |
| Atlas | 25 | 2 | .60452 → .60508 | repaired v1 (candidate overlaps) |
| Adder | 23 | 3 | .57951 → .58038 | v2 |

Every selected assembly passes the independent source-cell check for connected parts, exclusive occupied cells, and backed parent interfaces. This checks neutral source geometry, not in-engine behavior. Source and review JSON plus four-view SVGs are in this directory. The score is a manually marked, approximate visible-part overlap diagnostic, not a photogrammetric reconstruction or a comparison to main. Camera and stance residuals are recorded per view; several remain large. Variant matching is important; Blackjack uses the base-58 BJ-1 rather than the BJ-2 casting. No production promotion or Godot validation has occurred. Weapon apertures and gameplay muzzle bindings require additional checking.

Remaining full rebuilds: Banshee, Centurion, Charger, Crab, Cyclops, Dragon, Enforcer, Firestarter, Griffin, Hatchetman, Highlander, Hunchback, JagerMech, Marauder, Panther, Phoenix Hawk, Shadow Hawk, Stalker, Thunderbolt, Trebuchet, Warhammer, Wolverine.
