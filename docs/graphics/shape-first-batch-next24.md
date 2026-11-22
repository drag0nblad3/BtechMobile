# Shape-first batch: 24 more non-generic BattleMechs

**Status:** editable art prototypes; draft PR; Godot engine/render CI is not yet approved.

Separate low-resolution authored silhouettes and high-density voxel files. No existing combat rules or record sheets were edited. Current Catalyst plastic miniatures were preferred when studying overall character. These are distinctive reference-inspired geometry passes, not source-verified exact reconstructions.

## Model count, budget and individual silhouette choices

| Chassis | Official unit ID | Coarse silhouette | High voxels (pre-bevel estimate) | Unique design cue |
| --- | --- | ---: | ---: | --- |
| Wasp WSP-1A | `wasp_wsp1a` | 5,655 | 152,685 | Small angular command cockpit, swept jump-jet vanes, leg SRM-2 |
| Stinger STG-3R | `stinger_stg3r` | 4,831 | 130,437 | Narrower cockpit and paired arm machine guns, shorter jump flaps |
| Mercury MCY-98 | `mercury_mcy98` | 5,679 | 153,333 | Compact low sensor head, slim biped, separate torso lasers |
| Mongoose MON-66 | `mongoose_mon66` | 4,959 | 133,893 | High slim helmet, thin arms, scout laser layout |
| Valkyrie VLK-QA | `valkyrie_vlkqa` | 5,083 | 137,241 | Single left-shoulder LRM-10 rack and much smaller right-arm laser |
| Wolfhound WLF-1 | `wolfhound_wlf1` | 4,914 | 132,678 | Long canine face, cheek fins, forward right-arm heavy laser |
| Assassin ASN-21 | `assassin_asn21` | 4,956 | 133,812 | Low forward beak and offset SRM-2/LRM-5 pods |
| Vulcan VL-2T | `vulcan_vl2t` | 5,130 | 138,510 | Very tall narrow shins, small arm weapons, shoulder AC/2 |
| Hatchetman HCT-3F | `hatchetman_hct3f` | 6,687 | 157,005 | One-sided physical axe blade on right arm and right-shoulder AC/10 |
| Kintaro KTO-18 | `kintaro_kto18` | 5,593 | 151,011 | Separate SRM-6 torso and left-arm banks |
| Dervish DV-6M | `dervish_dv6m` | 5,744 | 155,088 | Paired narrow LRM-10 shoulder launchers and small arm missile pods |
| Whitworth WTH-1 | `whitworth_wth1` | 4,982 | 134,514 | High paired LRM-10 towers and tiny laser arms |
| Hollander BZK-F3 | `hollander_bzkf3` | 5,069 | 136,863 | Extremely long right Gauss rail above lean scout body |
| Flashman FLS-8K | `flashman_fls8k` | 6,460 | 130,005 | Rounded armored torso and recessed low cockpit, three large laser mouths |
| Victor VTR-9B | `victor_vtr9b` | 5,856 | 158,112 | Right AC/20 beside short left SRM-4 tower, long jump-capable legs |
| Zeus ZEU-6S | `zeus_zeu6s` | 6,250 | 168,750 | Left AC/5 versus tall right LRM-15 tower |
| Thug THG-10E | `thug_thg10e` | 5,729 | 154,683 | Low head between large PPC forearms and separate shoulder SRM-4s |
| Charger CGR-1A1 | `charger_cgr1a1` | 6,147 | 165,969 | Tall leggy assault walker with tiny laser mounts and fists |
| Kodiak | `kodiak` | 7,034 | 151,686 | Hunched bear-like torso, two distinctive clawed hands, shoulder UAC/20 |
| Executioner Prime | `executioner_prime` | 6,832 | 140,940 | Large asymmetric Gauss and ER-laser arms on a low Clan head |
| Hellbringer Prime | `hellbringer_prime` | 6,024 | 162,648 | Avian cockpit, twin PPC arms, independent right Streak SRM rack |
| Turkina Prime | `turkina_prime` | 6,832 | 146,502 | Low broad circular carapace and high paired LRM towers, digitigrade hocks |
| Kit Fox Prime | `kit_fox_prime` | 5,116 | 138,132 | Forward needle-like nose, thin reverse knees, asymmetric weapons |
| Ice Ferret Prime | `ice_ferret_prime` | 4,923 | 132,921 | Long pointed cockpit, slim reverse-jointed legs, light laser and SRM pods |

## Correctness and limitations

* Both LODs use the same primary loft contours, pivots and articulated part hierarchy.
* Independent coarse occupancy audit showed **zero overlaps**, **zero disconnected voxel islands**, and **zero missing parent-joint contacts** for all 48 JSON files.
* Fine-detail geometry has **228** associated muzzle points, and recipe-level opening checks confirmed matching erase operations.
* All authored materials belong to the JSON palette; official record IDs and both mirror chains were verified.
* Projected voxel range: **130005–168750**. Models above 150k (chiefly more elaborate assault frames) need Godot profiling and can be optimized further.
* Counts are mathematical 3× volume projections from the authored coarse occupancy, **not Godot-measured post-bevel** counts.
* Render contact sheets are constructed from the actual voxel geometry using an offline raster/mesh exporter; **not Godot screenshots or AI-generated concept pictures**.
* Next visual gates: front, rear, side, and top reference comparison, especially leg shapes, dorsal/arm bore orientation, torso depth and weapon mounting. No claim of Catalyst-level exact likeness.
* The adjacent prior-model art pass narrows original contour polygon tiers and preserves details like the Atlas recessed head and the Jenner forward disc. It does not homogenize all chassis with a single scale factor.

## Reference library

* [Catalyst Game Labs plastic miniature index](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
* [Catalyst ForcePacks](https://store.catalystgamelabs.com/products/battletech-forcepack-inner-sphere)
* [BattleTech Miniatures Gallery](https://jadedfalconer.com/Pages/6How/sculpts)

No APK built, no changes to authoritative combat rules.