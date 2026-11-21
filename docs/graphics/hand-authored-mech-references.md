# Reference-sculpted voxel chassis

These are **distinct hand-authored chassis**, not variations on the procedural voxel lab's shared humanoid generator. All geometry is constructed as ordered, named shapes in a shared world grid before subdivision. The `trim_overlaps` flag removes shared pivot-boundary cells from earlier parts to avoid z-fighting while allowing disjoint articulation. Each model retains per-location damage and a fine-resolution pass in `VxRefine`.

## Atlas AS7-D
- [Atlas original technical readout](https://mordel.net/tro.php?a=vt&id=72&ut=bm): skull cockpit and exceptionally broad shoulder/arm silhouette
- [Atlas orthographic concept sheet](https://ca.pinterest.com/pin/19844054593742889/): front, side and rear proportions
- [Atlas AS7-D loadout](https://mech.guide/units/atlas-as7-d): torso AC/20, LRM-20, SRM-6 and medium lasers
- Front: narrow skull eye apertures and jaw, right torso AC/20 bore, left torso LRM racks; side: heavier upper body over a narrower waist, full arm gauntlets and wide feet

## Wolverine WVR-6R
- [Wolverine FSW illustration](https://www.sarna.net/wiki/File:Wolverine_WVR-6R_FSW.jpg): rectangular cockpit, left shoulder six-hole SRM launcher and forearm cannon
- [Wolverine side/miniature study](https://syzgames.com/products/copy-of-hatamoto-chi-htm-27t-daniel): asymmetry, mechanical forearms and leg depth (different variant; use for 3D articulation only)
- [WVR-6R weapons](https://mwo.fandom.com/wiki/Wolverine_WVR-6R): AC/5 in right arm, SRM-6 in left torso, medium laser in head
- Front: upright SRM tower offset from the head; right: AC/5 nacelle extending below arm; legs: high knee joints, tapered calf plates, separated feet

## Jenner JR7-D
- [Jenner technical readout](https://mordel.net/tro.php?a=vtbm&id=188): extremely prominent forward-facing cockpit, rear SRM-4 cluster and very short weapon nacelles
- [Jenner three-quarter illustration](https://www.sarna.net/wiki/Jenner): reverse-jointed feet and high-slung body
- [Jenner miniature angles](https://syzgames.com/products/copy-of-kintaro-kto-19): pod-to-cockpit proportions, leg-to-body separation (alternate rendition)
- Profile: elongated projecting cockpit, wide horizontal engine deck; front: four paired laser bores and tall leg links with distinct knee/hock/ankle pivots

**Fidelity gate:** target 100k–150k occupied cells **after** subdivision, beveling and overlap trim; keep physics-independent damage and weapon muzzle coordinates anchored to openings. Do not build an APK as part of this modeling work. The procedural lab remains a legacy comparison until its renderer is explicitly retired.

## Geometry budget verification

The authoring-time independent occupancy simulator mirrors `VxModel._trim_overlaps` and `VxRefine._bevel` on the fine grid. It predicts:

| Chassis | Fine occupied voxels | Separate articulated parts | Silhouette (width:height) |
|---|---:|---:|---:|
| Atlas AS7-D | ~121,146 | 12 | 0.71 |
| Wolverine WVR-6R | ~123,223 | 12 | 0.73 |
| Jenner JR7-D | ~144,932 | 14 | 1.06 (wide scout hull) |

Godot CI independently checks those targets with `tests/unit/test_vx_reference_sculpt.gd` and `tools/vx_count_report.gd`. The fine-resolution values should be treated as estimates until the Godot job runs. Neither the separate procedural Mech Lab nor Claude's original Catapult/Hunchback JSON files are overwritten by this PR.
