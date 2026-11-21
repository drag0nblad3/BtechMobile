# Shape Refinement 11 — passes 178–197

Compare against Catalyst Game Labs 2023 Hansen's Roughriders Atlas, Premium / AGoAC Wolverine, Inner Sphere Striker Lance Jenner. Review subpart silhouette AND ratios of neighboring parts, joint connection angles and negative space. Wolverine **ONE** RIGHT shoulder→upper arm→elbow→forward gun/hand; no hanging second right forearm. Shape stage only `subdivide:1`, no APK or merge.

## Passes 178–182

| Pass | Atlas | Wolverine | Jenner |
|---|---|---|---|
|178|Recess complete Atlas skull/nose/jaw 2 voxels deeper in chest instead of forward mask.|Re-angle Wolverine paired chest plates and reduce the outer raised launcher-side shoulder.|Pitch Jenner front disc lower under nacelles; keep separate cockpit roof.|
|179|Recut Atlas breastplates into angular V supporting sunken skull.|Taper Wolverine right shoulder wing and rotate mass back toward cannon elbow.|Slim Jenner disc rim and raise distinct glazed crown above perimeter.|
|180|Sweep Atlas lower cuffs/gauntlets forward relative to shoulder sockets without moving wrists off fists.|Inset Wolverine elbow diagonal and add mechanical hinge linking ONE bent cannon/hand arm.|Draw Jenner side pod roots outward from disc to expose connecting yoke negative space.|
|181|Narrow Atlas knee/thigh armor and sharpen greave joins against large torso.|Broaden Wolverine hip cage relative to V chest, reduce center abdominal bloating.|Shift Jenner thigh knee/hip axes inward and make two-bend digitigrade silhouette less straight.|
|182|Add separate Atlas root bushing below right round shoulder where the AC20 shroud connects, trimming disconnected collar.|Re-angle Wolverine shoulder upper arm so elbow sits immediately behind horizontal AC5/gripping hand.|Rebuild Jenner disc-to-torso neck brace into pitched contiguous undercarriage instead of beam.|

First five coordinated passes substantially re-seat Atlas head in 3D chest, reshape V-armor and shoulder AC20 connection, Wolverine shoulder/torso and elbow hinge (without duplicating right arm), Jenner disc pitch and lower neck, side-pod and hip attachments. Source loft ordering/voxel integer validity checked before push; Godot five-view review must follow.


## Passes 183–187 — absolute component proportions and angular joins

The intermediate pass-182 five-angle review still showed Atlas's broad orange face and globe shoulders, Wolverine chest bib, and a Jenner disc aligned with the pod line rather than hanging below it. All linked parts were adjusted together instead of moving only the outer shell.

| Pass | Atlas | Wolverine | Jenner |
|---|---|---|---|
|183|Shrink full Atlas skull and cheek/brow assembly together so it fits between compact round shoulder bells.|Replace Wolverine chest bib with two angled, distinct breast armor planes around narrow head and broad waist.|Lower entire Jenner disc/cockpit/rim two voxels under its laser pods, carrying all accessories, windows and braces along.|
|184|Build Atlas shorter angled wrist cuffs and true clenched hand connection below shoulder rotators.|Resculpt Wolverine cannon-side bent elbow with compact bearing behind gripping hand, no second lower arm.|Replace Jenner boxy side laser pod housings with tapered eight-vertex fore-aft shapes.|
|185|Reduce Atlas shoulder extreme width while keeping near-level crests above recessed skull.|Reshape Wolverine lower ribcage to wider triangular bridge rather than a pinched belt.|Expand circular Jenner disc at its widest middle sections to full 20-unit diameter without thickening it.|
|186|New coupled Atlas knee-to-shin yoke so greaves taper from fuller thighs and stop resembling straight blocks.|Add Wolverine upper-thigh tapered knee armor to balance broad torso and gun-arm load.|Re-angle Jenner reverse knees and shins for recognizable two-bend side silhouette.|
|187|Connect narrowed Atlas skull to chest with separate lowered angular brow bridge rather than protruding orange mask.|Add compact Wolverine missile rack inner mounting brace beside angular helmet, retain open 2×3 ports.|Build Jenner lower circular disc rim so lowered saucer is visibly separate from upper reactor and pods.|

Atlas head assembly narrowed as a group; new knee yokes. Wolverine triangular breast armor and paired tapered thigh cuffs; hand still grips ONE right cannon arm. Jenner head lowered two whole voxels including glass/struts, side pods rebuilt with tapered octagonal sections and low saucer underlip. Original weapon ports retained. No high density, APK or merge.


## Passes 188–192: user's Atlas depth critique

Pass-187 Godot side/top views show Atlas too thick and volumetric in z (front/back), despite reasonable head and shoulder width. We reduced **whole connected Atlas systems** without changing x/y: CT/pelvis/pectoral housing z scale ~70%; LT/RT shoulder shells/bands/rotator/cradle ~65–77%; HD entire skull/eyes/neck compressed around z−10 ~75%; rear radiator z scale ~64%; arms, gauntlets and hands ~78%. Keep weapon muzzles in place; never add density. The old Jenner y28 forward nose assertions were stale after pass-183 lowering; changed to y26 at same z=-36 nose projection. Relational Godot render/CI checks next.

| Pass | Atlas | Wolverine | Jenner |
|---|---|---|---|
|188|Cut Atlas main CT/abdomen/hip/breastplate depth by ~30%, leaving shoulders width/height untouched.|Add slanted structural Wolverine keel-to-pelvis V brace instead of disconnected oval bib.|Add low Jenner windshield brow on lower forward saucer.|
|189|Shallow Atlas both shoulder bells, caps, underplates, ridges and cradle while preserving LRM/AC20 mouths.|Trim Wolverine right wing shoulder cap to expose bent gun/hand elbow connection.|Taper Jenner disc back saddle to shorter neck under lowered canopy.|
|190|Compress whole Atlas skull, cheeks, nose, jaw and eye sockets front-to-back about 25%, keeping face beneath shoulder crowns.|Raise Wolverine bent elbow pivot at back of single cannon-bearing forearm, leaving hand on AC5.|Further round Jenner middle disc plan to broad flattened saucer ahead of two laser pods.|
|191|Shorten Atlas rear radiator housings about one third; remove huge top/rear overhang.|Taper Wolverine back jump pack armor to a smaller rear silhouette.|Re-angle Jenner left laser-pod side truss toward mid-fuselage.|
|192|Compress Atlas forearm/gauntlet and hands in depth to match shallower shoulder and chest mass; never reduce width of fists.|Resculpt Wolverine right elbow shield around single arm/hand/gun silhouette.|Advance Jenner hock shin pivot to stand under lower forward disc.|

Atlas measured z bounds after these passes: CT -5..6, LT shoulder -8..6, skull -16..2, rear radiator 4..7. All three models changed on each of five passes. No APK or merge.


## Passes 193–197: follow-up to major Atlas depth reduction

The actual pass-192 Godot side and top-down render shows a clearly shallower Atlas (right direction). Remaining geometry refinements soften giant domes and upper back, preserve properly seated head, shape gauntlets to match shallow chest and improve knee/leg ratios. CI after pass 192 surfaced a *stale* Atlas codpiece voxel test (moved from z−8 to z−6 by torso compression) and an actual disc width overshoot in Jenner (radius 11). We retained codpiece source geometry and updated its expected location, and **reduced Jenner disc source radius to 10** rather than weakening width tests. Wolverine hand remains on ONE bent right AC5-carrying arm.

| Pass | Atlas | Wolverine | Jenner |
|---|---|---|---|
|193|Reduce the Atlas upper back/CT shoulder-overlap depth another voxel while keeping skull centered and breastplates angled.|Strengthen the bend of Wolverine's single right gun arm immediately behind its gripping hand.|Correct Jenner disc diameter from too-wide 22 units to 20 units, preserving its forward projection and separate pods.|
|194|Thin and round the front/back ends of both Atlas shoulder bells, further reducing bulky dome appearance.|Reprofile Wolverine's paired chest plates toward a narrow angular helmet and broader mid torso.|Flatten Jenner main disc middle layer by about two voxels while keeping glazed cockpit above it.|
|195|Move Atlas fist knuckles slightly aft in z to fit slimmer wrist cuff rather than bulky protruding hand slabs.|Build Wolverine compact wrist-to-gun collar linking the ONE right palm to its forward AC5 forearm.|Raise Jenner under-saucer rim lower surface so disc reads thin in side view, not thick beak.|
|196|Shorten Atlas compact rear radiator housing another unit, aligning it with the now shallower round shoulders.|Resculpt Wolverine dorsal jump pack's side bevel, matching torso depth and hand/gun pose.|Increase Jenner forward hock bend beneath lowered round cockpit to restore digitigrade posture.|
|197|Fit Atlas knees and shins to smaller torso mass with narrower greaves, preserving tall load-bearing stance.|Finish Wolverine one bent right arm with visible elbow pin, hand wrapped around same AC5, not another lower forearm.|Finish Jenner angled rear disc saddle and toe proportions beneath centered side-pod hull.|

20 passes complete (178–197), 60 model-level changes across three chassis. Shape stage remains subdivide=1; no APK, no merge. Final five-angle Godot render and technical tests required; artistic likeness remains under review.
