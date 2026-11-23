# Remaining voxel model coverage — 22 November 2026

**Status:** New editable art prototypes committed on a working branch. **Not approved / not merged.** No APK produced.

## New coverage

- **42 distinct BattleMech chassis**, each with an editable 1× polygon silhouette `data/voxels/<sprite>_shape.json` and matching 3× fine-detail sculpt `data/voxels/<sprite>.json`; both added to `VxShowcase.MODELS`.
- **22 official combat vehicle variants**, each with an independent `data/voxels/vehicles/<id>.json` sculpt instead of relying entirely on the one generic tracked/hover/wheeled body.
- **7 official battle-armor squads**, individual `data/voxels/battle_armor/<id>.json` art; 5-trooper Elementals and 4-trooper Inner Sphere squads, with distinct arm-mounted flamer/MG/laser/AP Gauss designs.
- **71 new model subjects total** (113 new source model JSON files).

### BattleMech chassis
tian_zong, jackalope, rattlesnake_ii, stealth, hermes, marauder_ii, thunder, champion, uziel, galahad, dragon_fire, cerberus, bane, locust_iic, mad_cat_mk_ii, shiro, grand_dragon, gunsmith, gladiator, shadow_hawk_iic, huntsman, cougar, ebon_jaguar, kingfisher, arctic_wolf, avatar, battle_cobra, black_lanner, griffin_iic, highlander_iic, jenner_iic, jinggau, peacekeeper, raptor, sunder, tempest, templar, thunderbolt_iic, glass_spider, tiburon, toro, rattlesnake.

### Record-sheet combat vehicles
behemoth_heavy_tank, bulldog_medium_tank, condor_heavy_hover_tank, demolisher_heavy_tank_clan, demolisher_heavy_tank_mk_i, drillson_heavy_hover_tank, galleon_light_tank_gal_100, hetzer_wheeled_assault_gun, j_edgar_light_hover_tank, lrm_carrier, lrm_carrier_c, manticore_heavy_tank, patton_tank, pegasus_scout_hover_tank, pike_support_vehicle, pike_support_vehicle_clan, schrek_ppc_carrier, skulker_wheeled_scout_tank, srm_carrier, srm_carrier_c, vedette_medium_tank, von_luckner_heavy_tank_vnl_k65n.

### Battle armor
elemental_ba_ap_gauss, elemental_ba_flamer, elemental_ba_laser, elemental_ba_mg, is_standard_ba_flamer, is_standard_ba_laser, is_standard_ba_mg.

## Geometry-first / weapons work

Primary cross-section silhouettes are authored as polygons and separate moving components, then fine-detail voxel edges are painted *after* that stage. The low/high Mech files use exactly matching `parts[*].shapes` contours, pivots, hit locations and muzzle coordinates. Launcher tube cutouts and gun bores are real voxel erasures, not painted dots. Representative signatures include:

- **Ebon Jaguar:** much larger right-arm Gauss barrel versus left LB-X, with high LRM10.
- **Mad Cat Mk II:** long paired arm guns and ten open tubes on each torso LRM bank.
- **Bane:** paired rotary autocannon barrel groups and independent LRM banks.
- **Marauder II:** broad raised carapace, projecting beak cockpit and arm Gauss weapons.
- **Shiro:** separate long sword on right arm, left LB-X cannon, split LRM launchers.
- **Schrek:** triple PPC turret; **Demolisher:** parallel AC20 barrels; **Pike:** three/five distinct AA cannon bores depending on record sheet.
- **Elementals vs IS standard:** different squad counts and weapons with tapered, polygonal chest armor rather than a single generic box.

The two reproducible scripts `tools/missing_chassis_shape_generator.js` and `tools/missing_support_shape_generator.js` perform **50 real geometry-edit loops for every new subject**, with five successive cycles of ten geometric concerns. Each source file records a total edit count and a revision identifier. These are *automated source edits*, **not** 50 independently reviewed visual approvals. Art-specific rules and project combat data remain separate. No rules, sheet statistics, damage outcomes or pivots were changed.

## Integration

- Added all low/high Mechs to `VxShowcase.MODELS`.
- `VoxelAsset.build_record_vehicle` and `build_record_squad` select the official record-sheet art; `PlaceholderAsset` retains the previous stand-in if recipe loading fails.
- The existing **50,000-occupied-voxel hard ceiling** is enforced by `VoxelAsset.model_from_dict` for all added vehicles and squads. These are caps, not claimed measured counts.
- Existing shared support assets and their cap remain unchanged.
- New tests: `tests/unit/test_vx_missing_chassis.gd` and `tests/unit/test_voxel_record_sheet_models.gd`.

## Outstanding approval and audit

**No Godot executable was available in the working environment.** CI, actual engine voxel counts, full joint/part connectivity, high-LOD bevel meshing, Android FPS, and side/rear/top miniature fidelity are **not verified**. In particular, procedural lofts and shared part scaffolds must be compared carefully against recent Catalyst miniature references. The new models have varied armaments and measurements, but that is not a substitute for independent multi-angle silhouette acceptance.

Required checks before merge:

1. `godot --headless --import` then `godot --headless -s tests/run_tests.gd -- vx_missing_chassis` and `-- voxel_record_sheet_models`; then run the whole test suite.
2. Open `scenes/vx_showcase.tscn`, cycle all newly added Mechs, and inspect front/side/top/rear and three-quarter views against current plastic sculpt references.
3. Confirm all 22 vehicle and seven squad files load instead of placeholders, measure each runtime occupied voxel total, and confirm every model is **≤50,000**.
4. Review named weapon-mount origin, no model floating components or hidden coincident shells, and performance with 20/60 detailed units. Roll back or correct models that fail.
5. Approval and merge only after CI and human art review.

No APK build requested or attempted.
