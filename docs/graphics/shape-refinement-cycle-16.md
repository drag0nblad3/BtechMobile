# Reference-led polygon geometry cycles 256–275

**Baseline:** `feature/atlas-arm-geometry-rework-246-255` (Atlas arm cleanup complete, CI passing). **All three mechs were edited for 20 full modeling cycles**, 2 paired source-loft operations each, 120 operations overall. These alter existing polygon sections/attachment profiles, not cosmetic detail, generated meshes, or final voxel density.

## Reference hierarchy

Current Catalyst Game Labs plastic miniatures are the primary shape standard. Variant identification and reference angles were cross-checked using [Sarna's CGL miniature index](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs).

- **Atlas AS7-D:** [Catalyst Hansen's Roughriders official product with single Atlas miniature](https://store.catalystgamelabs.com/products/battletech-hansens-rough-riders-battle-lance), [second front-view photo](https://meeplescorner.co.uk/uk/products/battletech-hansens-roughriders-battle-lance), [Roughriders group scale comparison](https://kryptonitekollectibles.com/products/battletech-hansens-roughriders-battle-lance). Key form cues: skull recessed between level/broad rounded shoulder caps, short fists and exposed wrists, separate thighs and calf/knee armor, no deep barrel torso.
- **Wolverine WVR-6R:** [Camo Specs painted Catalyst plastic](https://camospecs.com/listing/wolverine-wvr-6r-10/), [another Camo Specs angle](https://camospecs.com/listing/wolverine-wvr-6r-2/), [CGL plastic painter source](https://mechpainters.org/miniature/wolverine-clan-wolverine/), and [WVR-6R three-quarter alternative sculpt](https://syzgames.com/products/wolverine-wvr-6r) for cross-check only. Narrow angular helmet, launcher next to the head, wider abdomen than neck, ONE bent gun arm with the gripping hand enclosing the AC5.
- **Jenner JR7-D:** [official Striker Lance pack identification](https://www.sarna.net/wiki/BattleTech:_Inner_Sphere_Striker_Lance), [CGL Kickstarter unpainted model three-quarter image](https://www.ebay.com/itm/403292195264), and [Striker Lance lineup](https://www.walmart.com/ip/318122401). Flattened protruding disc/cockpit, broad horizontal engine fuselage, short symmetric side laser nacelles, narrow reverse-bend leg/hock links.

The geometry stage is not an invitation to raise voxel density. `subdivide: 1` remains fixed, and the rendered image is drawn **directly from authored loft polygon surfaces**, not voxelized cubes.


## Twenty coordinated anatomy cycles

| Cycle | Intent | Atlas components | Wolverine components | Jenner components |
|---|---|---|---|---|
| 256 | Atlas shoulder caps frame skull; Wolverine helmet chest ratio; Jenner forward disc canopy | lt + hd | hd + ct | hd_disc_crown + hd_front_windscreen |
| 257 | Atlas chest shallow under pauldron; Wolverine upper ribs and waist; Jenner disc lower fairing | ct + ct_left_breast_plate | ct + ct_wide_abdomen | hd_disc_lower_fairing + hd_round_underlip |
| 258 | Atlas other shoulder crown, centered head; Wolverine compact launcher root; Jenner outer rim | rt + hd | lt_srm6_inner_mount + lt | hd_disc_rim + hd_disc_rim |
| 259 | Atlas clavicle-to-head face; Wolverine cannon elbow supported; Jenner flank laser yoke | ct_left_clavicle + hd_left_orbit_brow | ra_cannon_mount + ra_compact_elbow_armor | la_pod_yoke + la |
| 260 | Atlas upper arm shoulder socket and elbow transition; Wolverine intact one-arm chain; Jenner pod fuselage connection | la_rotator_socket + la | ra + ra_elbow_link | lt + ct |
| 261 | Atlas upper arm width and wrist trim; Wolverine left arm less bulky; Jenner rear thigh volume | la + la_knuckle_cuff | la + la_shoulder_yoke | ll + ll |
| 262 | Atlas thigh shin shape distinction; Wolverine knee guard/greave; Jenner lower hock assembly | ll + ll_knee_guard | ll_shin_fairing + ll_knee_yoke | ll_shin + ll_hock_joint |
| 263 | Atlas lower armor to pelvis; Wolverine hip cage wider than waist; Jenner tarsus-to-foot flow | pelvis + ct_lower_abdominal_armor | pelvis + ct_wide_abdomen | ll_tarsus + ll_foot |
| 264 | Atlas jaw skull clearance and cheek; Wolverine visor-to-neck; Jenner canopy side arc | hd_lower_mandible + hd_cheek_left | hd_angular_cheek_left + hd_neck_yoke | hd_left_disc_crescent + hd_top_glass_left |
| 265 | Atlas chin-to-collar and chest; Wolverine shoulder asymmetric contours; Jenner dorsal saddle | hd_neck_collar + ct_right_breast_plate | rt + lt | hd_rear_disc_saddle + hd_disc_neck_brace |
| 266 | Atlas gauntlet knuckle alignment; Wolverine integrated hand/cannon grip; Jenner bridge to saucer | la + la_outer_thumb_pad | ra_integrated_hand + ra_grip_wrist_collar | lt_disc_bridge + hd_left_disc_strut |
| 267 | Atlas rear torso less deep; Wolverine chest rib thickness; Jenner outer nacelle profile | ct + ct_rear_left_radiator | ct_lower_breastplate + ct_lower_breastplate | la + lt |
| 268 | Atlas longer tapered shin profile; Wolverine thigh knee transitions; Jenner hock knee profile | ll_shin + ll_shin_plate | ll + ll_tapered_thigh_cuff | ll_shin + ll_knee_cowl |
| 269 | Atlas round shoulder cap trim; Wolverine narrow missile rack support; Jenner rear-fuselage roof | lt_round_shoulder_band + lt_shoulder_ridge | lt_srm6_inner_mount + ct_rear_jump_pack | ct + ct_rear_reactor_spine |
| 270 | Atlas hips knees slender; Wolverine left fist definition; Jenner feet toes and ankle | ll + ll_knee_inner_yoke | la + la | ll_foot + ll_front_ankle_link |
| 271 | Atlas reduced rear shoulder depth; Wolverine armor angle on shoulder; Jenner pod yoke proportion | lt + rt | lt + rt | la_pod_yoke + hd_left_disc_strut |
| 272 | Atlas neckline and brow recessed; Wolverine small angular cockpit; Jenner flattened forward prow | hd_recessed_brow_bridge + hd | hd + hd_angular_cheek_left | hd_front_windscreen + hd_disc_crown |
| 273 | Atlas hand boot final shape; Wolverine sole/ankle; Jenner knee/foot splay | ll_foot + ll_ankle_collar | ll_foot + ll_shin | ll + ll_foot |
| 274 | Atlas chest and shoulder adjacency; Wolverine abdominal armor; Jenner disc undercarriage | lt_round_shoulder_underplate + ct_left_breast_plate | ct_wide_abdomen + ct | hd_round_underlip + ct_belly_front_apron |
| 275 | Atlas face shallow and arms balanced; Wolverine AC5 same-arm continuity; Jenner compact disc/body transition | ct + la | ra + ra_cannon_mount | hd_disc_lower_fairing + ll_rear_hock_brace |

All exact operations, their section selection, and the applied contour modes are saved in `tools/shape_loft_passes_256_275.json`. To protect narrow shapes, 57 attempted extreme-edge moves required **single-corner constrained redrafting** rather than allowing face crossings or collapsed polygon loops. Every documented cycle changed two existing lofts on each chassis; no parts were added just to disguise old forms.

## Assembly-level checks

An independent **coarse occupied-grid check** (diagnostic only, not render or new art density) compared the incoming branch to the revised branch:

| Mech | Before | After | Connected landmarks |
|---|---:|---:|---|
| Atlas | 14,980 | 14,541 | shoulder apron/head/chest; shoulder→upper arm→wrist band→fingers/thumb; no return to knee-length arms |
| Wolverine | 14,755 | 14,647 | one right upper arm and one diagonal forearm, one autocannon mount, hand contacts both gun and mount, offset SRM-6 still connected |
| Jenner | 14,394 | 14,028 | 20-cell disc width, forward nose at (0,26,-36), rear hock brace at (-7,8,10) |

**Verified in independent static diagnostic:** Atlas AC/20 and ten front LRM ports open; Wolverine AC/5 and six SRM ports open; Jenner both side-laser muzzle pairs open. All sampled paired component contacts remain positive. No subdivision changes, no APK, no merge.

The static contour audit found no new self-intersecting profile sections, unsorted loft stations, duplicate source part names, or collapsed profile areas. Godot GDScript CI is a separate required validation step and is not a substitute for inspecting silhouette images.

## Actual polygon-surface render

[Four-angle three-mech contact sheet](../../previews/loft_surfaces_256_275.png) — three-quarter, front, right side, and top-down, in columns Atlas / Wolverine / Jenner. PNG is generated by z-buffer triangle rasterization of **the source loft profiles joined directly into polygon faces** (and original authored box faces). It does not sample the voxel occupancy grid, render voxel cubes, or use AI illustration. Diagnostic colors are for reading geometry only. The source `erase` Boolean operations are not cut out in this polygon-only proxy; actual weapon bore emptiness was separately verified by the coarse occupancy audit.

**Status:** shape modeling still under visual review. No high-density/detail stage or release artifact is authorized.
