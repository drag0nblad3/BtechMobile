# Reference-focused resculpt and part-by-part connectivity — eight priority chassis

**Scope:** Raven, Shadow Cat, Flea, JagerMech, King Crab, Rifleman, Hunchback IIC, and Locust. Three nontrivial macro-cycles per chassis (primary volume and head/body proportion; loadout-specific weapons and silhouette detail; part-by-part connectivity, collision removal, and hinge/contact repairs). This is the first intentionally hand-targeted reference-resculpt batch following two automated fifty-pass contour rounds.

**Reference selection:** Give highest priority to recent Catalyst Game Labs plastic miniatures and production sculpt photographs. The [Catalyst miniature index](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs) identifies relevant force packs. Reference examples used in this pass include the [Shadow Cat Clan Command Star miniature](https://www.rpgminihunter.com.au/products/shadow-cat-battletech-clan-command-star-catalyst-game-lab), [King Crab ComStar Command miniature](https://www.rpgminihunter.com.au/products/king-crab-battletech-comstar-command-lvl-ii-set-catalyst-game-lab), and [Hunchback IIC plastic miniature](https://www.wargamesemporium.co.uk/products/battletech-hunchback-iic-single-mech). A [Raven Urban Lance](https://www.sarna.net/wiki/BattleTech:_Inner_Sphere_Urban_Lance) reference guided the avian hull. Side/rear views are supplemented by source miniatures and the in-game weapon layout; the models have *not* yet received final per-angle artist sign-off.

## Distinctive resculpt changes

| Chassis | Main silhouette change | Weapons / recognition | Specific structural safeguard |
|---|---|---|---|
| Raven | Longer, narrower avian nose, widened rear equipment body and slender lower legs | Rear EW sensor mast; NARC pod differentiated from twin laser barrels | Clip right shoulder-to-arm overlap; retain all hip/knee/hock parent contacts |
| Shadow Cat | Broader vented upper core and narrow forward pod with distinctly lean arms | Large **right** Gauss barrel and left dual medium-laser ports | Carve torso/shoulder colliding cells; ensure weapon and radiator mounts remain attached |
| Flea | Smaller, narrower body, lightweight arms, thin lower legs and short cockpit | Tiny gun and compact exhaust/engine, not a swollen torso | Reconnect head and left shoulder fragments |
| JagerMech | Narrower center torso, reduced forearm housings, longer side-facing weapon profile | Twin separate AC barrels on each arm rather than slabs | Verify long barrels are joined to the arm within each part |
| King Crab | Broad, flatter carapace above slimmer legs, with stronger lateral pincer mass | Two distinct talons at the front of each claw | Carve shared CT/shoulder/arm cells and repair/reject stray carapace islands |
| Rifleman | Slimmer upright cockpit and torso with gun arms distinct from the main chassis | Paired independently drilled long cannon tubes on both sides | Retain independent weapon bores and arm/shoulder contacts |
| Hunchback IIC | Narrow core and squat central cockpit below widened upper shoulders | Twin large shoulder weapon housings and their mounting braces | Trim penetrating torso/shoulder/arm cells without severing attachments |
| Locust | Tiny ovoid torso with narrow reverse-jointed limbs and elongated nose | Front-mounted light gun barrel and aft engine assembly | One explicit right-shoulder-to-CT joint bridge; remove old disconnected engine geometry |

## Validation methodology

The offline authoring script `reference_resculpt_cycles.py` (included in the downloadable audit bundle) projects each source shape onto the **same integer coarse voxel grid** used by `VxModel._paint` (including loft interpolation, boxes, erase masks, mirrored parts, and ordered additive detail). For every resulting part it performs a six-neighbor flood fill and requires one connected island. It separately verifies the named parent part shares a cell **or face adjacency**, and checks all owned cells across parts are disjoint. It trims collisions from parent armor rather than hiding parts inside each other, then reruns the same checks until stable. Changes are mirrored into coarse and detailed model manifests without altering location assignments, pivots, or baseline muzzle target coordinates.

A separate Godot regression test (`tests/unit/test_vx_reference_resculpt_connectivity.gd`) loads **both** LOD recipes at coarse grid resolution and independently verifies every part's connectivity, parent contact, and exclusive voxel ownership. That Godot test is authoritative; local Python checks alone do not prove final 3× voxelization or game animation correctness.

## Local offline results

| Model | Part count | Before coarse cells | After coarse cells | Final disconnected parts | Final overlapping cells | Final missing parent contacts |
|---|---:|---:|---:|---:|---:|---:|
| Raven | 14 | 5,158 | 5,320 | 0 | 0 | 0 |
| Shadow Cat | 14 | 5,304 | 5,796 | 0 | 0 | 0 |
| Flea | 14 | 5,005 | 3,997 | 0 | 0 | 0 |
| Jagermech | 12 | 5,288 | 4,808 | 0 | 0 | 0 |
| King Crab | 12 | 8,973 | 9,765 | 0 | 0 | 0 |
| Rifleman | 12 | 6,603 | 5,964 | 0 | 0 | 0 |
| Hunchback Iic | 12 | 7,522 | 7,206 | 0 | 0 | 0 |
| Locust | 12 | 6,469 | 5,639 | 0 | 0 | 0 |

**Limitations:** All local *coarse* grid checks above pass. This does not imply the entire mech catalog is now fixed; earlier merged work had extensive Godot test failures, and newly resculpted models require engine-level tests, firing-angle checks, multi-angle mini/photo comparison, rig animation review, and final art approval. No APK requested or built. Review branch remains unmerged.
