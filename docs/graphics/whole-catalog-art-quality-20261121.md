# Whole-catalog voxel art quality pass — silhouette, weapon, connections

Status: **implemented art pass; provisional until Godot CI and multi-angle visual approval**.

## Scope
- **151** shape-first BattleMech silhouettes and paired detailed JSONs are loaded through `VxArtQuality.apply` in `VxModel.from_dict`.
- The separate established Catapult and Hunchback examples and three specialized Atlas/Jenner/Wolverine procedural source descriptors are supported by the existing loader, but some do not use the same generic cross-section drawing conventions.
- **16** vehicle, VTOL, emplacement and infantry archetypes use `VxArtQuality.apply_asset` in `VoxelAsset.model_from_dict`, subject to the unchanged **50,000 occupied-voxel hard cap**.
- The first 19 flagship chassis pairs also have their revised primary contours **baked directly into both JSON sources**. Other models receive the class-specific pass on load; the original editable geometry is retained for future hand-sculpting.

## Five geometry-first passes
1. **Silhouette:** break rectangular torso profiles into waist / chest / roof regions, with restrained changes for very broad assault machines and none of the forced humanoid waist on quadrupeds or the UrbanMech. Reference-facing special heads (Atlas skull, Jenner disc, Wolverine angular cockpit, Marauder and Timber Wolf nose, King Crab) are preserved.
2. **Shoulder and gun separation:** taper only the outer shoulder/upper-arm profiles; preserve inner attachment faces and forward-firing weapon locations. Avoid replacing unique hardpoints with generic blocks.
3. **Weapon readability:** convert unusually thick, long cannon boxes into a tapered forward muzzle + full breech profile without moving real `erase` channels or `muzzles` coordinates. Continue respecting the 20-tube racks and other physical missile openings.
4. **Leg and head proportions:** slimmer mid-shins for the scouts and humanoid bodies, conservative head width correction on oversized generic heads. Keep the digitigrade articulated chain and pivot hierarchy intact.
5. **Mechanical contacts:** settle single-cell ownership before subdivision. Repair tiny disconnected clusters on the Raven arm and Shadow Cat center hull; bridge short articulation gaps with narrow structure-role rods rather than fat armor fillers. No arbitrary root-leg rotations or gameplay hit-location changes.

## Vehicle and infantry differentiation
Tracked tanks retain visible tread tracks; hover units retain skirts; wheeled trucks retain separate wheels; VTOLs keep their long fuselage/rotor shapes. Upper hulls and turrets receive restrained contour taper rather than a single interchangeable blocky mass. Infantry and battle armor use a polygonal waist/torso cross-section rather than a solid cuboid, while retaining their long rifles, jets and armor.

Three manual archetype source edits prevent visibly merged launcher or transporter masses:
- **LRM Carrier:** three distinct housing banks with space between them; all existing high-grid firing port cuts remain.
- **Missile emplacement:** three open-sided launcher banks instead of one continuous wide wall; the 21 existing bores remain aligned.
- **Wheeled supply truck:** exposed rear cargo-bed rails, visibly distinct from the sealed wheeled APC.

## Offline asset-budget audit (after all changes)

| Archetype | Final fine occupied voxels, offline | Hard cap |
| --- | ---: | ---: |
| Savior repair vehicle | 44,272 | 50,000 |
| Tracked tank | 39,392 | 50,000 |
| LRM carrier | 30,952 | 50,000 |
| Wheeled APC | 39,976 | 50,000 |
| Wheeled supply truck | 37,544 | 50,000 |
| Hover scout | 31,952 | 50,000 |
| Hover tank | 38,696 | 50,000 |
| Attack VTOL | 20,856 | 50,000 |
| Transport VTOL | 34,088 | 50,000 |
| Artillery carrier | 45,208 | 50,000 |
| Field emplacement | 30,440 | 50,000 |
| Missile emplacement | 33,999 | 50,000 |
| Rifle infantry squad | 9,600 | 50,000 |
| Jump infantry squad | 15,296 | 50,000 |
| Motorized infantry squad | 11,440 | 50,000 |
| Elemental battle-armor squad | 11,520 | 50,000 |

These are offline occupancy counts using the authored JSON and a local preview raster. The **Godot renderer, material blending and hidden-face bevel pass are still the authoritative engine behavior**. Strict runtime guard rejects an asset exceeding 50k and retains the placeholder.

## Quality gates and known limits
- `tests/unit/test_vx_art_quality.gd` checks every ordinary low/high pair after refinement: primary loft contour equality, unchanged component pivots, untouched muzzle locations, original weapon assignments and exclusive cell ownership.
- Existing `test_voxel_assets.gd` enforces strict 50k cap across all 16 assets.
- Baseline CI before this pass had **66 failures**, mainly overlapping older art modules, plus disconnected islands on Raven/Shadow Cat. This pass addresses both causes, but do **not** claim tests pass until GitHub CI finishes.
- Automated contour taper and box-to-loft conversions **cannot guarantee Catalyst sculpt fidelity**. Do front/side/top/three-quarter inspection with latest plastic miniatures and individually sculpt remaining shape mismatches, especially 20-ton scouts, unusual bird bodies and oversized shoulder hardpoints.
- Shape and visual damage changes are separate from record-sheet authority. No changes to core combat rules; no APK and no merge.
