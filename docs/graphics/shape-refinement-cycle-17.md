# Front-silhouette modeling review — cycles 276–295

**Starting point:** `feature/shape-three-mech-p256-275`, all three models still at `subdivide: 1`. This is **geometry source refinement only**. No high-resolution voxelization, texture pass, gameplay changes, APK, or merge.

## Reference hierarchy

Front silhouette was the primary target, with modern **Catalyst Games Labs plastic sculpts** highest-weight. Side and three-quarter photos were checked to avoid creating anatomically implausible extrusions.

- **Atlas AS7-D / Hansen's Roughriders 2023 plastic:** [Catalyst store front-facing Atlas image](https://store.catalystgamelabs.com/products/battletech-hansens-rough-riders-battle-lance), [front view in the Battle Lance assortment](https://kryptonitekollectibles.com/products/battletech-hansens-roughriders-battle-lance). Characteristic frontal arch: broad round shoulder bells nearly framing the recessed skull at equal height, generous armor above separate forearms/fists, stable chest taper and thick squarely loaded legs. The old authored shoulder crowns looked like vertical boxes, so all longitudinal sections were redrawn into rounded outlines rather than adding another shell.
- **Wolverine WVR-6R / CGL Beginner Box and A Game of Armored Combat plastic:** [Camo Specs WVR-6R gallery](https://camospecs.com/listing/wolverine-wvr-6r-10/), [painted official plastic WVR-6R](https://mechpainters.org/miniature/wolverine-clan-wolverine/), [CGL identification](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs). Shoulders are angled around a **small angular helmet**; ribcage stays broad into waist and thighs; one long right diagonal gun/hand is distinct from the other hand; SRM-6 has a compact offset shoulder cradle. The shoulder polygons were individually redrafted and the torso/hip bands rebalanced.
- **Jenner JR7-D / CGL Inner Sphere Striker Lance plastic:** [plastic front/rear silhouette and digitigrade legs](https://www.rpgminihunter.com.au/products/jenner-battletech-inner-sphere-striker-lance-set-catalyst-game-lab), [official plastic sculpt three-quarter](https://www.ebay.com/itm/403292195264), [CGL miniature catalogue identification](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs). Its defining forward rounded cockpit/disc should be *shallow relative to width*, separated from side laser nacelles, with slim reverse-jointed legs and broad toes. The forward disc was flattened without changing the 20-unit width or head nosepoint.

## Twenty cycles and component pairing

The complete plan is `tools/front_silhouette_cycles_276_295.json`, with the exact source-loft target, section selection and edit mode for every operation. There were **20 passes on each chassis**, with **126 explicit source-geometry edits** total (42 per mech). Each pass changes at least two actual existing loft volumes on **each** model, frequently three. No duplicate outer shells were introduced.

| Cycle | Geometry objective |
|---|---|
| 276 | Rebuild large shoulder and disc silhouettes |
| 277 | Chest plates and helmet proportions |
| 278 | Shoulder socket and cheek transitions |
| 279 | Thoracic width / launcher height |
| 280 | Shoulder and upper arm shape |
| 281 | Gauntlet / cannon arm / side rim |
| 282 | Hips and leg sockets |
| 283 | Thigh mass and knee cowls |
| 284 | Knee/shin transitions |
| 285 | Calf and hock dimensions |
| 286 | Ankle and foot stance |
| 287 | Helmet and disc upper profile |
| 288 | Pectoral and shoulder side seams |
| 289 | Hands and outer nacelles |
| 290 | Lower front torso |
| 291 | Crests and launcher support |
| 292 | Front-view leg spacing |
| 293 | Toe/ankle stance |
| 294 | Front armor cleanup |
| 295 | Final frontal balance |

**Major deliberate source reshapes:** Atlas left/right main shoulder lofts each entirely redrawn in all six longitudinal sections; Atlas shoulder crown band reprofiled across four sections; Wolverine left/right shoulder lofts rebuilt across all four sections; Jenner front head/disc profile flattened over its forward longitudinal contours. This was followed by changes to chest plates, head/brow, upper arm sockets, wrists, thigh sockets, knees, shin profiles, ankle and foot exterior contours.

**Contour integrity:** all source lofts preserve equal polygon lengths between stations, ordered stations, and positive usable contour area. Strict self-intersection checks passed; eight narrow contour proposals used a shifted neighboring station instead of collapsing the profile to a slit.

## Front-view measurement checks

The independent source occupied-grid diagnostic is **for measurement and connectivity only**, not a renderer or higher-detail art stage. The frontal projection was sampled by all x positions containing material at a given vertical y.

| Frontal band | Before | After | Implication |
|---|---:|---:|---|
| Atlas crest y=54: occupied x columns | 16 | 6 | Replaced broad flat shoulders with curved domes, high center and sloped caps |
| Atlas shoulder-chest y=50: overall x span | 36 | 38 | Outer shoulder width retained despite rounded cap |
| Atlas arms/chest y=42: overall x span | 40 | 42 | Better shoulder and chest framing |
| Atlas lower stance y=3: overall x span | 20 | 22 | Slightly stronger planted feet |
| Wolverine pectoral/shoulder y=44: overall x span | 41 | 43 | Less pinched frontal shoulder-to-chest transition |
| Wolverine legs y=16: overall x span | 18 | 20 | Leg balance relative to broadened upper body |
| Jenner upper body y=33: overall x span | 36 | 34 | Less over-tall/angular wing-upper edge |
| Jenner laser/nacelle y=27: overall x span | 36 | 36 | Preserves signature side-pod stance |

### Anatomy safety constraints

- **Atlas:** both arms remain mirrored, main forearm starts no lower than y=28, each hand stays in contact with cuff, fingers, thumb and shoulder bearing; torso still intersects recessed head. Main cannon landmark and 10 LRM mouths remain.
- **Wolverine:** `ra` still contains exactly **two** authored shapes (one upper arm and one gun-bearing forearm). The cannon mount retains both diagonal bend landmarks; integrated hand contacts the AC/5 shroud. All six SRM openings stay unobstructed.
- **Jenner:** source disc remains **20 units** wide with frontmost nose at `(0, 26, -36)`, and rear hock-brace landmark `(-7, 8, 10)` persists. All four side-laser openings stay unobstructed.

## Renders

- [Full 15-panel four-angle and before/after contact sheet](../../previews/front_silhouette_276_295_before_after.png): top two rows are large after/before frontal views; lower rows show three-quarter, right-side, and top-down geometry.
- A smaller two-row **before/after front-only image** was shown directly in the conversation to avoid GitHub raw-link issues.

Both renders are rasterized by triangulating **original loft source polygons directly** and applying a depth buffer; **no voxel surface was constructed to produce the images**. Diagnostic shading and visible silhouette edges make each boundary easier to evaluate. Original `erase` operators are not Boolean-subtracted from this direct polygon view; weapon openings were audited separately using coarse occupancy.

**Next gate:** human visual acceptance of front proportions, plus Godot CI. Do not enter 100k–150k voxel-detail stage until shape approval.
