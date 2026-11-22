# Battlefield Support voxel graphics — 50,000 voxel hard limit

Status: **visual prototypes**, engine integration pending Godot CI and mobile profiling.

Visual recipes reside in `data/voxels/assets/` and remain independent from `data/assets/` tactical record cards. The following recipes cover tracked, wheeled, hover, VTOL, emplacements, infantry squads and battle armor.

All count values include the authored fine-grid surface features and physical gun/missile openings. The art-only asset loader enforces **at most 50,000 occupied cells per model**, including a complete infantry squad, after subdivision, bevel treatment and fine details. If a model exceeds the limit it is rejected and the old placeholder renders instead.

| Asset recipe | Type | Actual offline fine-grid cells |
| --- | --- | ---: |
| `savior_repair_vehicle` | vehicle (t) | 42,088 |
| `tracked_tank` | vehicle (t) | 41,352 |
| `lrm_carrier` | vehicle (t) | 35,016 |
| `wheeled_apc` | vehicle (w) | 41,656 |
| `wheeled_supply_truck` | vehicle (w) | 37,480 |
| `hover_scout` | vehicle (h) | 32,624 |
| `hover_tank` | vehicle (h) | 39,336 |
| `attack_vtol` | vtol (v) | 21,248 |
| `transport_vtol` | vtol (v) | 34,832 |
| `artillery_carrier` | vehicle (t) | 46,856 |
| `field_emplacement` | emplacement (stationary) | 30,832 |
| `missile_emplacement` | emplacement (stationary) | 35,327 |
| `infantry_rifles` | infantry (f) | 12,032 |
| `infantry_jump` | infantry (j) | 17,728 |
| `infantry_motorized` | infantry (w) | 12,960 |
| `battle_armor_elementals` | battle_armor (j) | 12,520 |

## Integration

- `VoxelAsset.recipe_for(def)` uses `AssetCard.kind`, motive, and primary specials. The Savior Repair Vehicle uses its exact source ID. Unknown asset types keep the previous placeholder.
- `PlaceholderAsset.build` now attempts VoxelAsset first; the combat rules, record cards, BV and hit/damage calculations are untouched.
- A shared VxPart mesh system culls hidden faces and limits draw calls; parts are static until a separate rotor/turret animation pass.
- Art prototypes were checked in a direct offline voxel geometry renderer, not generated images. Actual Godot meshes and FPS must be verified on device.
- Some visual archetypes (artillery, transport VTOL) are included for later selection once specific official support cards are added.
- Test using `tests/unit/test_voxel_assets.gd` and existing asset smoke/unit tests. No Android build was requested.

## Art follow-up

- Replace generic armored vehicle and infantry uniforms with reference-matched variants as more official cards are added.
- Add turret yaw, tread/wheel motion and VTOL rotor animation only after verifying static geometry and game performance.
- Treat 50,000 as a limit, not a desired minimum; infantry squads need far fewer voxels.
