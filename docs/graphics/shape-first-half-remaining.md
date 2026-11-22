# Half of the remaining distinct BattleMechs — 34 shape-first pairs

**Status: editable prototypes pending Catalyst multi-angle art approval and Godot CI.**

At the start of this batch there were 67 unmodeled distinct chassis after ignoring variant-only IDs and chassis already represented by the voxel catalog. This batch contains 34, leaving 33.

Each low-density shape and high-density result preserves the same authored loft sections, part positions, joint pivots and uniquely placed weapons. High-detail models subdivide authored cells 3×; counts are projected pre-bevel, not Godot-measured.

| Chassis | Official unit id | Coarse voxels | Projected high voxels | Muzzles |
| --- | --- | ---: | ---: | ---: |
| Adder Prime | `adder_prime` | 3,202 | 86,454 | 3 |
| Akuma AKU-1X | `akuma_aku1x` | 4,042 | 109,134 | 26 |
| Albatross ALB-4Ur | `albatross_alb4ur` | 3,835 | 103,545 | 20 |
| Argus AGS-4D | `argus_ags4d` | 3,458 | 93,366 | 13 |
| Axman AXM-1N | `axman_axm1n` | 3,626 | 97,902 | 2 |
| Caesar CES-3R | `caesar_ces3r` | 3,400 | 91,800 | 4 |
| Chimera CMA-1S | `chimera_cma1s` | 3,375 | 91,125 | 23 |
| Clint CLNT-2-3T | `clint_clnt23t` | 3,261 | 88,047 | 3 |
| Crossbow Prime | `crossbow_prime` | 3,218 | 86,886 | 40 |
| Devastator DVS-2 | `devastator_dvs2` | 3,772 | 101,844 | 6 |
| Emperor EMP-6A | `emperor_emp6a` | 3,652 | 98,604 | 6 |
| Excalibur EXC-B2 | `excalibur_excb2` | 3,859 | 104,193 | 21 |
| Exterminator EXT-4A | `exterminator_ext4a` | 3,665 | 98,955 | 14 |
| Falconer FLC-8R | `falconer_flc8r` | 3,365 | 90,855 | 6 |
| Firebee FRB-2E | `firebee_frb2e` | 3,357 | 90,639 | 9 |
| Firefly FFL-4C | `firefly_ffl4c` | 3,182 | 85,914 | 7 |
| Goliath GOL-1H | `goliath_gol1h` | 5,079 | 137,133 | 20 |
| Grendel Prime | `grendel_prime` | 3,182 | 85,914 | 11 |
| Grizzly | `grizzly` | 3,494 | 94,338 | 14 |
| Guillotine GLT-3N | `guillotine_glt3n` | 3,464 | 93,528 | 11 |
| Hatamoto-Chi HTM-27T | `hatamoto_chi_htm27t` | 3,540 | 95,580 | 14 |
| Hellspawn HSN-7D | `hellspawn_hsn7d` | 3,296 | 88,992 | 21 |
| Hermes II HER-2S | `hermes_ii_her2s` | 4,001 | 108,027 | 3 |
| Hoplite HOP-4D | `hoplite_hop4d` | 3,276 | 88,452 | 6 |
| Linebacker Prime | `linebacker_prime` | 3,431 | 92,637 | 11 |
| Mackie MSK-9H | `mackie_msk9h` | 3,669 | 99,063 | 5 |
| Night Gyr Prime | `night_gyr_prime` | 3,654 | 98,658 | 6 |
| Pack Hunter | `pack_hunter` | 3,210 | 86,670 | 1 |
| Piranha | `piranha` | 3,235 | 87,345 | 15 |
| Scorpion SCP-1N | `scorpion_scp1n` | 4,830 | 130,410 | 6 |
| Supernova | `supernova` | 3,704 | 100,008 | 6 |
| Tarantula ZPH-1 | `tarantula_zph1` | 4,703 | 126,981 | 4 |
| Thanatos TNS-4S | `thanatos_tns4s` | 3,562 | 96,174 | 24 |
| Viper Prime | `viper_prime` | 4,172 | 112,644 | 9 |

## Shape and connectivity approach

- Each chassis has an individually authored x/z upper hull profile and distinct head/cockpit placement, silhouette span, leg thickness and weapon positions. High-detail passes do not change low-detail primary lofts.
- Heavy hulls with large hidden cores were regridded at matched world scale to avoid consuming the voxel budget invisibly, while retaining weapon and joint positions.
- Three quadrupeds—Goliath, Scorpion and Tarantula—have four independent leg rig chains, bound to LA/RA (front) and LL/RL (rear), with a long low fuselage. Their authoritative game record has `quad=true` and their preview files also record `quad: true`.
- Godot VxModel currently handles the eight hit locations but the showcase gait solver requires further quadruped animation development; these models are not animation-approved.
- Distinctive signatures modeled include Axman hatchet, large twin Gauss barrels on Devastator, Crossbow twin LRM-20 launchers, Night Gyr paired PPCs plus Ultra AC/10, Piranha MG banks, and Pack Hunter top-mounted PPC.
- Offline audits found zero inter-part overlapping cells, zero disconnected islands, and zero absent part-parent contacts in all 68 recipes. 390 physical fine-grid muzzle point definitions have corresponding cut operations.
- Multi-angle reference comparison used Catalyst miniature listings and BattleTech ForcePack sculpture references when available; final likeness/angles have not been visually approved.

## Engine validation and constraints

- Run the unit test `tests/unit/test_vx_half_remaining_chassis.gd`, importer and Claude Voxel Showcase smoke. These run in GitHub Actions once branch is updated; do not claim local Godot runtime tests.
- Offline renders are derived directly from voxel geometry and do not replicate Godot bevel/animation/rendering or claim to be official miniature scans.
- Official unit record sheets, combat mechanics, and the other voxel lab were not changed. No Android build requested or produced.

## References

- [Catalog of Catalyst Game Labs plastic miniatures](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
- [Catalyst Game Labs miniatures catalog](https://store.catalystgamelabs.com/collections/miniatures)