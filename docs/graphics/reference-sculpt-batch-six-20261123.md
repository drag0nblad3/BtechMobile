# Reference geometry — Batch 6 of 20 (23 November 2026)

### Chassis

Alfar, Apollo, Bandersnatch, Battle Hawk, Behemoth, Blade, Bombard,
Brigand, Cestus, Cossack, Cronus, Daedalus, Daikyu, Daimyo, Dart,
Dragoon, Duan Gung, Eagle, Eisenfaust, Enfield.

These twenty are the first group from the integrated 88-design sculpt
catalog added in #231; earlier twenty-chassis batches intentionally
excluded these.

### Sculpt revisions

- Individually reduced exaggerated aft armor on CT and left torso, with
  smaller reductions on the articulated left arm and lower leg. Mirrored
  right-side geometry follows the left while retaining independent
  weapon accessory parts.
- Behemoth received lighter changes to preserve assault-class bulk.
  Dart and Duan Gung received trim-focused upper-body corrections.
- The Battle Hawk, Cossack, Duan Gung and Eagle retained digitigrade
  articulation and long forward cockpit or launcher features.
- All twenty high-detail JSON recipes use an authored source link.
  The linked `_shape` geometry was adjusted in place. No duplicate
  high-detail mesh file was created.
- No change to game rules, design record sheets, attack muzzles, weapon
  housings or damage logic.

### Validation and required remaining work

`tests/unit/test_vx_reference_batch_six.gd` checks source alias
integrity, real loft polygon area, eight standard hit-location parts
and preserved reverse-jointed gait signatures.

The existing Godot CI, voxel catalog connectivity and silhouette
workflows are required. **Not a final visual approval:** each design
still needs front, side and 3/4 rendered comparison against modern
Catalyst miniatures to inspect weapons, proportions, floating masses
and component-specific geometry.

References:
- [Catalyst miniature collection](https://store.catalystgamelabs.com/collections/miniatures)
- [Catalyst miniature catalog overview](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
