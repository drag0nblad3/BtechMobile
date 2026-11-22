# Atlas lower-arm geometry correction — passes 246–255

**Branch:** `feature/atlas-arm-geometry-rework-246-255`, stacked on polygon-shape passes 226–245. **Only Atlas** changed; Wolverine and Jenner source models remain untouched. The project stays in its **shape-first geometry stage**, `subdivide: 1`. No high-density voxelization, gameplay or gait work, APK build, or merge.

## Reference check

The Catalyst Game Labs 2023 Hansen’s Roughriders AS7-D Atlas miniature was the priority. [Direct front photo of the mini](https://www.ebay.com/itm/404166265786), [Catalyst plastic range listing](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs), and [Hansen’s Roughriders product set description](https://www.sarna.net/wiki/Hansen%E2%80%99s_Roughriders_Battle_Lance).

In the mini, the upper arm hangs below the shoulder bell, the elbow leads to one broad but relatively short angular gauntlet, and the fists close near hip/lower chest height rather than knee level. Both hands have identifiable knuckle surfaces and a thumb. They must not look like separate cylinders hanging in parallel.

## Actual problems observed in source geometry

- The `la` lower armor was three loft volumes layered across y=21–36, plus **four little finger/thumb boxes within the arm itself**.
- A distinct `la_finger_knuckles` part added another **four** finger/thumb boxes at the same height, including a duplicate outside thumb.
- The `la_outer_thumb_pad` loft covered the same outer-fist region and only shared **2 source voxels** with the whole arm before changes — nearly detached.
- The base arm reached y=21, almost to the knee at y≈19, despite the shoulder centered around y≈41; this exaggerated the whole forearm.
- Some cross-sections pinched into razor-thin intermediate profiles and caused the impression of a second arm/fist. The individual wrist trim was almost wholly buried.

All corresponding right-side geometries are derived by `mirror`, so correcting the source left-side geometry corrects **both arms**.

## Ten shape-only cycles

| Pass | Main source geometry edit |
|---|---|
| 246 | Rebuild short tapered gauntlet at y=30–39 instead of y=24–36 |
| 247 | Reconnect elbow y=34–40 and redraw upper-arm contours |
| 248 | Delete four redundant arm-level finger/thumb boxes |
| 249 | Resculpt the single closed fist at y=28–34 and move three actual finger blocks to y=26–29 |
| 250 | Reposition wrist cuff to y=31–35 and adjust its pivot |
| 251 | Rebuild one connected thumb pad at y=30–34 and adjust its pivot |
| 252 | Reshape pinched shoulder rotator profile into one anchored bearing |
| 253 | Refine front-to-back taper and gauntlet angle |
| 254 | Thin and expose cuff cross-sections at the wrist |
| 255 | Adjust thumb-tip depth and preserve contact with the newly positioned fist |

A final finishing change moved the cuff's source-loft stations forward in z and tapered the elbowward shell. No other geometry was added.

## Coarse contact validation, *not* a voxel-detail pass

These approximate occupied-grid overlaps are a **connectivity diagnostic** based on the authored polygon lofts. The render below is **not made with these voxels**.

| Contact | Before | After |
|---|---:|---:|
| Main LA ↔ shoulder rotator socket | 42 | 166 |
| Main LA ↔ wrist cuff | 29 | 69 |
| Main LA ↔ finger geometry | 29 | 14 |
| Main LA ↔ outside thumb | 2 | 55 |
| Wrist cuff exposed outside main arm | 8 | 21 |
| Outside thumb exposed outside main arm | 81 | 16 |

The finger bases remain attached but extend visibly below the glove; the thumb is now connected instead of floating. The right-side arm mirrors the left with the same source-grid count of 779 main-arm occupied cells.

**Authoring checks:** all modified sections have consistent vertex counts, noncrossing contours and positive area. New regression tests are in `tests/unit/test_atlas_arm_assembly.gd`. All prior Atlas torso, rocket rack, cannon mouth, and leg models remain as on the parent branch.

## Render — raw polygon source surfaces

[Before / after four-view contact sheet](../../previews/atlas_forearm_before_after_246_255.png)

The PNG compares pre-cleanup and post-cleanup shape geometry at identical camera scale, with three-quarter, front, side and right-arm detail projections. It is rendered by triangle rasterizing the original `loft` contours and authored `box` faces, with **no voxelization whatsoever**. Materials are diagnostic colors; the source `erase` operations are not Boolean-subtracted by this geometry-only surface preview.

**Approval state:** silhouette review pending. This is a noticeable arm construction repair, not permission to begin adding 100k–150k detailed voxels.
