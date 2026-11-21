# Front-silhouette geometry refinement — passes 276–295

**Status:** source polygon modeling only, `subdivide: 1`; not approved for high-density voxelization, gameplay integration, release or APK.

## References: strongest weight on current Catalyst plastic

- **Atlas AS7-D:** [Catalyst's Hansen's Roughriders official re-posed Atlas front photograph](https://store.catalystgamelabs.com/cdn/shop/files/HR-Atlas-NewPose.jpg?v=1734215751) and [Catalyst release explanation](https://www.catalystgamelabs.com/news/three-new-mercenaries-forcepacks). Important straight-on silhouette cues: broad **rounded** shoulder domes framing a sunken skull, substantial upper chest, single raised gauntlets with clenched hands, leg armor taper through knees to sturdy feet.
- **Wolverine WVR-6R:** [CGL Premium Wolverine photo](https://store.catalystgamelabs.com/cdn/shop/files/Wolverine3.png?v=1746551300&width=1445) and [Camo Specs WVR-6R plastic mini photography](https://camospecs.com/listing/wolverine-wvr-6r/); cross-check with [alternative posed 6R print](https://cdn.thingiverse.com/assets/14/69/40/3e/74/large_display_WVR-6R_1.jpg). Key cues: narrow angular cockpit above a broader pectoral/abdomen mass, sloping pauldron silhouette, offset launcher, single cannon-bearing hand and bent right arm, clear knee-to-boot contour.
- **Jenner JR7-D:** [CGL Striker Lance mini front photo](https://www.rpgminihunter.com.au/cdn/shop/files/Fit_P1190416_Final_1200x1200.jpg?v=1708318633) and [CGL Kickstarter three-quarter miniature](https://i.ebayimg.com/images/g/dHUAAOSwaWRidYD4/s-l500.png). Key cues: low oval/disc cockpit projecting in front of broad horizontal body, paired flank laser housings, two distinct digitigrade shin/hock chains rather than columns, and relatively narrow claw toes.

## Twenty full modeling cycles

Each row changed **three existing polygon component lofts on each chassis**, with primary evaluation based on the **front X/Y projection** rather than a three-quarter render. Exact station selections and operation modes: `tools/shape_front_silhouette_passes_276_295.json`.

| Pass | Anatomy goal | Atlas parts | Wolverine parts | Jenner parts |
|---|---|---|---|---|
| 276 | Round Atlas shoulder peaks; strengthen Wolverine shoulder slope; round Jenner protruding disc | lt, rt, hd | lt, rt, hd | hd, hd_disc_crown, ct |
| 277 | Connect Atlas round caps to chest; widen Wolverine ribs; smooth Jenner flanking housings | lt_round_shoulder_band, rt, ct | ct, lt, rt | lt, la, hd_disc_rim |
| 278 | Shape Atlas chest V and jaw, Wolverine under-shoulder contour, Jenner flattened prow | ct_left_breast_plate, ct_right_breast_plate, hd_lower_mandible | ct_lower_breastplate, ct_lower_breastplate, ct_wide_abdomen | hd, hd_front_windscreen, hd_disc_lower_fairing |
| 279 | Separate Atlas upper arm silhouette; reduce Wolverine giant elbow; Jenner side pod profiles | la, la_rotator_socket, lt_round_shoulder_underplate | ra, ra_compact_elbow_armor, la | la, lt, la_pod_yoke |
| 280 | Atlas skull brow and collar, Wolverine head silhouette, Jenner saucer underlip | hd_left_orbit_brow, hd_recessed_brow_bridge, hd_neck_collar | hd, hd_angular_cheek_left, hd_neck_yoke | hd_round_underlip, hd_disc_lower_fairing, hd_chin_fairing |
| 281 | Atlas broad shoulder outer slope, Wolverine launcher-side top outline, Jenner torso shoulder width | lt, rt, lt_shoulder_ridge | lt, lt_srm6_inner_mount, rt | ct, lt, hd_disc_rim |
| 282 | Atlas breastplate and waist shaping, Wolverine breastplate faceting, Jenner underbody | ct_left_breast_plate, ct_right_breast_plate, ct_lower_abdominal_armor | ct_lower_breastplate, ct_lower_breastplate, ct_faceted_waist_spine | belly, ct_belly_front_apron, hd_rear_disc_saddle |
| 283 | Atlas fist and cuff distinct, Wolverine gun arm single silhouette, Jenner paired laser pods | la, la_knuckle_cuff, la_outer_thumb_pad | ra, ra_cannon_mount, ra_grip_wrist_collar | la, la_pod_yoke, lt |
| 284 | Atlas hip width against chest, Wolverine pelvis support, Jenner leg-root spacing | pelvis, ll, ll_hip_guard | pelvis, ll, ll_tapered_thigh_cuff | ll, ll_leg_root, ll_hip_link |
| 285 | Atlas thigh knee break, Wolverine shin and knee scale, Jenner knee reverse-leg break | ll, ll_knee_guard, ll_shin | ll, ll_knee_yoke, ll_shin | ll, ll_knee_cowl, ll_shin |
| 286 | Atlas leg gap and greaves, Wolverine lower leg taper, Jenner hocks off centerline | ll_shin, ll_shin_plate, ll_ankle_collar | ll_shin, ll_shin_fairing, ll_foot | ll_shin, ll_hock_joint, ll_rear_hock_brace |
| 287 | Atlas foot width and toe shapes, Wolverine toe stance, Jenner claw-foot silhouette | ll_foot, ll_foot, ll_shin | ll_foot, ll, ll_hip_bearing | ll_foot, ll_tarsus, ll_front_ankle_link |
| 288 | Atlas shoulder cap second-round silhouette, Wolverine right pauldron slope, Jenner upper engine breadth | lt, rt, lt_shoulder_ridge | rt, ra, ct | ct, lt, ct_rear_reactor_spine |
| 289 | Atlas skull jaw placement and shoulder lip, Wolverine narrow head and wide abdomen, Jenner disc central brow | hd, hd_lower_mandible, lt_round_shoulder_underplate | hd, ct_wide_abdomen, ct_center_keel | hd_disc_crown, hd_top_glass_left, hd_low_glazing_brow |
| 290 | Atlas forearm taper and fist at hip, Wolverine left fist/arm mass, Jenner laser nacelle lower silhouette | la, la, la | la, la, la_shoulder_yoke | la, la_laser_lower, la_laser_upper |
| 291 | Atlas shorten visual shoulder walls, Wolverine align shoulder tops, Jenner cockpit body gap | lt_round_shoulder_band, rt, ct | lt, rt, ct | hd_disc_neck_brace, hd_rear_disc_saddle, hd |
| 292 | Atlas lower torso width and thigh armor, Wolverine abdomen thigh balance, Jenner thigh/hock distance | ct, pelvis_front_codpiece, ll_hip_joint | ct, pelvis, ll | ct, ll, ll_hock_joint |
| 293 | Atlas shoulder-to-arm gap check, Wolverine pistol/grip outline, Jenner disc rounded flank | la_rotator_socket, la, lt_round_shoulder_underplate | ra_cannon_mount, ra_integrated_hand, ra_compact_elbow_armor | hd_left_disc_crescent, hd_disc_rim, hd_disc_rim |
| 294 | Atlas face and leg silhouette final balance, Wolverine head-shoulder V, Jenner feet and ankle separation | hd, ll_shin, ll_foot | hd, lt, ll_shin | ll_tarsus, ll_foot, hd_front_windscreen |
| 295 | Final full-height front silhouette connection and cleanup | ct_left_breast_plate, ct_right_breast_plate, la_knuckle_cuff | ct_lower_breastplate, ct_lower_breastplate, ra | hd_disc_lower_fairing, lt, ll_shin |

In total, 20 cycles × 3 parts × 3 mechs = **180 existing-source loft operations** (Atlas 227 adjusted contour vertices across 28 parts; Wolverine 169 across 26; Jenner 199 across 31). Source edits use rounded dome/oval side profiles and controlled width, edge and bottom adjustments. The contour-safe editor used constrained local redrafts on 51 small polygon operations rather than allowing collapsed sections, crossed polygons, or extra interior solids.

**Post-pass visual-measurement correction:** Atlas front silhouette at upper crown height y=54 temporarily became too pinched. A follow-up correction broadened the central 3D shoulder crown cross-sections and raised the upper part of the existing shoulder-band contours to y=55, preserving a rounded top, not a point or giant horizontal block.

## Geometry validation

The source `subdivide` remains **1** on Atlas, Wolverine and Jenner. Static checks confirmed monotone loft stations, matching polygon vertex counts, no new contour intersections and non-collapsed cross-sections.

Coarse occupied-grid diagnostic of parts (not the renderer): Atlas forearm remains one compact gloved construction, mirrored on both sides with fingertip minimum y=28. Its CT/head and shoulder-apron contacts persist. Wolverine still has **one** right gun-bearing arm, one attached hand, six SRM mouths and an open AC/5 muzzle. Jenner preserves the disc's 20-cell width, forward nose at (0,26,-36), rear hock landmark (-7,8,10), and both laser pairs. All existing weapon openings checked are unobstructed.

Coarse cell unions before the late Atlas shoulder correction: Atlas 14,541 → 14,604; Wolverine 14,647 → 14,624; Jenner 14,028 → 13,664. These are NOT the desired final ~100–150k voxel counts, and no new voxelization/detail stage was performed.

## Preview requirement

`previews/front_silhouette_geometry_276_295.png` is a direct **source-loft polygon-triangle** contact sheet with matched **front BEFORE and front AFTER** views emphasized, plus three-quarter, right-side and top-down AFTER views. There is no intermediate voxel-grid rasterization, no AI-generated approximate illustration, and no substitution with a stock/reference photograph. The polygon-only viewer does not Boolean-subtract `erase` operators; muzzle cavities are validated separately in coarse occupancy checks.

No APK built, no merge. In-engine Godot CI required before approval.
