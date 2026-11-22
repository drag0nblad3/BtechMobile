# Shape-first batch of twenty-four BattleMechs

Status: **draft art prototypes; do not merge until Godot CI and reference visual review pass.**

24 independently shaped chassis, each with a coarse editable primary silhouette
`data/voxels/<id>_shape.json` and separate detailed `data/voxels/<id>.json`.
The detail copy uses `subdivide: 3` with exact matching primary loft sections
and fine-grid weapon bores. Gameplay data stays official in `data/units`.

## Why they are different

Based on Catalyst Game Labs plastic miniature appearances and the official
unit record sheets. These 24 deliberately mix forward-beaked digitigrade
OmniMechs, long-limbed scout designs, humanoid energy-weapon carriers,
skeletal gun platforms, broad assault carapaces, and truly asymmetric
shoulder/arm setups. No common generic octagonal body or straight tree-trunk
legs were reused; high-resolution detail follows approved authoring geometry.

## Chassis and geometric verification

| Mech | Unit record | Low voxels | Projected high voxels | Unique structure |
| --- | --- | ---: | ---: | --- |
| Annihilator ANH-2A | `annihilator_anh2a` | 4,594 | 124,038 | Four long LBX barrels on tall squared shoulders, slender hip struts |
| Nightstar NSR-9J | `nightstar_nsr9j` | 4,473 | 120,771 | Low pointed bird cockpit, curved carapace, paired Gauss arms |
| Dire Wolf Prime | `dire_wolf_prime` | 4,556 | 123,012 | Overhanging broad assault yoke, recessed cockpit, shoulder LRM rack |
| Warhawk Prime | `warhawk_prime` | 4,574 | 123,498 | Low Clan prow, paired dual PPC pods, elongated reverse knees |
| Grasshopper GHR-5H | `grasshopper_ghr5h` | 4,563 | 123,201 | Narrow humanoid torso between twin tall rear jump stacks |
| Quickdraw QKD-4G | `quickdraw_qkd4g` | 4,623 | 124,821 | Jump-jet pylons, left LRM and small chest missile launcher |
| Dragon DRG-1N | `dragon_drg1n` | 4,326 | 116,802 | Long raked torso, deep nose, asym right autocannon |
| Trebuchet TBT-5N | `trebuchet_tbt5n` | 4,649 | 125,523 | Larger left forearm and right shoulder LRM-15 launchers |
| Cicada CDA-2A | `cicada_cda2a` | 4,431 | 119,637 | Tiny elongated insect cab, spindly reverse-kneed legs |
| Commando COM-2D | `commando_com2d` | 4,612 | 124,524 | Compact helmet, split chest/right arm SRM launchers |
| Javelin JVN-10N | `javelin_jvn10n` | 4,524 | 122,148 | Twin separate six-tube shoulder SRMs above narrow legs |
| Fire Moth Prime | `fire_moth_prime` | 4,530 | 122,310 | Very narrow bird fuselage, lofty rear fins, thin hock legs |
| Mist Lynx Prime | `mist_lynx_prime` | 4,725 | 127,575 | Low projecting nose, narrow hocks and separate arm missile pods |
| Banshee BNC-3E | `banshee_bnc3e` | 4,577 | 123,579 | Tall long-legged torso, smaller shoulder AC and PPC |
| Cyclops CP-10-Z | `cyclops_cp10z` | 4,508 | 121,716 | Single amber eye, asymmetric right AC/20 and LRM-10 |
| Mauler MAL-1R | `mauler_mal1r` | 4,441 | 119,907 | Wide, low shoulder pods with paired cannon stacks and lasers |
| Enforcer ENF-4R | `enforcer_enf4r` | 4,429 | 119,583 | Right forearm AC/10 versus left long laser |
| Blackjack BJ-1 | `blackjack_bj1` | 4,397 | 118,719 | Long parallel AC/2 twin gun rails, narrow central torso |
| Crusader CRD-3R | `crusader_crd3r` | 4,493 | 121,311 | Paired arm LRM-15 launchers and separate leg SRMs |
| Cataphract CTF-1X | `cataphract_ctf1x` | 4,420 | 119,340 | Off-center head, asymmetric right torso cannon and PPC |
| Ostsol OTL-4D | `ostsol_otl4d` | 4,094 | 110,538 | Rounded laser torso over long thin legs, small arm frames |
| Ostroc OSR-2C | `ostroc_osr2c` | 4,190 | 113,130 | Ovoid cabin, paired high lasers and right lower SRM launcher |
| Gargoyle Prime | `gargoyle_prime` | 4,347 | 117,369 | Low Clan cockpit, twin side SRM-6 pods and reverse knees |
| Stormcrow Prime | `stormcrow_prime` | 3,944 | 106,488 | Long low avian nose, two slender laser arms and knee hocks |

## Validation and outstanding review

* 24 low/high pairs, each with 8 hit locations and matching polygon contours.
* Authoring-grid checks: 0 cross-part overlaps, 0 detached islands and 0
  gaps at parent articulation contacts for both versions of all 24 chassis.
* 282 intended gun and missile apertures across all chassis.
* **Counts are offline pre-bevel projections**, not Godot-measured runtime counts.
* Preview sheets are offline renders from actual JSON voxel occupancy
  (not AI-generated concept art, not Godot screenshots).
* Visual verification still required against current Catalyst plastic models:
  front/side/top/rear, avoiding tall box shoulders, tree-trunk legs, wrong
  head placement and invented symmetry. In particular recheck overall
  limb slenderness and scaled arm weapon clearance in the real engine.
* Godot unit tests, render smoke and Android frame-rate stress tests still
  required before production approval. This batch does not claim CI success.

## Reference entry points

* [Catalyst miniature overview](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
* [Modern BattleTech force-pack miniatures](https://store.catalystgamelabs.com/collections/miniatures)
* Canonical chassis details and visual history: `https://www.sarna.net/wiki/<Mech_Name>`
* Existing official record sheet IDs are used; gameplay stats are untouched.

This art batch adds no APK. Leave the PR unmerged pending visual review.
