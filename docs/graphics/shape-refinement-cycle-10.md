# Shape refinement passes 158–177 — reference-led assembly review

Catalyst plastic sculpts are the target. Use the actual Godot five-angle contact sheet (front three-quarter, head-on, side, rear three-quarter and top) to compare each subpart and, most critically, **how it attaches to its neighbors**. The user's first priority is one Wolverine bent RIGHT arm with the hand gripping the AC5. Never reproduce a separate vertical dangling right hand, even if the individual parts look plausible.

## Passes 158–162 — remove duplicate arm silhouette

| Pass | Atlas | Wolverine | Jenner |
|---|---|---|---|
|158|Resculpt Atlas asymmetric torso into fuller ribcage below tucked skull and shorter round shoulder shells; integrate arm sockets at equal height.|REMOVE old right dangling y-axis lower-arm loft and sculpt ONE bent upper arm -> elbow -> forward AC5 forearm with weapon gripping hand behind barrel.|Cut down Jenner broad top slab and pitch leading disc lip down 2 voxels, rejoining its support neck to the forward saucer.|
|159|Taper Atlas shoulders from chest and shrink both outer shoulder ridges, retaining balanced rounded heights around skull.|Move Wolverine right-hand thumb and finger pads up to grip top/back of same AC5, narrowing the visible gap between knuckles and weapon housing.|Recast Jenner forward disc rim from rectangular flattened tip into 9-sided oval planform and round pod-to-disc leading joins.|
|160|Cut away Atlas excessive forearm armor corner mass while making fist-to-wrist linkage explicit and symmetric.|Reshape Wolverine left upper arm to match a walking-ready pose and tilt RIGHT gun shoulder inward so the entire gun/hand chain reads from torso.|Shorten Jenner rear disc neck and shift underside spar pitch so the body carries the nose instead of a cantilevered beam.|
|161|Replace remaining Atlas chest bib with two angular overlapping pectoral forms leading toward the inset skull instead of flat frontal mass.|Re-angle Wolverine upper and lower cannon-arm join so elbow points toward forward gun, with no hanging geometry at z near zero below y32.|Rebalance Jenner side laser nacelles against compact saucer with shorter tapered inner pod roots and clearer negative space.|
|162|Make Atlas knee/thigh armor comparatively leaner than chest, restoring assault-mech longer-legged stance despite massive shoulders.|Remove any independent vertical right forearm profile and center integrated Wolverine gun-grip fingers directly behind AC5 shroud; add hard no-duplicate geometry invariant.|Thicken Jenner digitigrade hip mounting wedges while thinning calf and rounding toe spacing beneath body balance line.|

The Wolverine old `ra` second shape was a vertical y-axis forearm tube at z=0, y32–37 while the AC5 continued ahead on a separate diagonal mount. **That source volume was removed**, replaced with exactly two z-axis profiles (upper arm and forward gun-support forearm). The elbow link was moved to z−7/y38 instead of z0/y30. The right-hand knuckles and palm were moved alongside the AC5 shroud at z−22..−14, y27..36, so the hand **grips the gun attached to that same right arm**. Added regression checks on palm↔gun↔mount voxel contacts, elbow↔upper-arm contact and exactly one right-forearm contour. Atlas shoulders and Jenner saucer were also edited in all five passes; no voxel subdivision, no APK, no merge.


## Passes 163–167: contour and articulation refinement

|Pass|Atlas|Wolverine|Jenner|
|---|---|---|---|
|163|Replace Atlas shoulder bells with 12-corner round shells, matched across both shoulder crowns.|Deepen Wolverine narrow angular visor and cheek edge beside small launcher.|Rebuild Jenner cockpit surface as 12-point round disc, not a blunt wing.|
|164|Pull Atlas jaw, nasal ridge and toothline forward from recessed skull.|Remodel Wolverine elbow armor as rotated octagonal shield around the bend.|Bend Jenner portside cockpit-to-pod truss downward into hull.|
|165|Replace squared Atlas hip collar with narrow faceted sloping waist.|Bring Wolverine right gun mount closer to elbow and grip, shortening bulky rear spine.|Cut Jenner canopy roof bulk and add actual separate raised forward glass glazing.|
|166|Angle Atlas upper arm out of rounded shoulder undercut.|Replace Wolverine oval center armor with angular faceted abdominal panel.|Rake Jenner side laser yokes rearward, opening space behind disc.|
|167|Sculpt Atlas distinct pair of deep eye sockets and nose ridge below level shoulder caps.|Add Wolverine actual finger wrap on rear of SAME AC5 rather than changing a second forearm.|Angle Jenner digitigrade thigh roots inward and center ankles under side pods.|

The pass-162 Godot render confirms deletion of the duplicate hanging Wolverine forearm. The remaining gun is held in one bent arm; its hand, trigger fingers, shroud and elbow are integrated into the same chain. Atlas shoulder shells now have 12-point rounded contours, and the Jenner disc top plan has 12-point faceted circular cross-sections. All three models changed in all five passes. No subdivision, APK or merge.


## Passes 168–172: correct negative space and joint angles

|Pass|Atlas|Wolverine|Jenner|
|---|---|---|---|
|168|Deepen negative space under Atlas skull and between shoulder bells.|Inset Wolverine inner elbow shield and open notch without separating gun, hand or forearm.|Narrow Jenner side-pod bridge where it meets front cockpit disc.|
|169|Shorten Atlas finger blocks and make both hands angle forward at elbow.|Sweep Wolverine left forearm and fist forward to balance bent right gun-bearing arm.|Bring Jenner rear hocks inward and ankle hinges forward under nacelle center.|
|170|Conform Atlas LRM rack supporting cradle to shoulder cap arc, no giant upright plate.|Re-angle Wolverine AC5 armor at the breech and hand grip; preserve open muzzle.|Add Jenner thin exposed glass windshield lip on front cockpit top and reduce upper saucer cap mass.|
|171|Rebuild Atlas skull chin teeth geometry and sharpen mandible lower edge.|Add Wolverine thumb wrap on SAME right AC5 hand just behind cannon shroud.|Anchor Jenner rear edge of disc to reactor chassis with pitched structural saddle.|
|172|Taper Atlas front shin and advance foot noses to make assault silhouette less squat.|Reshape Wolverine lower pelvis and greaves so single bent gun arm sits over stable leg centers.|Taper Jenner reactor roof and hock greaves to balance the round disc/head.|

Three models modified in each of five passes. New Atlas lower jaw elements, Wolverine gun-gripping thumb on same right arm and Jenner pitched disc rear brace. Wolverine source preserves precisely two z-axis arm lofts; no vertical right lower arm is reintroduced. Technical tests and final Godot review pending; no APK, merge or subdivision.
