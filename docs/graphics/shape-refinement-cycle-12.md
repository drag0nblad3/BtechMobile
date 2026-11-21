# Shape cleanup passes 198–205 — intentional layer ownership

**Baseline:** feature/shape-reference-refinement-20261120, pass 197. The authoring stage remains **subdivide = 1**, so the goal is better shape clarity rather than higher voxel count. Nothing here changes damage rules, gait logic or the other higher-resolution voxel lab. No APK build or unsolicited render.

## Method

Audit voxel occupancy of authored `box`, `loft`, `erase` operations and mirrored parts, looking at shared cells between distinct pieces. Overlap alone is not an error: a collar nested into a shoulder, structural keel inside armor, or head recessed into chest is intentional. The problem cases are **independent full-size parts with nearly identical footprints** and separate meshes painting coincident faces. Keep connected silhouettes, preserve weapon mouths, and keep the one-hand/one-gun arm construction.

## Passes

| Pass | Chassis | Model correction |
| --- | --- | --- |
| 198 | Atlas | Replace buried rounded shoulder band with slimmer, raised crest near the sunk head's height |
| 199 | Atlas | Reprofile buried round shoulder underplate into a narrow exterior apron, retain skull/chest structural layering |
| 200 | Wolverine | Reduce forward elbow/forearm's overlapping full-section mass while keeping **exactly two z-section shapes** in right arm |
| 201 | Wolverine | Slim AC5 mount into one connected diagonal structural spar from shoulder to barrel; hand still grips this weapon |
| 202 | Wolverine | Conform wrist collar, right hand, and elbow plating to the same chain; narrow largely hidden faceted waist insert |
| 203 | Jenner | Replace thick solid secondary saucer with two slim lateral rim arcs, retaining 20-unit-wide primary disc |
| 204 | Jenner | Resculpt lower fairing and underlip as shallow lower edge rather than a second thick lower disc |
| 205 | Jenner | Remove wholly duplicated glazing strip, convert other window overlays into narrow upper/lower trim around the main windshield |

## Intersection audit

Source-grid diagnostic counts (independent part cells that occupy the same grid positions), measured before and after:

| Pair | Before | After |
| --- | ---: | ---: |
| Atlas torso shoulder / underplate (left) | 469 | 339 |
| Wolverine right arm / cannon mount | 570 | 298 |
| Wolverine cannon mount / gripping hand | 285 | 196 |
| Wolverine abdomen / interior waist spine | 505 | 248 |
| Jenner head / secondary disc rim | 976 | 166 |
| Jenner head / lower disc fairing | 503 | 286 |
| Jenner old duplicate glass / canopy piece | 321 | 0 (duplicate removed) |
| Jenner head / lower underlip | 330 | 111 |

Some positive overlap remains on purpose for physical contact and damage. The Atlas shoulder band gained actual exposed voxels above the main shell rather than simply hiding inside it; buried cells were not categorically deleted.

**Approximate source occupancy:** Atlas 22,601 → 22,657, Wolverine 22,054 → 20,861, Jenner 24,630 → 22,530; these are shape-grid counts, **not** a high-density voxel target. Wolverine's hand still intersects both the gun and the diagonal mount, both original cannon bridge landmarks remain, Jenner's forward nose remains at (0, 26, -36), Atlas AC20 bore remains clear. New `test_voxel_layer_ownership.gd` encodes guardrails without requiring every intentional connector to become non-overlapping.

## Validation and next review

Geometry source was checked for section order, consistent polygon vertex counts, unique names, valid parent/mirror references, physical weapon/hand connection and the named silhouette landmarks. An independent authored-grid overlap audit was run and measured as above. **Godot runtime test and five-view render have not been run** in this environment. Review these from front, left, right, 3/4 and top-down before considering the silhouette approved.
