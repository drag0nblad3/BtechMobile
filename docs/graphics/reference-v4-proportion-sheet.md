# Reference V4: clean-slate model blockouts

## Intent

**Discard the previous common model, not refine it.** The V2/V3 geometry is
no longer used to generate any of these six chassis. The new source is
`src/view/units/voxel_reference_v4.gd`; `VoxelMechArt` and
`VoxelMechRig` now call it directly. The old builders remain in the
repository for historical comparisons only.

All source links are art references, not imported game assets. Models are
original voxel approximations based on landmarks, not distributed copies of
reference meshes. Classic TRO art and a current CGL miniature / official
technical art are the paired views for each production BattleMech. Because
illustrations vary between eras, the classic silhouette takes precedence
over surface panel layout when they disagree.

## Multi-reference visual specifications

| Chassis | Classic/technical reference | Second visual reference | Geometry landmarks |
| --- | --- | --- | --- |
| Atlas AS7-D | [Original AS7-D TRO:3025 (Sarna)](https://www.sarna.net/wiki/Atlas) | [Catalyst AS7-D miniature and newer CGL variants](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs) | Small integrated skull; big but separate square pauldrons; wide chest taper to narrow waist; independent long armored limbs; torso AC/20, recessed launcher, visible hands |
| Hunchback HBK-4G | [TRO:3025 Hunchback (Sarna)](https://www.sarna.net/wiki/Hunchback) | [CGL Hunchback miniature index](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs) | Dominating squared *right torso* gun tower above small off-center head; asymmetrical shoulder line; comparatively small arms; separated long shins |
| Wolverine WVR-6R | [WVR-6R technical illustration](https://www.sarna.net/wiki/File:Wolverine_WVR-6R_FSW.jpg) | [Wolverine game miniature art](https://www.sarna.net/wiki/Wolverine) | Slim conventional humanoid body; upright angular sensor head; left six-port missile cassette; right arm AC/5 and left manipulator; longer legs than chest |
| Jenner JR7-D | [TRO:3025 classic Jenner](https://www.sarna.net/wiki/Jenner) | [CGL JR7-D technical card](https://masterunitlist.battletech.com/units/jenner-jr7-d) | Low aircraft-like wedge cockpit protruding well ahead; four SRMs high on dorsal fuselage; four medium lasers in two side-mounted twin units; reverse-jointed narrow legs and long toe claws |
| Catapult CPLT-C1 | [Original TRO:3025 Catapult](https://www.sarna.net/wiki/Catapult) | [Shimmering-Sword modern technical drawing](https://www.deviantart.com/shimmering-sword/art/Battletech-Catapult-786522819) | Narrow aircraft fuselage; visually dominant two tall LRM-15 racks separated above cockpit; no forearms or hands; thin three-link bird limbs and independently splayed toes |
| Original lab prototype | [Locust light-walker proportions](https://www.sarna.net/wiki/Locust) | [Crab industrial limb/actuator references](https://www.sarna.net/wiki/Crab) | Noncanonical test demonstrator, narrow spine, sensor mast, one diagnostic cannon and one manipulator claw; cannot be claimed canonical |

## Rebuild rules

1. **Every part dictionary starts empty.** No inherited anonymous torso,
   ellipsoid limbs, or previously layered `VoxelAnatomyV2`,
   `VoxelRosterSculpt`, `VoxelSilhouetteV3`.
2. At thumbnail scale, no two canonical mechs should be confused. The
   overall widths, heads, weapon positions, hip centers, and exposed
   leg joints must visibly differ even in flat monochrome.
3. **Height is structural, not false voxel count.** A per-chassis display
   `height_stretch` lengthens Y on the frame without moving the existing
   knee/hock joint angles. Actual cells remain damageable.
4. Legs are relatively narrow through the calf: a thin inner actuator,
   open side channels and discrete knee and ankle armor. Feet have
   separate toes, not large fused bricks.
5. Weapon bores must be genuinely vacant cell tunnels. The Atlas AC/20
   and five missile exits, Hunchback AC/20, Wolverine AC/5 + SRM6,
   Jenner four medium lasers + SRM4 and Catapult thirty rack exits are
   distinct.
6. Keep 100k–150k **actual occupied microvoxels** per model as a budget,
   not an end in itself. More/lower resolution is justified only if it
   improves model shapes or captures reference details.
7. Validate **front, three-quarter, and side Godot renders of all six
   models**, plus tests for view-space landmarks and the walking rigs;
   do not assume a failed artistic comparison is made good by a CI pass.
8. No change to official `src/core/` combat rules, and no APK export
   unless the user explicitly requests it.

## Current status

This document is an implementation spec, not a claim of final visual
accuracy. Approval requires comparing actual final Godot captures with the
reference images, and measuring mobile performance before any release.
