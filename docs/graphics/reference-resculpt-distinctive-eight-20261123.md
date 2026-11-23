# Eight distinct BattleMech source resculpts — 23 November 2026

This reference-informed **source geometry pass** deliberately avoids the first 20 already being worked in #259. All changes occur in both editable silhouette and high-detail authoring files, preserve signed rig pivots, visual weapon origins, physical muzzle openings and existing backed 2×2 joint sockets from #242.

| Chassis | Reference-dependent changes |
| --- | --- |
| Jenner IIC | Broader forward oval cockpit disc and paired aerials rooted in the head, lighter powerplant roof and slender digitigrade calves |
| Locust IIC | Slimmer pointed cockpit beak, integrated dorsal spine, light upper back and very narrow insectoid lower legs |
| Mad Cat Mk II | Wide cockpit wedge with converging narrow top, less top-heavy central roof, untouched twin drilled LRM shoulder racks |
| Marauder II | Lower, wider canopy prow beneath wide shallow carapace, slimmer lower legs; tall dorsal cannon retained |
| Uziel | Rounded central canopy and high rounded shoulder artillery housings, lean forearms and slender calves |
| Shadow Hawk IIC | Tapered high forward helmet and uneven shoulder geometry, trimmed rear roofline, slimmer legs |
| Sunder | Asymmetric broad upper weapon housings left intact, narrower upper-back block, slim calves |
| Templar | Strong separated shoulder/arm silhouettes and taller rounded brow, smaller roof and lower limbs |

## Sources and priorities

Prefer Catalyst plastic when available. Jenner IIC, Locust IIC and Shadow Hawk IIC are in the **Clan Cavalry Star** (https://www.sarna.net/wiki/BattleTech:_Clan_Cavalry_Star). Marauder II appears in the **Inner Sphere Direct Fire Lance** (https://www.sarna.net/wiki/BattleTech:_Inner_Sphere_Direct_Fire_Lance). For the Mad Cat Mk II secondary MWO reference: https://www.sarna.net/wiki/File:MWO_Mad_Cat_MkII.png. For Uziel rounded cannon shoulders and leg anatomy: https://imgur.com/gallery/mech-day-day-23-uziel-oJhOL29. For Sunder: https://www.dakkadakka.com/gallery/1069000-Sunder.html; for Templar: https://thangs.com/designer/BobertmaX/3d-model/MW4%20Templar%20Battletech%20Miniature-904740.

## Structural and visual review gates

These are authored source-contour changes, **not approved 1:1 reference matches**. Current renders must still be compared from front, side, oblique, top and rear. Moving joint roots, shrinking arm-gun mounting seams, filling bores or attaching unsupported floating shapes is not permitted. The two small Jenner antennae begin inside the head and the Locust dorsal spine begins inside its torso, rather than existing as floating islands.

`tests/unit/test_vx_reference_distinctive_eight.gd` enforces paired authoring source, unchanged kinematics and weapon locations, valid loft sections and a positive section area. The earlier full catalog backed-contact/connectivity audit, voxel integrity, performance smoke tests and scene render audits remain mandatory. No rules, unit designs, combat outcomes or Android APK changed.
