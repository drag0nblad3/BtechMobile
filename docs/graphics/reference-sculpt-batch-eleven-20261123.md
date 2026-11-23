# Twenty additional BattleMech sculpt corrections — batch eleven

This third batch after the eight merged sculpt cohorts, and the eleventh
20-model cohort overall, covers: **Atlas, Jenner, Akuma, Albatross, Argus,
Caesar, Chimera, Crockett, Devastator, Emperor, Excalibur, Falconer, Firebee,
Flea, Grizzly, Gunslinger, Havoc, Hel, Helios, and Hellspawn**.

## Dedicated silhouette corrections

### Atlas (shape source only)
- Chassis primary rear hull depth and two massive rear shoulder shell
  envelopes were reduced independently.
- The skull head remains recessed below the high rounded shoulders.
- New compact solid palm and knuckle volumes are part of the source
  left arm, mirrored to the right, instead of a second floating arm.
- Weapon racks, open missile mouths, muzzle coordinates and rig unchanged.

### Jenner (shape source only)
- Forward projecting disc head **already existed**; it was inspected against
  contemporary plastic miniature references instead of adding another
  generic dome. The mid-disc rim was shaped slightly broader while the
  deep aft torso was shortened.
- Added a broad internal neck strut from its head rear toward torso
  front for physically backed attachment; must pass a voxel face-contact test.
- Preserve paired arm lasers, central missile pod and reverse-jointed leg rig.

Both Atlas and Jenner lack separate authored detailed JSONs in this catalog,
so these edits are made in `*_shape.json` only.

### Other eighteen chassis

Each receives a chassis-specific change to rear torso/shoulder/forearm or
occasional shin envelope, using matched edits in both separately authored
resolution tiers. Flea is tightened more strongly while retaining its long
forward cockpit; Gunslinger/Devastator retain major weapon casings. No general
blind whole-model scale factors or gameplay data edits.

## Review and CI

The added `tests/unit/test_vx_reference_batch_eleven.gd` checks sculpt
tier parity, all animated locations, the Jenner broad backed head join and
both Atlas arms. The full game CI, multi-angle connectivity and physically
backed accessory audits must pass before merge. Passing geometry tests is
**not** final human approval against plastic miniatures or evidence that all
small floating components have been removed.

References consulted:
- [Catalyst plastic miniature catalog](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
- [Jenner contemporary Catalyst plastic figure gallery](https://www.rpgminihunter.com.au/products/jenner-battletech-inner-sphere-striker-lance-set-catalyst-game-lab)
- [Atlas miniature range and identification](https://miniset.net/sets/cgl-35725-atls)

No Android APK, core combat rules, official design JSON, or dice modified.
