# Polygon-first shape refinement — cycles 226–245

**Baseline:** `feature/shape-reference-cycles-206-225`. Twenty cycles on Atlas AS7-D, Wolverine WVR-6R, Jenner JR7-D. Work remains at the **component-loft geometry approval gate**, `subdivide: 1`; no density/detail work, APK or merge. The purpose of this set is to change assembled component silhouettes, not generate decorative voxels.

## References revisited before sculpting

Current physical Catalyst miniatures are the primary sculpt reference; alternate models and historical art are proportion cross-checks only:

- **Atlas:** [Hansen's Roughriders plastic front](https://meeplescorner.co.uk/uk/products/battletech-hansens-roughriders-battle-lance), [Catalyst Miniatures identification](https://www.sarna.net/wiki/File:Hansen%27s_Roughriders_Battle_Lance_Atlas.jpg), [lance set photo](https://kryptonitekollectibles.com/products/battletech-hansens-roughriders-battle-lance). Main comparisons: near-level round shoulders framing sunk skull, fists at ends of individual arms, flat-ish deep shoulder cap behind shallow chest, clear thigh/shin/knee segmentation.
- **Wolverine:** [Catalyst premium miniature](https://store.catalystgamelabs.com/products/battletech-premium-miniature-wolverine), [Camo Specs photos](https://camospecs.com/listing/wolverine-wvr-6r-10/), [WVR-6R flank/three-quarter cross-check](https://syzgames.com/products/wolverine-wvr-6r). Main comparisons: small angular head, broad armored ribs, compact launcher near helmet, **one** bent right cannon arm with one integrated grip, left hand and leg proportions.
- **Jenner:** [CGL Striker Lance front](https://www.rpgminihunter.com.au/products/jenner-battletech-inner-sphere-striker-lance-set-catalyst-game-lab), [same sculpt from side](https://www.rpgminihunter.com.au/products/jenner-battletech-inner-sphere-striker-lance-set-catalyst-game-lab), [force pack official identification](https://www.sarna.net/wiki/BattleTech:_Inner_Sphere_Striker_Lance). Main comparisons: low protruding flattened cockpit head with broad plan-view disc, paired outer laser pods and shallow underbody, two-bend digitigrade hocks and spread feet.

## Source edits

The exact twenty cycle objectives and three edits **per model, per cycle** are recorded in machine-readable `tools/shape_loft_passes_226_245.json`. Every cycle changed existing polygon-section lofts on all three mechs; some related mirrored pieces inherit the changes automatically. Most changes alter cross-sectional outline or component attachment angle. Where a contour-edge reduction caused a narrow polygon to turn inside-out, the source editing pass preserved topology by translating the *entire local contour section* instead; it did not add a duplicate shell.

| Model | Geometric emphasis | Observed source geometry |
|---|---|---|
| Atlas | Expose separate lower shoulder apron, recut high pauldron cap, keep a recessed skull and jaw, shrink overdeep thorax, taper gauntlets, knees, greaves and feet | 73 authored parts; shoulder apron reduced buried upper plate while retaining contact; CT/head still intersect |
| Wolverine | Reduce upper shoulder and helmet proportions while widening torso waist, reshape chest V, elbow, cannon mount, cannon-side gripping hand and knee links | 48 parts; **exactly two** authored right-arm lofts remain; mount and hand still physically join the autocannon |
| Jenner | Flatten forward disc and its windscreen/fairing/underlip, fit side nacelles and low reactor body, slim femur/knee/hock and reshape boots | 62 parts; disc diameter remains 20 source-grid units and forward nose still extends to z=-36 |

In total: **20 × 3 × 3 = 180 named loft reshaping operations**, altering **864 source profile vertices**. Additional correction lowered the Atlas underplate's overlapping upper surface while preserving its exposed apron.

## Technical validation

- `subdivide = 1` on all three shapes; no 100k–150k target until geometry approval.
- All checked source polygon sections preserve vertex counts and ordered loft stations; no new near-zero/crossing contours in the authoring process.
- Separate voxel occupancy diagnostic (not used for rendering): source unions Atlas 14,808, Wolverine 14,755, Jenner 14,394 prior to final Atlas underplate trim. Counts are *low-resolution validation values*, not intended art density.
- Atlas AC/20 + LRM rack bores, Wolverine AC/5 + six missile ports and Jenner flank laser bores remain empty in the diagnostic occupancy grid.
- Wolverine diagonal cannon spar retains its elbow and breech landmarks and overlaps both its single forearm and the gripping hand.
- No APK built and no merge.

## Render: **polygon source geometry, not voxels**

[`previews/loft_surfaces_226_245.png`](../../previews/loft_surfaces_226_245.png) is one 12-panel contact sheet: **three-quarter, front, side, top** × Atlas, Wolverine, Jenner. Its render triangles come from the *authored loft profile vertices and joins*, plus original bar/box component surfaces. Each polygon is depth-tested directly. It does **not** construct a voxel grid or draw voxel cubes.

**Limitations:** This is a coarse preview of the polygon source and not a Godot screenshot. `erase` operators used for negative cuts are not Boolean-subtracted in the surface-only proxy, so confirm gun bore cutouts and true color/material assignment separately with the actual loader. Visual likeness approval is still pending.

CI: Godot unit test results to be recorded after PR checks.
