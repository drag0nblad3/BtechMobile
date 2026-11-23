# Twenty BattleMech specialist contour refinements — batch twelve

Twenty previously untouched chassis: Hollander, Hoplite, Icarus II,
JagerMech, Katana, Kodiak, Lancelot, Legionnaire, Longbow, Mackie,
Malice, Merlin, Night Sky, Ostwar, Pack Hunter, Penetrator, Razorback,
Rook, Scarabus, and Sentry.

All were inspected at their source lofts and received targeted aft torso,
shoulder, arm and/or shin volume reductions without changing primary weapons
or cockpit source. Priority distinctive features remain: the **Kodiak's
bear-claw hands** and broad armored upper arms, **Longbow's separate twin
missile launchers**, JagerMech's twin autocannon arms, Mackie's original
heavyweight outline, and the Legionnaire/Pack Hunter's leg rig geometry.

## Two-source caveat

17 chassis have separate shape/detail recipes with matching primary lofts,
both edited. Razorback and Sentry have *one* authored source plus a detailed
source alias, so the alias intentionally remains untouched. Rook has a
separately authored, independently detailed recipe, not an alias, and the
two original tiers have nonidentical shape detail; sculpt adjustments were
made to both without replacing the detailed original with the low tier.

## Verification

`tests/unit/test_vx_reference_batch_twelve.gd` checks the 17 matched
anatomical tiers, the two aliases, Rook's separate detail, rig part inventory,
nondegenerate loft areas, Kodiak claws, Longbow launchers, digitigrade legs.
Authoritative connectivity and silhouette tests, multi-angle miniature
comparison and headless Godot CI must pass before merge. Contour adjustment
alone is **not** final miniature reference approval.

Reference images consulted: contemporary Catalyst plastic Kodiak and
Inner Sphere Fire Lance Longbow photos; JagerMech front weapon silhouette.

No APK, official loadouts, gameplay/rule changes, or dice modifications.
