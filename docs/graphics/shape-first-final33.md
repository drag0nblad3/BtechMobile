# Final shape-first BattleMech chassis batch — 33 models

Status: **editable prototypes; Godot CI and independent multi-angle reference approval pending**.

This batch follows the previous 34 of a planned 67 remaining chassis. Each chassis ships as an independent shape study and high-detail voxel recipe using 3× subdivision, with preserved loft contours and articulated parts.

| Chassis | Official unit | Low voxels | High projected pre-bevel | Open muzzle targets |
| --- | --- | ---: | ---: | ---: |
| BattleAxe BKX-7K | `battleaxe_bkx7k` | 6,831 | 133,866 | 13 |
| Chameleon CLN-7V | `chameleon_cln7v` | 6,220 | 134,055 | 5 |
| Crockett CRK-5003-1 | `crockett_crk50031` | 7,375 | 137,025 | 16 |
| Gunslinger GUN-1ERD | `gunslinger_gun1erd` | 7,078 | 138,969 | 6 |
| Havoc HVC-P6 | `havoc_hvcp6` | 5,868 | 130,977 | 8 |
| Hel HL-1 | `hel_hl1` | 6,260 | 132,327 | 9 |
| Helios HEL-3D | `helios_hel3d` | 6,476 | 134,784 | 15 |
| Howler Prime | `howler` | 6,071 | 137,808 | 15 |
| Hunchback IIC | `hunchback_iic` | 6,165 | 131,787 | 4 |
| Icarus II ICR-1S | `icarus_ii_icr1s` | 6,094 | 133,461 | 3 |
| Katana CRK-5003-2 | `katana_crockett_crk50032` | 7,187 | 135,405 | 16 |
| Lancelot LNC25-01 | `lancelot_lnc2501` | 6,542 | 134,271 | 4 |
| Legionnaire LGN-2D | `legionnaire_lgn2d` | 5,833 | 129,951 | 1 |
| Malice MAL-XT | `malice_malxt` | 7,212 | 137,943 | 4 |
| Merlin MLN-1A | `merlin_mln1a` | 6,226 | 132,273 | 9 |
| Nightsky NGS-4S | `nightsky_ngs4s` | 6,151 | 135,648 | 4 |
| Ostscout OTT-7J | `ostscout_ott7j` | 6,156 | 135,783 | 1 |
| Ostwar OWR-2Mb | `ostwar_owr2mb` | 6,633 | 135,324 | 15 |
| Penetrator PTR-4D | `penetrator_ptr4d` | 6,666 | 140,022 | 8 |
| Pillager PLG-3Z | `pillager_plg3z` | 7,249 | 143,370 | 5 |
| Sagittaire SGT-8R | `sagittaire_sgt8r` | 7,069 | 133,920 | 7 |
| Scarabus SCB-9A | `scarabus_scb9a` | 5,969 | 137,268 | 4 |
| Sentinel STN-3K | `sentinel_stn3k` | 6,056 | 135,567 | 3 |
| Shockwave SKW-2F | `shockwave_skw2f` | 4,902 | 132,354 | 11 |
| Shogun SHG-2F | `shogun_shg2f` | 6,822 | 133,299 | 42 |
| Spartan SPT-N2 | `spartan_sptn2` | 6,941 | 139,212 | 6 |
| Spector SPR-5F | `spector_spr5f` | 6,357 | 133,812 | 4 |
| Starslayer STY-3C | `starslayer_sty3c` | 6,419 | 134,379 | 8 |
| SuburbanMech UM-R90 | `suburbanmech_umr90` | 5,437 | 146,799 | 3 |
| Thunder Hawk TDK-7S | `thunder_hawk_tdk7s` | 7,453 | 143,370 | 3 |
| Thunder Stallion 4 | `thunder_stallion_4` | 7,892 | 135,432 | 3 |
| Venom SDR-9K | `venom_sdr9k` | 6,686 | 136,944 | 4 |
| Ymir BWP-2B | `ymir_bwp2b` | 7,339 | 140,184 | 16 |

## Art standards and remaining work

- Distinctively sketched head/forebody, torso, shoulder and leg outlines per chassis, with asymmetric weapons from the actual `data/units` record rather than a shared arm slab.
- Preserve low/high loft section positions and pivots. High resolution adds cut gun bores and machine plate detailing after primary silhouette.
- Fine counts are **projected before Godot bevel and seam treatment**; they are not runtime Godot measurements.
- Thunder Stallion has four independent leg chains, bound into existing eight location slots. It needs a dedicated quad gait animation in the running showcase.
- Rerun `godot --headless -s tests/run_tests.gd` and inspect front/side/back/top reference images before approving any shape.
- This batch does not include ground vehicles or infantry, which will have a separate per-model **50,000 cell hard cap**.
- These render/geometry checks are offline and do not certify exact resemblance to current CGL plastic sculpts.

## References

- [Catalyst plastic miniatures catalog](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
- [Catalog details from Catalyst store](https://store.catalystgamelabs.com/collections/miniatures)