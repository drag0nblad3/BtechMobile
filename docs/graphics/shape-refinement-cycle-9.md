# Reference silhouette refinement — pass 9

**Review stage: low-resolution components only; not approved for detail.**
This branch changes the *geometry* of each mech, not voxel density, surface trim, damage, animation, or the APK. Keep one combined three-quarter Godot render per iteration.

| Chassis | Primary image | Secondary image | Geometry corrected |
| --- | --- | --- | --- |
| Atlas AS7-D | [Scull-and-shoulder reference, unpainted CAD](https://www.deviantart.com/lizzygibbs3d/art/FAN-ART-BattleTech-MechWarrior-AS-7-D-Atlas-551614099) | [Current tabletop sculpt, three-quarter](https://www.defiance-industries-wargaming.com/listing/4324190923/atlas-pmw-sculpt-multiple-variants) | Larger cranium, pronounced cheek/jaw taper, broad brow, sculpted dome/shoulder shells. Size relative to the 35t and 55t chassis. |
| Wolverine WVR-6R | [WVR-6R FSW technical artwork](https://www.sarna.net/wiki/File:Wolverine_WVR-6R_FSW.jpg) | [Multiple views of physical miniature](https://syzgames.com/products/wolverine-wvr-6r) | Front-leaning armored shoulder shields, an unmistakable pilot visor and slender antennas, chested armor plane replacing tube-like chest. |
| Jenner JR7-D | [Jenner technical drawing](https://mordel.net/tro.php?a=vtbm&id=188) | [Jenner three-quarter miniature](https://www.ebay.com/itm/205033594352) | Extended aircraft-like cab instead of central gun barrel, visibly raked canopy/front windshield, angular chin, horizontal fuselage, 35t scale. |

First review gate: head/cockpit, chest, left/right shoulder silhouettes and major negative space need to compare favorably to the above illustrations. Second gate: thigh/shin/hock/foot silhouettes and gaps, then a separate detail pass. Do not confuse the surface-only VxShapePreview with full game voxelized damage geometry: it does not render `erase` cuts.

After each actual in-engine render, log visible errors and resculpt the offending components before further refinement. **No increase to `subdivide` or target voxel counts before all three model shapes are approved.**

## Iteration and actual Godot review log

| Cycle | Visual finding from one in-engine gallery | Reference-driven change | Gate |
| --- | --- | --- | --- |
| 9 | Atlas head too small in the old baseline; Wolverine shoulders resembled hollow cannons; Jenner nose read as a turret | Enlarged Atlas skull, revised WVR shoulder and head, tapered Jenner cockpit, corrected 100t/55t/35t relative scale | Not approved |
| 10 | WVR large shoulder-front caps looked hollow; Jenner straight leg outlines hid reverse joints; Atlas missing signature apertures | Solid WVR arm shells and split chest shields; Jenner's knee and rear hock moved in actual cross-section profiles; separate five-opening Atlas launcher | Not approved |
| 11 | WVR armor caps remain too rounded; Jenner's bent legs lacked clear pivots and aircraft side windows; Atlas thighs looked generic | Hard-edged WVR pauldrons and long shin covers, Jenner side glass + hock/knee couplings, Atlas angular upper-thigh guards | Pending newest in-engine render |

Keep production gates unchanged: `subdivide: 1`, genuine per-chassis parts, **one** combined gallery image, no APK and no merge without instruction. Structural component contours must match both primary and secondary references and read correctly in isolation *before* fine details.

## Additional silhouette corrections

- **Pass 12 — armor plate directions:** WVR pauldron front caps changed to independent canted plates after fixing the preview's inward surface normals. Jenner's side-mounted paired laser nacelles use chamfered boxlike sections, not cylindrical pods. Atlas thigh guards are narrower and the upper-arm elbow linkage stays exposed.
- **Pass 13 — chassis proportions:** Atlas and Wolverine legs were elongated below the hip while the original individually sculpted upper assemblies were translated upward intact. This specifically targets the short-legged appearance in the prior Godot gallery; no global generic-mech mesh or fine-detail noise was introduced. Jenner's already-long digitigrade limbs were not stretched. Gallery labels are now derived from the models' actual heights.

The latest screen capture is a **single** gallery image; extra angle renders are not required for each ordinary iteration. Approval remains contingent on new visual inspection against the primary art—this is an active sculpting branch, **not** accepted final geometry.

## Expanded reference set — revisions 14 and 15

These are additional views for **shape matching**, not material/texture guides. Do not mix in Atlas II, Wolverine 6D, Jenner F, or other chassis variants.

| Chassis | New secondary image/reference | What the shape must show |
| --- | --- | --- |
| **Atlas AS7-D** | [Official newer Atlas line art](https://www.sarna.net/wiki/Atlas) | Skull with visible lower jaw, recessed between high shoulder cowlings; chest-mounted AC/20, shoulder/torso LRM rack, elbow and knee breaks |
| | [Stock AS7-D resin sculpture, front and rear photographs](https://www.laserforgeminiatures.com/products/atlas-as7-d-mech) | Flat shoulder roofs and front chamfers; torso length, back shell, arm spacing and calf depth; do not copy minute panel seams |
| | [Modern Atlas CAD sculpture](https://www.deviantart.com/lizzygibbs3d/art/FAN-ART-BattleTech-MechWarrior-AS-7-D-Atlas-551614099) | Depth and scale of Death's Head skull vs shoulder armor, physical 3-D component overlaps |
| **Wolverine WVR-6R** | [WVR-6R FSW line art](https://www.sarna.net/wiki/File:Wolverine_WVR-6R_FSW.jpg) | Angled slab pauldrons, distinct breastplate halves, 2×3 launcher beside helmet, forearm cannon separate from armor |
| | [WVR-6R dual-pose resin sculpture](https://syzgames.com/products/wolverine-wvr-6r) | Shoulder cross-sections, knee-to-foot proportion and negative space, left/right asymmetry |
| | [Alternate WVR-6R sculpt, side and three-quarter](https://afterdarkprints.net/products/wvr-6r-wolverine-alternate-battletech-model-1) | Shoulder sweep from side, long arm weapon shroud and separate calf armor plates |
| **Jenner JR7-D** | [JR7-D technical readout linework](https://mordel.net/tro.php?a=vtbm&id=188) | Long cockpit prow with window faces, four-port dorsal SRM rack, two smaller stacked laser barrels per nacelle, reverse-knee articulation |
| | [Later Jenner line art](https://www.sarna.net/wiki/Jenner) | Cockpit and nose length from oblique side; forward knee vs rear hock; rear-facing drive deck |
| | [JR7-D 3-D side/front view miniature](https://www.ebay.com/itm/205033594352) | Narrow legs vs horizontal body, short rectangular side pods, angular foot contact |
| | [JR7-D two-angle model](https://syzgames.com/products/copy-of-kintaro-kto-19) | Overall front width and paired-laser offsets |

### Visual review 14–15

- **Pass 14** reshaped the root component volumes for all three chassis: flat Atlas shoulder cowlings/short upper-arm guards; sharper and smaller WVR shoulder/torso pieces; narrower Jenner laser nacelles and a projecting cockpit nose. Multiple directions per model, rather than one generic torso template.
- **Diagnostic correction** the Godot `SurfaceTool` preview was *averaging vertex normals*, making polygonal planes look like bulbs. Setting `set_smooth_group(-1)` before adding vertices gives properly flat-shaded faces (Godot 4.5 documented behavior). This does not alter game meshes, the source voxel grids, or the subdivision level.
- **Pass 15** revised the actual proportions after looking at the corrected rendering: Atlas AC-20 shoulder/upper-arm separation and skull brow/optics, Wolverine narrower arm shields and shallow chest plates, Jenner smaller separated laser barrels and reduced front canopy glazing.
- The preview uses subtle **component identity colors only in the diagnostic renderer**. Source materials and gameplay colors are unchanged. Do not confuse these colors with model-detail work.
- Re-evaluate the latest one-image Godot screenshot; silhouettes are still **not approved** for 100–150k voxel refinement.


### Shape-only passes 16 and 17

- **16** — Atlas stock torso AC/20 shroud projected farther forward; Wolverine's forearm autocannon cradle lengthened, and its chest breastplates flattened; Jenner's four SRM-4 tubes reorganized as a horizontal, raised dorsal row per newer technical art.
- **17** — Wolverine lower limbs no longer share the Atlas's rounded armored-tube silhouette: hand-drawn six-faced taper on both thighs and calves, preserving knee/ankle joint gaps.
- All work remains at `subdivide:1`; no procedural detail pass, damage work, texture work, APK build, or merge.
- The latest single-gallery capture is *shape evidence*, not automatic approval. Atlas/Wolverine still require further front/side reference matching if the component silhouettes fail.


## Passes 18–20: multi-view component corrections

Review these **primary and secondary visual references** together, not just a single orthographic silhouette:

| Chassis | Front / facial / arm visual | Three-quarter / leg silhouette visual | Remaining approval criterion |
| --- | --- | --- | --- |
| Atlas AS7-D | [Syllogy Atlas miniature, frontal skull and torso](https://www.laserforgeminiatures.com/products/atlas-as7-d-mech) | [LizzyGibbs3D AS7-D CAD, alternate angle](https://www.deviantart.com/lizzygibbs3d/art/FAN-ART-BattleTech-MechWarrior-AS-7-D-Atlas-551614099) | Broad cowls frame the skull, cheek/jaw reads skull-like, projected RT AC/20 + LT rack, non-tubular arms |
| Wolverine WVR-6R | [SYZGames two-pose miniature](https://syzgames.com/products/wolverine-wvr-6r) | [AfterDark alternate WVR-6R view](https://afterdarkprints.net/products/wolverine-6r-alternate-battletech-model) | Sloping *narrower* pauldrons rather than Atlas bulk, six-port SRM at shoulder, long independent RA cannon, angular legs |
| Jenner JR7-D | [Mordel TRO illustrated JR7-D](https://mordel.net/tro.php?a=vtbm&id=188) | [CGL JR7-D miniature oblique view](https://www.ebay.com/itm/205033594352) | A long armored prow with inset glazing, compact paired side lasers, rear dorsal four-port rack, reverse-knee + aft hock legs |

- **18** — Atlas cheekbones/mandible sculpted independently and 100t scale separated from 55t Wolverine; Wolverine swept upper-arm pauldron roots; Jenner windshield reduced and physical hock offset increased. Compared with the single true Godot render: the overall scale improved, but barrel/arm shapes still differed.
- **19** — Eight-corner planar Atlas upper arms, roofed Wolverine shoulder plates and angled shin guards; Jenner's cockpit rebuilt as an aircraft wedge and the visor confined to the upper prow. One render, angled slightly more sideways to expose side-depth and leg hock.
- **20** — Atlas RT AC/20 has a compact 5×6 recessed opening mounted below the right shoulder; Wolverine RA AC/5 now extends as a separate forearm cannon. Both are real individually defined cells, not painted outlines; their front faces and positions are covered by low-resolution shape-regression tests.

**Open visual issues / next review**: the torso and legs must read as unique chassis from all angles and still need approval before 100–150k voxel detailing. Do not use the preview's component-identification color overlays as game materials. Keep one combined image per iteration, `subdivide:1`, no build or merge.

- **21** — The pass-20 Godot close-up showed an oversized Atlas AC/20 shroud crossing the chest. Corrected its silhouette into a short recessed 5×6 RT muzzle and updated the regression landmark. This is a shape correction made from the real render, not additional detailing.

## Passes 25–29 — CGL plastic first, reference hierarchy corrected

**Reference weighting:** use the current 1:265 Catalyst plastic miniature's sculpt as the primary target, even when it contradicts old TRO art, fan STL variants or a single screenshot. The older line art is secondary for weapon identity and hard-to-see joints. Do not derive the same common capsule-body profile for all three.

| Rank | Chassis | CGL plastic source / image | Mandatory silhouette evidence |
|---|---|---|---|
| 1 | AS7-D Atlas | [Catalyst Hansen's Roughriders official photo, reposed Atlas](https://store.catalystgamelabs.com/products/battletech-hansens-rough-riders-battle-lance) (see HR-Atlas-NewPose.jpg) | Rounded segmented shoulder bells; domed distinct *skull* with brow/cheek/jaw; compact two-column launcher cluster at left inner shoulder; short torso AC20; split blunt feet |
| 1 | WVR-6R Wolverine | [CGL Premium Wolverine assembled photo](https://store.catalystgamelabs.com/products/battletech-premium-miniature-wolverine) and CGL 2019 A Game of Armored Combat plastic | Armored mid-weight torso with short asymmetric shoulder caps, compact cockpit visor, independent right-arm cannon, six-port left shoulder launcher, narrow knee-to-ankle legs |
| 1 | JR7-D Jenner | [CGL Inner Sphere Striker Lance product](https://store.catalystgamelabs.com/products/battletech-forcepack-inner-sphere) and [actual plastic front/side photos](https://www.rpgminihunter.com.au/products/jenner-battletech-inner-sphere-striker-lance-set-catalyst-game-lab) | Compact **rounded** cockpit saucer and three window bands, central underbody, dorsal SRM pack, paired laser bores in each compact flank nacelle, long digitigrade knees and rear hock joints |
| 2 | Atlas / Wolverine / Jenner | Earlier TRO/artist drawings already in this document | Only for hidden surfaces / lineage, never to overrule a clear CGL plastic sculpt |
| 3 | Third-party resin and alternate sculpts | SYZGames, Defiance, other print shops | Supplemental pose and construction views only; cannot determine the canonical proportions |

### Recorded Godot review checkpoints
- **25:** rounded Atlas shoulder/upper cranium, smaller WVR shoulder roots, **replaced Jenner's overlong arrow nose** with the CGL broad saucer; genuine Godot one-gallery render. The Jenner glass was still too dominant.
- **26:** physical Atlas skull nasal ridge/jaw recess and WVR compact visor/rear pack; Jenner short bottom fairing and three-piece windshield; genuine Godot render showed the Atlas still had a protruding face and Jenner a too-dark cockpit.
- **27:** six visible double-column Atlas launcher apertures, slimmer WVR arm AC5, framed paired Jenner laser sockets; CI caught that the Jenner bores were accidentally **filled**, so an actual erase was added to all four muzzle pieces, not just dark geometry.
- **28:** Atlas split toe boot blocks and Wolverine wedge feet/knee plates vs Jenner extended digitigrade knee and hock shells; Godot render checked leg silhouette separation.
- **29:** refined Atlas mandible to recede flush below skull, narrowed WVR upper-arm plates so they do not resemble assault-mech shoulders, restricted Jenner glazing to a slim windscreen strip and roof pane after Godot 28 comparison.

The existing `subdivide:1` requirement and 100–150k voxel **deferral** remain intact. No APK built, no merge. One Godot render per checkpoint. Shapes are **not automatically approved** by the completion of these five passes.

## CGL plastic-led cycles 30–37 (eight new shape passes)

Reference priority: current Catalyst plastic miniature photos, including front and side/rear, outweigh earlier technical art, third-party resin or fan interpretations. Multiple angles are mandatory for each silhouette. No Gothic Atlas variant substitutions.

| Chassis | Primary reference | Second angle / alternate current plastic |
| --- | --- | --- |
| Atlas AS7-D | [CGL Hansen's Roughriders official plastic photo](https://store.catalystgamelabs.com/products/battletech-hansens-rough-riders-battle-lance) | [Independent frontal unpainted Atlas photo](https://www.ebay.com/itm/404166265786), [Sarna verified photo](https://www.sarna.net/wiki/File:Hansen%27s_Roughriders_Battle_Lance_Atlas.jpg) |
| Wolverine WVR-6R | [CGL 2019 AGOAC/Beginner plastic](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs) | [Official CGL premium Wolverine alternate view and parts](https://store.catalystgamelabs.com/products/battletech-premium-miniature-wolverine), [CGL plastic miniature paint photo](https://mechpainters.org/miniature/wolverine-clan-wolverine/) |
| Jenner JR7-D | [CGL Striker Lance bare plastic, FRONT and SIDE](https://www.rpgminihunter.com.au/products/jenner-battletech-inner-sphere-striker-lance-set-catalyst-game-lab) | [Multiple other angles of the same CGL Striker Lance plastic](https://jadedfalconer.com/Pages/1Light/jenner) |

### Eight completed geometry passes

30. Atlas: independently shaped left/right split chest plates; reduce inflated shoulder-cowl edge.
31. Jenner: reduce oversized flank laser nacelles, rebuild physically underslung belly apron absent from prior model.
32. Wolverine: shorten/drop inflated pauldron contours and add separate shoulder yoke joints beneath shield.
33. Atlas: physically construct a double-column five-row missile rack with ten open apertures and aligned launch positions, not just dark mouth decals.
34. Wolverine: reshape forearm and thighs into narrower tapering geometry distinct from Atlas.
35. Jenner: replace swollen duck-like cockpit with shorter stepped eight-sided nose, actual narrow windscreen, revised chin.
36. Atlas and Wolverine: slim Atlas gauntlet/knuckle shapes, and correct oversized Wolverine right forearm AC5 shroud.
37. Jenner: add real bilateral aft engine exhaust frames with twin air channels, connected to existing rear drive modules.

Audit focus: bloating (pauldrons, gauntlets, nacelles), gaps (Wolverine exposed shoulder yokes; Jenner belly/hocks), missing sculpt features (Atlas rack mouths, Jenner rear exhaust, Atlas split chest), and weapon opening occupancy. Godot surface preview does not show erase cuts; validate actual generated voxel cells at the muzzle coordinates.

CGL photos have priority over old TRO art and fan resin. Keep only a few combined in-engine renders for review, no automated multi-angle image batches. Retain subdivide = 1 and keep all three models unapproved for high-density detailing, unmerged, no APK.

## Plastic-first refinement 38–47 — ten committed geometry passes

Each pass above is a separate committed adjustment to the actual authored section geometry, not a generated concept illustration. Keep Catalyst Game Labs' *released plastic* miniature as the primary silhouette source, weighted above earlier TRO drawings or non-CGL fan/resin sculpts; reference photographs are examined from front and from three-quarter/side/rear. These are shape-only studies, not detailed voxel builds.

| Miniature | Front / three-quarter primary | Side / back secondary | Proportions checked |
| --- | --- | --- | --- |
| Atlas AS7-D | [Hansen's Roughriders actual CGL grey plastic](https://meeplescorner.co.uk/uk/products/battletech-hansens-roughriders-battle-lance) | [CGL Battle Lance multi-miniature product photo](https://kryptonitekollectibles.com/products/battletech-hansens-roughriders-battle-lance) | Skull recessed between shoulder bell armor, low jaw and eyes, split torso/hips, distinct elbow/hand gauntlets, squared boots |
| Wolverine WVR-6R | [2019 CGL Beginner/AGOAC sculpt verified in CGL miniatures catalog](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs) | [Painted plastic WVR-6R views](https://mechpainters.org/miniature/wolverine-clan-wolverine/), [Camo Specs multiple views](https://camospecs.com/listing/wolverine-wvr-6r/) | Compact cockpit, narrow upper shoulders, left SRM rack, right forearm AC5, functional elbow, leaner limbs than Atlas |
| Jenner JR7-D | [CGL Striker Lance grey plastic front and angled shots](https://www.rpgminihunter.com.au/products/jenner-battletech-inner-sphere-striker-lance-set-catalyst-game-lab) | [Additional CGL three-quarter/side angle](https://www.atomicempire.com/Item/303370), [photographs of CGL plastic miniature](https://jadedfalconer.com/Pages/1Light/jenner) | Cockpit prow, square short twin laser pods, elevated SRM rack, stepped reverse knee and rear hock, connected waist/leg mechanics |

| Pass | Shape modifications | Reject / audit criterion |
| --- | --- | --- |
| 38 | Atlas skull front planes and jaw shortened; independent neck collar | Oversized cartoon-face mask, floating neck |
| 39 | Wolverine pauldrons narrowed and shoulder yokes overlapped | Swollen shoulders and exposed detached joints |
| 40 | Jenner rearward shin bend and tapered tarsus | Human straight-leg silhouette |
| 41 | Atlas squared bevelled upper arm shield, tighter elbow linkage | Round inflated upper-arm bulbs |
| 42 | Wolverine side torso root carved narrower beneath arms | Torso wide as Atlas, excessive armor overlap |
| 43 | Jenner paired laser housings and wing shoulder shell compacted | Huge square side cannons or disconnected wing |
| 44 | Atlas boot soles shortened; left/right ankle collars added | Long ski-shaped feet, ankle gaps |
| 45 | Wolverine SRM-6 rebuilt as compact 2×3 hollow launcher | Missile block larger than helmet or obstructed holes |
| 46 | Jenner knee cowl and aft hock made as separate slim pieces | Bulging joint covers masking digitigrade silhouette |
| 47 | Atlas hip-to-pelvis sockets; Wolverine AC5 elbow link; Jenner both hip attachments | Missing connection between torso/limbs, floating arms and legs |

Checkpoints: a single true in-engine combined gallery at pass 40 and another at pass 46; final pass 47 also produces one combined review artifact. No image-generation reconstructions. Geometry changes remain at subdivide=1, with no high-density 100–150k refinement before approval. Tests check open physical missile mouths, cockpit/weapon landmarks, independent low-resolution hip, shoulder and elbow parts. These photos show mostly forward/oblique faces; the final render is not sufficient evidence to approve all rear mechanical details.

**Known residual mismatch:** this shape renderer still has stylized component simplification; upper torso and legs need closer fit to the current plastic silhouettes, especially Atlas's skull face and Wolverine's shoulder profile, before detail work. Passing Godot CI is a technical gate, not a visual match assessment.

## Actual shape refinements 48–57 — Catalyst plastic, three-angle audit

The reference hierarchy remains CGL **released plastic sculpts first**, front and side/rear where photographed; current premium CGL images inform Wolverine joint construction, older TRO art only the secondary weapon identity. These are **ten committed changes to geometry**, not procedural voxel upscaling.

- Atlas 2023 reposed AS7-D: [CGL official frontal plastic photo](https://store.catalystgamelabs.com/products/battletech-hansens-rough-riders-battle-lance), [Camo Specs Hansen plastic](https://camospecs.com/listing/atlas-as7-d-53/).
- Wolverine WVR-6R: [CGL premium assembled front and oblique photo](https://store.catalystgamelabs.com/products/battletech-premium-miniature-wolverine), [MPU A Game of Armored Combat CGL painted miniature](https://mechpainters.org/miniature/wolverine-lyran-royal-guards/), [Camo Specs plastic](https://camospecs.com/listing/wolverine-wvr-6r-10/).
- Jenner JR7-D: [CGL Inner Sphere Striker Lance grey plastic](https://www.rpgminihunter.com.au/products/jenner-battletech-inner-sphere-striker-lance-set-catalyst-game-lab), [MPU JR7-D plastic](https://mechpainters.org/miniature/jenner-draconis-combine-3rd-sword-of-light/).

| Pass | Physical silhouette change | Reason for correction |
| --- | --- | --- |
| 48 | Atlas skull crown, shortened jaw, compact cheek/eye contours | Cartoon head and protruding mask |
| 49 | Wolverine outer side-torso and both shoulder armor cross sections narrowed, chest plates flattened | Shoulder/torso bulk approaching Atlas |
| 50 | Jenner calf sections sweep more rearward to a joined, extended tarsus | Reverse-knee angle hidden in three-quarter |
| 51 | Atlas central chest ribs widened under cowls and shallow tapered waist plate added | Floating shoulder/breastplate visual gap |
| 52 | Wolverine upper-arm volume narrowed, elbows and thigh armor tapered | Large rectangular arms and Atlas-like legs |
| 53 | Jenner twin laser nacelle shells compacted and separate chin slimmed | Pod and prow bloating |
| 54 | Atlas knee armor squared and lower shin facing elongated | Bulbous kneecaps that hide straight assault-mech lower legs |
| 55 | Wolverine rear jump-jet housings individually built and mounted to rear torso | Single featureless central backpack on back view |
| 56 | Jenner knee cowl slimmed and physical aft hock braces added to both legs | Gaps in back-facing hock linkage |
| 57 | Wolverine cannon arm bridged diagonally to its separate AC/5 housing | Real side-view inspection exposed a floating right-arm gun |

**Important diagnostic discovery:** The existing front-only gallery concealed a striking gap between Wolverine's right-arm cannon and upper forearm. Added front, side and rear three-quarter Godot review passes; compose these into **one user-facing multi-angle image**, not dozens of images. Cell-contact tests now require the diagonal bridge to intersect both the arm and shroud, rather than merely appearing nearby.

This project remains at the shape gate, with `subdivide=1` and no 100–150k voxel detailing. Passing Godot import and unit tests is only a technical gate; CGL sculpt resemblance must still be approved. Do not merge PR #102 or build an APK without instruction.

## Catalyst plastic reference refinement — cycles 48–57

The three sculpts here are still **low-resolution component-shape studies** with subdivision 1. The requested 100–150k visual detail work is *not* authorized until they pass the silhouette review.

### Reference hierarchy and views

1. **Primary: currently released CGL plastic**, especially the [2023 Hansen's Roughriders Atlas grey miniature front](https://store.catalystgamelabs.com/products/battletech-hansens-rough-riders-battle-lance), [2019 CGL Wolverine WVR-6R Beginner/AGOAC plastic](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs), and [Striker Lance Jenner JR7-D grey sculpt](https://www.sarna.net/wiki/BattleTech_Inner_Sphere_Striker_Lance). Prioritize actual arm/head/calf arrangement over old TRO outlines.
2. **Secondary CGL alternate views:** [official Wolverine Premium, assembled and unassembled views](https://store.catalystgamelabs.com/products/battletech-premium-miniature-wolverine), [2023 Atlas grey minis front photo](https://kryptonitekollectibles.com/products/battletech-hansens-roughriders-battle-lance), [2021 Jenner product photograph](https://www.ebay.com/itm/403292195264), plus [Jenner painted CGL miniature multiple views](https://jadedfalconer.com/Pages/1Light/jenner).
3. Older TRO images, player 3-D printed third-party reinterpretations: supplemental only; reject variants or redesigns inconsistent with the above plastic forms.

Each inspection covers front three-quarter, individual profile and rear three-quarter **inside one combined Godot review image**. The renderer rotates each mech in place for side/rear to avoid accidental overlap of the three mechs along the gallery X-axis. Images show low-saturation part-category colors; these are *not* game materials. GDScript renderer may show covered-over erase voids poorly, so rasterized cell tests still check the launcher mouths.

### Ten reference-driven geometry passes

| Pass | Chassis | Core form fix | Defect targeted |
| --- | --- | --- | --- |
| 48 | Atlas | Smaller skull brow/jaw/cheek outline | Giant projecting head, bulging Death's Head |
| 49 | Wolverine | Narrower CGL-style pauldrons, less bloated twin breastplates | Oversized generic shoulders |
| 50 | Jenner | More physical rearward hock and pitched lower leg section | Straight-leg silhouette / obscured digitigrade |
| 51 | Atlas | Lower central abdomen, narrower hip silhouette with central cod guard | Empty waist and detached hips |
| 52 | Wolverine | Shallow paired angled armor and a central recessed chest keel; independently narrow arm roots | Inflated chest and shoulder-to-torso gap |
| 53 | Jenner | Compact lateral twin-laser wing roots, shorter stepped cockpit/chin | Duck-like face and oversized fighter nose |
| 54 | Atlas | Smaller angular knee cover, squarer narrow shins | Balloon knees and generic leg pillars |
| 55 | Wolverine | Two structural rear jet/exhaust modules paired with backpack | Missing aft machinery seen from rear |
| 56 | Jenner | Narrow knee cowl with rear hock piston/brace | Bloated knee covering true reverse joint |
| 57 | Wolverine | Tapered diagonal **physical** AC/5 breech-to-upper-arm assembly | Cannon housing floating separately in side view |

**Remaining issues at this stage**: compare final multi-angle screenshot before declaring any model approved. The Atlas still needs accurate head-to-cowl negative space and lower-leg articulation; Wolverine's torso/pauldrons need precise plastic-sculpt silhouette; Jenner's feet and hock are simplified relative to the sculpt. Do not confuse automated Godot pass/fail with visual approval.

**Regression checks** after pass 57: physical atlas codpiece cells, the Wolverine AC/5 mount reaching both arm and barrel, independent rear jump-exhaust parts, and Jenner rear-hock braces, in addition to existing missing-part and empty weapon-port tests. No merge, no APK, no density/detail increase.

## Plastic-weighted reconstruction passes 58–77

**Primary reference weighting:** approximately 70% to Catalyst's exact current released plastic for the selected variant, particularly [Hansen's Roughriders 2023 reposed Atlas](https://store.catalystgamelabs.com/products/battletech-hansens-rough-riders-battle-lance), [A Game of Armored Combat Wolverine WVR-6R grey plastic](https://highlanderhobbies.com/products/wolverine-miniature-a-game-of-armored-combat-box-battletech), and [Inner Sphere Striker Lance Jenner JR7-D plastic](https://www.sarna.net/wiki/File%3AInner_Sphere_Striker_Lance_-_Jenner.jpg). Another ~20% goes to alternate-angle photos of *the same* CGL sculpts ([Wolverine painted sculpt](https://mechpainters.org/miniature/wolverine-clan-wolverine/), [Jenner painted plastic](https://mechpainters.org/miniature/jenner-tandrek-stables/), and [Atlas frontal stock grey photo](https://store.catalystgamelabs.com/cdn/shop/files/HR-Atlas-NewPose.jpg)). Prior TRO drawings and other sculpt interpretations serve as 10% secondary evidence of weapon identity and hidden surfaces only. **Never confuse aftermarket resin or the 2019/2023 poses.**

**Review method:** one actual Godot contact-sheet image combining front three-quarter, left side, and rear three-quarter views of all three models at each grouped checkpoint. Repeat the process after a group of real geometry edits rather than requesting a separate image per pass. Shape-preview materials separate armor components diagnostically; they are not final colors. Voxel-cell tests are the authority on physically open weapon mouths and touching structural bridges, since the preview's visual proxy ignores some erase operations.

| Pass | Chassis | Actual geometry change | Rejected failure mode |
| --- | --- | --- | --- |
| 58 | Atlas | Skull cheekbones and lower mandible converge beneath eyes | Inflated humanoid mask |
| 59 | Wolverine | Sloped, shorter pauldron shells reveal inner shoulder roots | Rounded Atlas-scale shoulders |
| 60 | Jenner | Lower compact cockpit saucer with narrower three-panel window | Bulbous nose and oversized visor |
| 61 | Atlas | Separate low square knee cover and vertical shin plate | Tree-trunk calf, balloon knee |
| 62 | Wolverine | Narrow wedge boots and shin fairing | Same assault-sized legs as Atlas |
| 63 | Atlas | Tighter main shoulder-cowl margins plus physically separate crest ridges | Single undifferentiated giant shoulder dome |
| 64 | Wolverine | Shorter rear backpack and narrow lower reactor attachment spine | Tall blank rear torso, disconnected backpack |
| 65 | Jenner | Physically shift both laser housings, all four muzzles and bores inward | Winglike inflated twin side pods and orphaned bores |
| 66 | Atlas | Lower skull crown and narrow upper cranial bevel | Dome too high, cartoon forehead |
| 67 | Wolverine | Taper upper leg and narrower knee/shin sections | Uniform heavy-robot thigh/calf |
| 68 | Jenner | Shorten three separate toes, reduce sole front | Overlong ski/ostrich feet |
| 69 | Atlas | Left/right paired rear reactor shields joined to central torso | Featureless back |
| 70 | Wolverine | Physically hollow paired aft jump exhausts and inset backs | Rear jets depicted as flat sealed caps |
| 71 | Atlas | Shorten boot core under projected split toe blocks | Single long assault ski foot |
| 72 | Jenner | Central tapered rear reactor spine linking engine deck | Blank central rear / detached engine housings |
| 73 | Wolverine | Cut forearm AC5 armor into a narrower taper while keeping physical breech overlap | Solid rectangular toy bazooka and floating gun |
| 74 | Atlas | Separate mirrored rear hip actuator shields with pelvic contact | Missing rear hips / blank rear thighs |
| 75 | Jenner | Mirrored slender front ankle links bridging lower calf and toes | Missing actuator in digitigrade leg |
| 76 | Atlas | Raised separate left/right skull-brow cowls over inset eye geometry | Unrecognizable blank pink face |
| 77 | Jenner | Lower top of four-port dorsal SRM cassette without filling its bores | Tall square roof launcher |

**Structural and visual audits:** use all three views for bulky armor, disconnected thighs/arms/hocks and absent equipment, but require rasterized occupied-cell checks for bores. Preserve separately authored head, hips, forward/rear leg mechanics, split toes and weapon housings, along with 1 subdivision. The rear Atlas radiator and Wolverine jump nozzles must remain modest so they do not create new rear armor bloat. No merge, APK, or 100–150k high-density step until silhouette approval.

**Known visual shortcomings despite these passes:** Atlas still needs its plastic skull/shoulder/torso proportions matched more precisely; Wolverine's arm and shoulder proportions remain simplified relative to CGL; Jenner's foot, nose and hock mechanics still need further study. A successful Godot import, contact-sheet generation and tests are necessary technical checks, not the definition of faithful visual likeness.

## Plastic-led passes 78–97 and five-view evidence

**Target:** replicate the most recent relevant Catalyst Game Labs plastic miniature geometry, not third-party resin or old technical readouts. Use multiple views: front 3/4, true head-on, side, rear 3/4, and **top-down**. The single review gallery at `tools/capture_component_shapes.gd` now captures all five; rotating each chassis in place preserves non-overlapping comparison positions. Read the five rows in that order.

Primary plastic sources: [Hansen's Roughriders Atlas official grey photo](https://store.catalystgamelabs.com/products/battletech-hansens-rough-riders-battle-lance); [2019 CGL Beginner/AGOAC Wolverine plastic](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs), [painted AGOAC WVR-6R photo](https://mechpainters.org/miniature/wolverine-lyran-royal-guards/); [2021 CGL Striker Lance Jenner grey sculpt](https://www.rpgminihunter.com.au/products/jenner-battletech-inner-sphere-striker-lance-set-catalyst-game-lab), [painted 2021 CGL Jenner](https://mechpainters.org/miniature/jenner-tandrek-stables/). Official CGL plastics carry higher weight than aftermarket sculpts.

| Pass | Shape corrections | Specific failure addressed |
| --- | --- | --- |
| 78 | Wolverine: remove independent hanging right fist/second forearm; one AC/5-bearing arm | **Two right arms** |
| 79 | Wolverine: connect barrel sleeve and elbow to single upper arm | Gun shell visually detached or doubled |
| 80 | Atlas: tighten oversized crown, cheeks and jaw | Cartoonish skull |
| 81 | Jenner: reduce oversized lateral engine/laser-root armor | Wide boxy wings |
| 82 | Atlas: reduce shoulder-bell top footprint | Enormous top-down cowls |
| 83 | Jenner: shorten and taper nose; sculpt compact top-view pod-root decks | Fighter-like long beak; abrupt wings |
| 84 | Atlas: split V breast armor; Wolverine: trim pauldrons | Generic flat chest and overwide shoulders |
| 85 | Wolverine: raise narrow arm-root distinction; Atlas: recess jaw | Generic mirrored shoulders and protruding face |
| 86 | Jenner: taper femurs and rear hocks into reverse-jointed legs | Thick humanoid thigh/calf |
| 87 | Atlas: compact articulated pelvis and thigh roots | Swollen abdomen and hip block |
| 88 | Atlas: bevel outer bell rear underside and front lip | Featureless shoulder blocks |
| 89 | Jenner: chamfer engine/pod roots and thin roof plates | Flat rectangular sidepods |
| 90 | Wolverine: narrow right torso cowl, distinct from AC/5-bearing arm | Duplicate-looking stacked right forms |
| 91 | Atlas: move mandible under orbital ridge | Skull mask extending too far forward |
| 92 | Jenner: narrow tarsus/rear lower leg while retaining physical joints | Bulky bird leg and disconnected hock |
| 93 | Wolverine: keep singular joined diagonal AC/5 mount | Second arm regression |
| 94 | Atlas: facet forearms and wrist into heavy rectangular gauntlet | Cylindrical forearm bulge |
| 95 | Jenner: two **physical** compact weapon-pod root yokes | Floating laser pods |
| 96 | Wolverine: taper knee and separate shin fairing | Atlas-like tree-trunk lower legs |
| 97 | Atlas: taper lower cheek, narrow upper skull beneath separated orbital brow | Helmet-like skull front |

**Regression controls:** source geometry guard in `tests/unit/test_component_shape_studies.gd` asserts exactly one forward right-forearm profile on the Wolverine, no independent fist boxes, one AC/5 muzzle, physically connected breech and shoulder, independent Jenner bores and Atlas missile openings. Never approve by preview image alone: `VxShapePreview` does not display all erase cuts and true voxel occupancy still matters.

**Open:** despite meaningful improvement, all three remain shape-stage simplifications, not approved sculpt matches. Atlas skull and giant shoulder proportions, Wolverine's torso/weapon interface, and Jenner's cockpit/foot mechanics should be compared quantitatively against the plastic from full front/top/side/rear before 100–150k voxel detail work. Preserve `subdivide:1`, do not merge or build an APK without request.

## CGL plastic geometry cycles 78–97: five-view construction audit

The review now includes five orientations of all three chassis **in one PNG**, in this order: 3/4 front, **straight front**, side, rear 3/4, and **straight top-down**. The top-down camera uses a custom +Z up vector so it does not collapse when pointing straight down. The models rotate in place for each angle; they never stack over one another. These are true Godot voxel-model component renders, not generated artwork.

**Primary sculpt sources and angle priorities:** [CGL reposed Hansen's Roughriders Atlas](https://store.catalystgamelabs.com/products/battletech-hansens-rough-riders-battle-lance) for front and overhead shoulder/skull shapes; [CGL 2019 Wolverine WVR-6R plastic (AGOAC / original Beginner Box)](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs) and [painted actual CGL Wolverine](https://mechpainters.org/miniature/wolverine-clan-wolverine/) for separate right-arm AC5 and left fist; [CGL Inner Sphere Striker Lance Jenner](https://www.sarna.net/wiki/BattleTech_Inner_Sphere_Striker_Lance) and [painted actual CGL plastic Jenner](https://mechpainters.org/miniature/jenner-tandrek-stables/) for blunt cockpit, separate side laser nacelles, compact hip pads, and birdlike tarsus. Treat fan STL alternate sculpts as secondary, and prioritize the released plastic when they contradict each other.

| Pass | Chassis | Shape correction / construction finding |
| --- | --- | --- |
| 78 | Wolverine | **Physically remove the extra dangling RA fist**. One right forearm now terminates in the AC5; retain the connecting armature. |
| 79 | Wolverine | Integrate cannon collar, elbow and housing into one visual mechanical arm with a recessed single muzzle. |
| 80 | Atlas | Flatten upper skull dome and narrow its upper brow/cranial contour. |
| 81 | Jenner | Compress lateral laser-mount armor while retaining physical four laser bores. |
| 82 | Atlas | Reduce inflated X/Z footprint of shoulder tops, visible from overhead. |
| 83 | Jenner | Shorten the armored nose, glazing and chin as a coordinated assembly; adjust nose landmark test. |
| 84 | Wolverine / Atlas | Narrow shoulder/pauldron forms and strengthen distinct angular assault chest contours. |
| 85 | Atlas / Wolverine | Pull projecting Atlas jaw/nasal elements back, and slim Wolverine front shoulder armor without losing arm joints. |
| 86 | Jenner | Narrow thigh/calf hock transitions, maintain contact through both tarsi. |
| 87 | Atlas | Taper waist/upper-thigh assemblies without damaging pelvis-to-leg joints. |
| 88 | Atlas | Chamfer both forward and aft shoulder-cowl lips instead of flat boxes. |
| 89 | Jenner | Replace broad side-wing roots with chamfered short nacelle bases, maintaining barrel positions. |
| 90 | Wolverine | Thin right torso shoulder shell beside single AC5 arm. |
| 91 | Atlas | Recess the lower jaw under the skull's raised cheek and orbital plate. |
| 92 | Jenner | Reduce rear tarsus and center toe bulk, preserve birdlike leg articulation. |
| 93 | Wolverine | Reduce overhead single AC5 breech footprint without adding another parallel arm. |
| 94 | Atlas | Rebuild bulky forearm gauntlet into a chamfered mechanical form, less cylindrical. |
| 95 | Jenner | Physically bridge bilateral laser pods to central hull with small yokes. |
| 96 | Wolverine | Sharper knee-to-shin discontinuity rather than generic Atlas-thickness legs. |
| 97 | Atlas | Taper skull cheek / upper cranium under raised orbital brow. |

**New regression gate:** `test_wolverine_single_right_arm_geometry_not_two_right_fists` verifies there is only one forward right forearm in the authored geometry, no lower right fist boxes, and exactly one AC5 muzzle. Older weapon-opening and true occupied-cell overlap checks remain mandatory. Do not use the *visual* coincidence of angled meshes as proof of physical attachment.

**Approval remains withheld.** The five-angle geometry review reduces blind spots but does not establish perfect CGL plastic matching. Keep subdivision at 1, no high-density 100–150k voxel build, no APK build and no branch merge.
