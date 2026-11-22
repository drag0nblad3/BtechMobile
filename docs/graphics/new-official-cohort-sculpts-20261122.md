# Newly imported BattleMechs: independent shape-first cohort of 15

Status: **unapproved draft geometry**. Added to the voxel showcase, not to the battlefield. Based on official unit data in `data/units`; weapon racks and locations are modeled on their own independently named mechanical segments. The 15 are Apollo, Bandersnatch, Battle Hawk, Bombard, Cestus, Daedalus, Daikyu, Daimyo, Dart, Duan Gung, Eagle, Enfield, Enforcer III, Falcon, and Falcon Hawk.

Each sculpt has bespoke torso loft sections, a proportion-specific cockpit, independent torso armor supports, upper arms, forearms, upper legs, shins and feet, and weapon-specific components. The source is plain-text editable; `subdivide:2` versions render the same shape source. These are early mechanical shape studies, **not** 15 finished reference-matched miniatures. Geometry tests must reject any disconnected mass and any weak joint. Review front, side, 3/4 and top views, resculpt visibly wrong profiles, then continue the still-missing list.

For consistency with the owner's art feedback: never mark a chassis complete solely because it has 15 parts or a green flood-fill; inspect actual rendered weapon mounts and shoulder bearings. The generator shared only octagonal loft/box/cut **drawing operations**; no rendered mech part was copied from a different chassis. Additional reference-based detailing is necessary.

## Corrective work and acceptance status

The owner's shoulder/arm feedback exposed both real weak bearings and a review-tool error. The six original studies now have 3×3 backed shoulder mount tests and a rooted full-assembly check. The preview renderer now draws `shell` mass and does not mirror right-side `add` shapes a second time. The 15 new source studies were checked with a stricter flood fill, rooted tree, backing contact and muzzle-clearance suite; 56 initial failures were removed by physically rebuilding elbow supports, cutting disconnected decorative fragments, and remounting weapons. **A passing graph/topology check does not certify reference likeness.**

A further silhouette/proportions pass adjusted tonnage-relative world scale, Apollo launcher shoulders, Bandersnatch swept top structures, Battle Hawk front beak, Daikyu rear housings, Daimyo helmet, and heavy arm cannons. The common assembly layout is still too visually repetitive in some of the 15. Do not describe them as finalized, use them as source geometry for individual reference-accurate resculpts. Prefer actual voxel renders (including openings) over simplified shape-proxy pictures.

### Remaining unmodeled newly imported chassis

The 100 additional imported official unit records are merged; the following distinct chassis from the 150-design import remain without an independently reviewed source voxel model. This list excludes imported variants of already-modeled chassis, which may reuse a base shape only where the geometry is actually appropriate.

- Original 50-design import (#221), **0 unmodeled**: 
- Next 50-design import (#226), **29 unmodeled**: `alfar`, `behemoth`, `blade`, `brigand`, `cobra`, `cossack`, `cronus`, `dragoon`, `eisenfaust`, `eris`, `exhumer`, `gravedigger`, `hermes_iii`, `hound`, `initiate`, `jagermech_iii`, `koschei`, `marshal`, `orochi`, `phoenix`, `rampage`, `razorback`, `rook`, `swordsman`, `talos`, `titan`, `verfolger`, `von_rohrs_hebi`, `yu_huang`.

**29 distinct unmodeled chassis remain**. The third 50-design import (#228) is largely established-chassis variants, plus Thorn variants (Thorn already counted above). These new shape studies are still **draft-only**, not deployed to battlefield geometry. Continue source-first unique silhouette work, 6-connected mass/3D contacts, per-chassis reference comparisons, and multiple passes before adding more unit records or merging artwork. No APK.

## Additional individual silhouette studies

New custom-source shape studies for **Imp (IMP-2E)**, **Rakshasa (MDG-2A)**, **Thorn (THE-F)**, and **Wraith (TR1)** have been added. They are intentionally made as independent structural compositions (huge rounded Imp dome and independent arm missile array; long-forward Rakshasa machine with digitigrade 4-segment legs and rotary autocannon; very small Thorn with an arm LRM5 cassette; Wraith with narrow chest, long dorsal aerials and asymmetrically sized laser emitters), not borrowed parts from earlier chassis. All weapon positions target the specific official unit record. Initial source sculpts still require topology, pose, and miniature likeness validation; do not merge solely on component count.

## Ten further chassis source studies and multi-angle targets

The next structural source pass adds **Ha Otoko, Hammerhands, Lightray, Wolf Trap, Watchman, Fireball, Gallowglas, Night Hawk, Kabuto, Warlord** with bespoke torso and cockpit cross-sections, tonnage-adjusted voxel sizes and location-correct custom weapon arrays. The four-pack Ha Otoko has precisely 20+20 shoulder and 10+10 arm launcher bores; Hammerhands has paired AC10 arms and 6-hole RT launcher; Wolf Trap has one major RA cannon and an LRM10 CT opening. Warlord has twin arm heavy PPCs and torso laser groups; Kabuto has two four-hole shoulder Streak arrays.

The shape grammar shares loft/box drawing operations, **not vertices or finished pieces**. Nevertheless these are *still first-stage draft sculpts*, not reference-accurate final art. Tonnage differences, specific beaks/helmet/shield mass, dedicated weapon positions, shoulder bearing thickness and view-angle proportions must be reviewed per chassis. Strict face-connected mass, backed joints and real muzzle openings apply to these 29 added cohort models too. Do not merge until the user approves their silhouettes. Actual bare-voxel five-angle gallery should be prioritized over preview proxy and test count.

## Original import cohort: 24 additional articulated shape studies

Each of the 24 unique chassis from initial unit import PR #221 that lacked art now has a **first** `_shape.json` source and doubled-resolution manifest. This includes a deliberately shared Samurai-style hull for four *Hatamoto chassis variants* (the same visual family), but their LT/RT weapon fits differ: Hi twin laser banks, Kaze LRM5 launchers, Ku AC/5 and Mizo ER large laser. Other sculpts have distinct primary proportions: massive missile shoulders of **Salamander**, large side machinery of **Juggernaut**, high offset rack of **Grim Reaper**, low-slung avian **Jackal/Nexus**, wide weapons of **Onslaught**, small **Koto** and **Talon**, and separate mixed weapon assemblies for their own official variants. These are **source-first drafts, not finished likeness-approved models**. Test flood-fill, backed joint mass and muzzle opening, then compare front and side angles with reference photos before signoff.

The original imported 50 official designs are now represented by a voxel source geometry study or by already-existing same-chassis geometry. The remaining **29** designs lacking individual art are from PR #226. Do not resume source unit import or merge until the full missing-art phase is complete.
