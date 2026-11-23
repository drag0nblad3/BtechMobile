# Third reference-led four-chassis resculpt (2026-11-23)

Issue: #271. Source JSON: `data/voxels/hellhound_conjurer.json`,
`dominator.json`, `solitaire.json`, `koshi_standard.json` plus Koshi
Standard 2 and 3 overlays. This pass replaces hull surfaces and silhouette
contours; it does **not** invent unit variants or alter equipment/rules.

| Mech | Reference direction | Major contour change |
| --- | --- | --- |
| Conjurer / Hellhound | Recognition Guide: ilClan vol. 5 and current Clan Striker Star plastic | Separate central slanted armor shield from two lateral forward chest facets; slimmer midsection, helmet, outward-sloped paired horns, tapered gun and short knees guards |
| Dominator | Recognition Guide: ilClan vol. 1 artwork | Asymmetric elevated LT missile array vs lower RT laser shoulder; lowered narrowed head, V-shaped center armor, strong right longitudinal PPC cannon with left independent fist |
| Solitaire | TRO 3067 and modern miniature render | Replace overlapping dorsal boxes with a tapered, forward-bored high laser heat jacket, shorten torso side silhouette and lengthen both legs by re-spacing rig parts |
| Koshi (Standard BattleMech) | TRO 3145 Mercenaries art **not Mist Lynx Omni** | True tapered/hollow paired dorsal radiators, round forward cockpit face, different left/right pod shapes and increased leg-height fraction |

**Leg proportion revision:** for the Solitaire and Koshi, the feet stay at
the same ground level and the hip rises four authored grid cells. Every
intervening thigh, shin and joint location is interpolated consistently,
and torso, muzzles and all Koshi variant overlays move along with it.
This is a *model proportion change*, not a runtime skeletal stretch.

**Acceptance:** full/coarse connectivity and camera render workflows must
pass; no weak contacts, non-physical missile openings, model-dependent
rig breakages, or additional floating masses. Multi-angle contact-sheet
inspection must guide the next pass. Automated silhouette scores are
**not** reference-pixel similarity scores.

Art reference entry points:
- https://www.sarna.net/wiki/Conjurer_(Hellhound)
- https://www.sarna.net/wiki/Dominator
- https://www.sarna.net/wiki/Solitaire
- https://www.sarna.net/wiki/Koshi_(BattleMech)

Sources are reference only; no official image copied into the repository.
