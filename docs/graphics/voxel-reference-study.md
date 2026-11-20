# Reference-guided voxel silhouette standards

All links are viewing references, not copied texture/image assets. This study
preceded **VoxelSilhouetteV3**. Sources include the BattleTech technical-art
collections maintained by Sarna, and the Master Unit List. They show strongly
different mass distributions; adding random recesses to shared cubes is not
enough.

## Chassis references and hard shape distinctions

| Chassis | Reference art | Key shape requirement | Avoid |
| --- | --- | --- | --- |
| Atlas AS7-D | [Sarna Atlas](https://www.sarna.net/wiki/Atlas), [Master Unit List](https://masterunitlist.battletech.com/units/atlas-as7-d) | Small recessed *death's-head* between very broad armor shoulders; deep V-taper chest; projecting round fists, true AC/20 and separate LRM/SRM ports; massive knee/boot armor | Tall isolated skull, a horizontal bar with two giant matching cannon fists, tiny legs |
| Hunchback HBK-4G | [Sarna Hunchback](https://www.sarna.net/wiki/Hunchback) | One dominant **squared right-torso cannon tower** with huge recessed AC muzzle and side grilles; little offset head; short conventional arms and stocky legs | Symmetric rounded shoulders, two equal arm guns, round domed cannon hump |
| Wolverine WVR-6R | [Sarna WVR-6R drawing](https://www.sarna.net/wiki/File:Wolverine_WVR-6R_FSW.jpg) | Upright small glass-front head, raised six-cell SRM launcher alongside it, separate barrel-shaped arm autocannon, broad segmented chest narrowing toward pelvis, longer conventional limbs | Atlas skull, big equal shoulder globes, hidden missile ports |
| Jenner JR7-D | [Sarna Jenner](https://www.sarna.net/wiki/Jenner) | **Forward swept aircraft nose** extending beyond body; compact side laser nacelles; back engine deck; tall exposed digitigrade knees/hocks; three separated toes | Human head, conventional dangling forearms, short boot legs |
| Catapult CPLT-C1 | [Catapult technical view](https://www.sarna.net/wiki/Catapult), [Shimmering-Sword illustrated view](https://www.deviantart.com/shimmering-sword/art/Battletech-Catapult-786522819) | Small angular aircraft-like cockpit *between* tall independently armored dual LRM-15 racks; narrow hull, exposed reverse-knee springs and long three-toe feet, no conventional hands | Square cyan face spanning entire torso, short humanoid legs, rectangles with painted missile circles |
| Test mech | Distinct experimental demonstrator, no canonical BattleTech reference | Twin diagnostic optics, exposed sensor mast, **asymmetric** test cannon vs claw, independent reactor bays | Another anonymous Atlas silhouette |

## Visible art acceptance gates

1. At a small render (roughly 250 px tall), all five actual chassis must be
   distinguishable by **silhouette alone** with flat material colors.
2. Head, torso weapon, limb and hip attachments must visually connect; do not
   place a separately floating helmet or disembodied gun over a black void.
3. Each physical tube must be **open** (no colored square at its outer surface)
   with a setback dark chamber. Test occupancy at the aperture and behind it.
4. Mechanisms and armor should be proportionate to their specific chassis.
   Hunchback's AC/20 must visually dominate; Catapult missile boxes dominate
   its shoulders; Jenner nose and legs dominate its profile.
5. Front and 3/4 camera captures plus a side profile per chassis, in **Godot**,
   are required before claiming visual acceptance.
6. Target **100,001–150,000 actual damageable occupied voxels** each, but don't
   add cuboid filler or lower-detail art merely to meet a number. If one sculpt
   needs more, justify it explicitly; remaining runtime stress tests are not
   performance approval.
7. For face/panel geometry, prefer tapered prisms, faceted lofts, removable
   armor and separately open joints rather than sphere/box/ellipsoid repetition.
8. Tests must enforce landmark *presence and negative-space absence*, and any
   20-/60-mech stress suite must continue to auto-select the densest model.

## Integration boundary

`VoxelSilhouetteV3` works in the 75mm coarse authoring grid before the
chosen 37.5/25mm refinement. The official BattleTech combat results continue
to originate exclusively from `src/core/` and the record sheet, never from
destruction of these geometry voxels. Both Claude and ChatGPT may cross-edit
the same source models in isolated branches and compare their Godot renders.
No APK export unless the user explicitly requests it.
