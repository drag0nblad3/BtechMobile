# Shape refinement cycle 13 — twenty reference-led cycles (206–225)

**Gate:** shape geometry only, `subdivide: 1`; not approved for 100–150k subdivision, additional panel detail, battle integration, or a production build. Changes based on polygonal source lofts; the voxelized raster is used **only to verify the shape**. This branch extends passes 198–205 rather than revising the high-resolution procedural lab.

## Reference survey — consulted before editing

Primary and higher weight: contemporary Catalyst plastics, with variant identification checked against catalogues. Secondary angles and older art are only dimensional cross-checks, not replacements for the chosen current sculpts.

* **Atlas AS7-D (Hansen's Roughriders, 2023):** [Catalyst product photos](https://store.catalystgamelabs.com/products/battletech-hansens-rough-riders-battle-lance), [unpainted front photo](https://meeplescorner.co.uk/uk/products/battletech-hansens-roughriders-battle-lance), [lance-front grouping](https://kryptonitekollectibles.com/products/battletech-hansens-roughriders-battle-lance); secondary [three-quarter Atlas reference](https://theblacksheepindustries.com/products/as7-d-atlas-battletech-miniature-resin-printed-model-inner-sphere-assault-battlemech) (not necessarily the same physical sculpt). Key anatomy: rounded high shoulder shells, skull **set down inside the chest**, faceted pectoral slope, cannon/rack offset, articulated forearm and hands; torso stays shallow in depth.
* **Wolverine WVR-6R (Beginner Box / A Game of Armored Combat):** [CGL miniature identified and photographed at Camo Specs](https://camospecs.com/listing/wolverine-wvr-6r-10/), [CGL plastic painted gallery](https://mechpainters.org/miniature/wolverine-clan-wolverine/), [variant and miniature description](https://scottsgameroom.com/2022/01/17/mech-manual-wolverine-wvr-6r/); secondary [three-quarter resin mini](https://syzgames.com/products/wolverine-wvr-6r), [early WVR illustration](https://www.sarna.net/wiki/File:Wolverine_WVR-6R_FSW.jpg). Key anatomy: small narrow angular cockpit, barrel/gripping **same** right cannon arm, other fist, shoulder-adjacent six-port launcher, wide abdomen rather than cinched hourglass.
* **Jenner JR7-D (CGL Inner Sphere Striker Lance):** [catalogue/photo of official plastic](https://www.sarna.net/wiki/File:Inner_Sphere_Striker_Lance_-_Jenner.jpg), [CGL plastic three-quarter view](https://www.rpgminihunter.com.au/products/jenner-battletech-inner-sphere-striker-lance-set-catalyst-game-lab), [CGL force-pack identification](https://www.sarna.net/wiki/BattleTech:_Inner_Sphere_Striker_Lance), secondary [TRO style reference](https://mordel.net/tro.php?a=vtbm&id=188). Key anatomy: *flattened forward saucer-like cockpit*, distinct laser flanks above lower nose, level engine body, slender rear-bending knee/hock chain and splayed feet.

## Twenty coupled-component sculpt passes

Each pass below **edited two existing component lofts on each of the three chassis**; no new cosmetic solids, second limbs, or new voxel detail. Changes to left components also propagate to their mirrored counterparts.

| Pass | Atlas — paired shape edits | Wolverine — paired shape edits | Jenner — paired shape edits |
|---|---|---|---|
| 206 | Flatten outer shoulder-bell ends; slim skull midsection | Narrow helmet; broaden torso-base | Flatten nose/front of disc; reduce lower fairing |
| 207 | Reduce frontal chest volume; tighten head crown | Widen abdomen at center; lower outer launcher shoulder | Raise disc undersurface; thin below-lip |
| 208 | Clarify raised shoulder crest; sharpen eye brow | Slim helmet cheeks; spread breastplate | Lower windscreen and crown height |
| 209 | Slim gauntlet; shallow thigh armor | Slim gun-side shoulder/elbow casing | Flatten rim arc and its side crescent |
| 210 | Shallow lower arm; taper greave | Taper left upper/lower arm | Reduce flank arm bulk and mount yoke |
| 211 | Spread split front chest plates; shorten hip depth | Open ribcage/hip transition | Flatten dorsal shoulder pod and fuselage front |
| 212 | Balance opposite pectoral; narrow lowest torso | Slim forward helmet visor; lower missile mount | Slim disc-to-body brace and saddle |
| 213 | Lower shoulder ridge; expose undershoulder apron | Open opposite breastplane; tighten internal rear spine | Narrow femur and knee cowl |
| 214 | Sharpen supraorbital ridge; trim cheek | Fit same-gun wrist collar and hand | Slim lower shin and reposition tarsus profile |
| 215 | Taper nasal plate; reduce jaw bulk | Lift elbow linkage and armor without second arm | Straighten lower hock-to-brace connection |
| 216 | Clarify knee shield vs greave width | Slim knee yoke and shin fairing | Widen flat engine hull, tighten laser yoke |
| 217 | Taper thigh and lower fist contour | Reduce thigh cuff bulk with wider supporting thigh | Reduce raised windscreen roof and lip |
| 218 | Shape hand cuff and thumb | Fit neck linkage, narrow internal rear spine | Thin disc underside and forward chin fairing |
| 219 | Shallow forward greave; tighten boot | Slope both shoulder cowls | Improve leg-root-to-hip angular links |
| 220 | Compress abdomen transition to hips | Slim left shoulder joint and chest frontal depth | Pointed disc nose and glazing narrower in front |
| 221 | Reduce rack cradle bulk and gun root bushing | Refine breastplate angles, elbow armor | Tighten front windscreen and lower glazing lip |
| 222 | Reduce mandible, lower central brow | Refine toe width and shin taper | Lower rear reactor protrusion and noseward foot front |
| 223 | Expose underplate edge; reduce arm rotary collar | Broaden pelvis and abdomen upper transition | Splay boots while re-angling lower shin |
| 224 | Angle toe/foot and taper shin | Lower helmet brow, refine opposite breastplane | Lower saucer crown and trim windscreen bottom |
| 225 | Taper shoulder hood and shorten rear chest | Flatten rear torso and tighten gun-side upper arm | Taper mirrored disc rim and top of nacelle |

## Measurements and shape-stage checks

All 20 passes changed both nominated loft profiles on all three chassis. **120** hand-selected contour operations adjusted **632 polygon vertices** across **77 distinct parts** (Atlas: 231 edits / 26 parts; Wolverine: 192 / 24; Jenner: 209 / 27). These are actual source loft edits, *not* added subdivided voxels.

Source-raster **union** occupancy, before → after (not the final high-resolution voxel count):

| Chassis | Before | After | Key checks |
|---|---:|---:|---|
| Atlas | 15,997 | 15,259 | head/chest connected; shoulder underplate overlap 339→274; AC/20 and 10 LRM apertures open |
| Wolverine | 15,449 | 15,266 | right arm/cannon mount overlap 298→268 while hand still intersects same AC5 and mount; six SRM mouths open |
| Jenner | 15,597 | 15,045 | saucer head/rim overlap 166→138; 20-cell head width, protruding nose, side laser bores intact |

Static validation: section order, integer coordinates, matching polygon vertex counts, `subdivide: 1`, all required part connections and named physical landmarks, and selected weapon mouths. Geometry intersection is allowed wherever it ensures a working mechanical connection; the goal is not to erase all stacking.

**Not yet performed:** Godot GDScript runtime unit tests, in-engine multiple-angle render and visual approval. No APK generated. A modeller should now review front/side/top/rear projections against the photo references before starting any density/detail stage.
