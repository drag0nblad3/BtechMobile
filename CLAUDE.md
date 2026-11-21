# BtechMobile — agent guide

Rules-complete BattleTech (Total Warfare) for Android phones. Godot 4.5+, typed GDScript.
Battle mode first; campaign layer later.

## Working efficiently (read this first)
- **Don't read the whole repo.** Use the file map below, open only the files a change touches.
- One class per file, `class_name` = PascalCase of the file name. Target < 150 lines per file;
  split before a file passes ~200.
- New rule = new file under `src/core/rules/<area>/` + a test in `tests/unit/test_<area>.gd`
  + a line in `docs/rules-coverage.md`. Don't grow existing rule files sideways.
- Content (units, terrain, maps, scenarios) is JSON in `data/`, never hard-coded.
- **'Mech designs are official only** (Tyler's rule): loadouts come from MegaMek's unit files
  (`source.megamek`), BV from the free official record sheets (`source.bv: "sheet"`) or, when a
  design has no free sheet, MegaMek's BV calculator (`"megamek"`). No made-up refits or BV
  formulas; a loadout that exercises one rule goes in `tests/fixtures/units/`. See `docs/data-sources.md`.
- Prefer `Edit` over rewriting files. Keep comments short; `##` doc comment on each class.

## Layers (strict)
- `src/core/` — pure rules. `RefCounted` only, **no Nodes, no rendering, no input**.
  Only `GameController` mutates `GameState`; it emits `GameEvent`s.
- `src/view/` — Godot nodes. Reads state, animates events, turns input into controller calls.
  Never changes `GameState` directly.
- Dependencies point view → core, never core → view.

## Shared voxel work across Claude and ChatGPT
- **Both agents may edit both implementations.** Claude's JSON/rig/record-sheet
  pipeline lives in `data/voxels/`, `src/view/vox/`, and
  `docs/graphics/voxel-model-format.md`; the procedural high-resolution lab
  lives in `src/view/units/voxel_*.gd`,
  `data/graphics/voxel_chassis.json`, and
  `docs/voxel-mech-prototype.md`. Don't treat either set as read-only or
  assume the two use interchangeable coordinate systems or mesh formats.
- Before changing an existing chassis, read **both** versions (if available),
  the relevant tests, and the integration plan in
  `docs/graphics/voxel-integration-plan.md`. Bring improvements across by
  adapting coordinates and voxel pitch, not by copying raw cell coordinates.
  Keep bilateral weapon racks, mirrored pivots, muzzles and physical openings
  aligned; never create coincident surfaces in parent/child parts.
- **Two shared visual rules:** material roles are `armor` and `structure`;
  cosmetic voxels may disappear but only the **real `Unit` record sheet and
  `GameEvent`s** decide game damage, criticals, limb loss and victory.
  Claude's `VxDamage` maps record-sheet state to visuals, whereas the
  procedural lab's `VoxelMech.hit_part` is a **sandbox** for art/stress testing.
  Do not change `src/core/` or infer combat outcomes from voxel counts in
  order to reconcile these visual systems.
- Cross-edit tests: `tests/unit/test_vx_model.gd` (JSON recipes, role-driven
  damage, mirrored launcher geometry), `tests/unit/test_voxel_detail.gd`
  and `tests/unit/test_voxel_chassis_fidelity.gd` (procedural density and
  damage), and `tools/voxel_count_report.gd`. Run the Godot unit and smoke
  tests, including both isolated lab scenes. Open a PR rather than changing
  someone else's working branch; inspect `main` before merging.
- **No Android APK build unless the user explicitly requests it.** Do not
  generate unsolicited model renders.

## File map
| Path | What |
|---|---|
| `src/core/hex/hex.gd` | Axial hex math, facings (0=N clockwise), mapsheet labels (XXYY, odd-q) |
| `src/core/map/` | `TerrainType`/`TerrainDb`, `MapTile` (level, depth, building), `BattleMap`, `MapLoader`, `BuildingType`/`Building` (threshold, destroy check, height) |
| `src/core/units/` | `UnitDef`/`UnitDb` (designs), `WeaponDef`/`WeaponDb`, `Unit` (live record sheet), `Location`, `StructureTable`, `CritLayout`/`CritSlot`, `MountedWeapon`, `AmmoBin`, `Pilot`, `DesignWeight` (tonnage check), `ClanTech` (Clan construction sizes), `OmniConfig` (OmniMech configurations), `DesignItems` (equipment strings), `InertGear` (A-pods, TAG: carried, no effect yet) |
| `src/core/state/` | `GameState`, `GameController` (turn flow, initiative, actions), `GameEvent`, `Phase`, `ScenarioLoader` |
| `src/core/rules/movement/` | `MoveMode` (walk/run/jump costs), `MoveCost` (per-hex MP), `MovePlanner` (Dijkstra over hex+facing, backward steps), `JumpPlanner`, `MoveOptions`, `ProneMoves` (dropping prone, prone turning), `Masc` (MASC bursts, escalating failure), `Quad` (four-legged 'Mechs: MP, piloting, prone fire), `LateralShift` (quad sideways steps), `Tsm` (triple-strength myomer), `Supercharger` (running bursts, engine damage), `MoveExecutor` (carries out a move for the controller) |
| `src/core/rules/combat/` | `LineOfSight`, `FiringArc`, `ToHit`/`ToHitCalc`, `IndirectFire` (spotters), `WaterCombat` (water line, underwater ranges), `HullBreach`, `ProneFire`, `FireOptions`, `WeaponFire`, `HitTable`, `ClusterTable`, `Damage`, `AmmoExplosion` (caps, CASE), `ComponentExplosion` (Gauss), `XlEngine` (side-torso engine slots), `AimedShot` (immobile targets), `AntiMissile` (AMS), `TargetingComputer`, `Ecm` (Guardian ECM vs Artemis), `C3` (Master/Slave networks, range sharing), `ActiveProbe` (sees through smoke, fog, murk), `WeaponModes` (Ultra/LB-X/Streak/Artemis), `RotaryAc` (rapid fire, jams), `Narc` (homing pods), `Atm` (ATM munitions), `CriticalHits`, `CritEffects`, `HeadHit` |
| `src/core/rules/heat/` | `HeatScale` (effects by heat level), `HeatPhase`, `HeatShutdown`, `VoluntaryShutdown` (shut down/restart by choice), `HeatSinkSwitch` (heat sinks off/on) |
| `src/core/rules/piloting/` | `Psr` (piloting rolls, standing up), `MovePsr` (rolls a move costs: on entering a hex or after the move), `Skid` (unused optional rule), `Fall`, `PilotDamage`, `Gyro` (gyro types, heavy-duty) |
| `src/core/rules/physical/` | `PhysicalOptions` (punch/kick/push, levels table), `PhysicalMods` (shared checks + modifiers), `Charge` (charge, DFA options), `ChargeResolve` (rolls, damage, displacement), `Displacement` (domino effect, ledges, off-map), `MeleeWeapons` (hatchet, sword, clubs), `QuadKick` (front and mule kicks), `PhysicalPhase` |
| `src/core/rules/buildings/` | `BuildingRules` (entering, inside modifiers, destroy checks, collapse), `BuildingDamage` (per-attacker damage, end-of-phase collapse), `BuildingFire` (shooting buildings), `BuildingMelee` (punching/kicking buildings), `Roofs` (roof landing/moves, support limit) |
| `src/core/rules/conditions/` | `Conditions` (weather, temperature, gravity for the whole map), `ExtremeTemp`, `Gravity`, `ConditionsTable`, `Wind`, `LowVisibility` (sensor checks) |
| `src/core/rules/missions/` | `Mission` (data), `MissionState` (score, crippled, exited), `MissionFlow` (controller hooks), `Objective`/`ObjectiveControl`, `VictoryPoints`, `Crippled`, `ForcedWithdrawal`, `RandomDuration`, `MapEdges`, `StandardMissions` + `MissionLayouts` (the book's missions, `data/missions/standard.json`), `Complications` |
| `src/core/rules/terrain/` | `Fire` (burning hexes, smoke, lighting buildings), `WoodsFire` (flamers lighting woods), `Obscurant` (smoke/fog math), `Surfaces` (ice/mud/snow, conditions → map), `Avalanche` |
| `src/core/rules/turn/` | `Initiative`, `InitiativeDie` (optional rule), `UnequalNumbers` (who acts when), `EndPhase` |
| `src/core/explain/` | `ExplainLevel`, `Explainer` (event → log text per level), `WeaponText` (shot results), `ModsText`, `BvText`, `DamageText`/`HeatText`/`ConditionsText`/`PilotText`/`TerrainText`, `Advisor` (choice advice), `MissionText`, `RulesText` (original phase blurbs), `Names`, `Tutorial` (scenario lessons), `TrainingCampaign` (connected training games, `data/training/campaign.json`), `PlateInfo` (nameplate contents: sight, health, best to-hit) |
| `src/core/ai/` | `Bot` (plays a side via controller calls, announces reasons), `BotSkill` (computer levels Novice-Elite), `BotMove`, `BotFire`, `BotModes` (Ultra/LB-X), `BotPhysical` (punch/kick/melee weapons), `BotCharge` (charge/DFA value), `BotAim` (aimed shots), `BotNarc` (beacon tagging), `BotMasc` (when to engage MASC or a supercharger), `BotWithdraw` (Forced Withdrawal), `BotObjectives` (objectives, mission exits) |
| `src/core/forces/` | `ForceBuilder` (Battle Value budget, lances, deployment, balance text), `BattleValue` (simplified BV 2), `BvSkill` (pilot skill multiplier), `DesignFilter` (catalog: tech filter, OmniMech groups), `Deployment` (zones before turn 1) |
| `src/core/util/` | `Dice` (seedable), `MinHeap`, `JsonFile` |
| `src/view/hex_layout.gd` | Hex ↔ world space, level height, facing → yaw |
| `src/view/map/` | `MapView` (MultiMesh prisms per terrain), `HexMesh`, `WoodsProps` + `VxTrees` (voxel conifers/broadleaf, swaying `vx_foliage.gdshader`), `WaterSurfaces`, `BuildingProps` (voxel buildings, see-through with a 'Mech inside, cosmetic wall scars from hits) + `VxBuildingGen`/`VxBuildingStyles` (procedural voxel building per class), `GroundScatter` + `VxPlants` (voxel grass, flowers, bushes, rocks, rubble chunks), `FireProps` (looping voxel fire + soot, `vx_flame.gdshader`; fog), `ObjectiveMarkers`, `HexHighlighter`, `HexPicker` (tap → hex), `FacingMarker` |
| `src/view/shaders/terrain.gdshader` | Triplanar terrain; voxel-pixel ground pattern per `TerrainType.pattern` (grass, rocks, paving, rubble, riverbed, forest) |
| `src/view/units/` | `UnitView` (animation, prone/wreck pose), `UnitsLayer`, `Nameplates` (plates over 'Mechs the selected one sees), `SpriteMech` (sprite sets from `assets/mechs/`, see `docs/graphics/sprite-integration.md`), `PlaceholderMech` (fallback) |
| `src/view/vox/` | Claude's voxel 'Mechs (separate from the Voxel Mech Lab): `VxModel` (text format, `docs/graphics/voxel-model-format.md`), `VxRefine` (2× subdivide, bevels, seams), `VxPart` + `VxMesher` (greedy mesher), `VxDamage` (record sheet → voxels), `VxMech`, `VxGrid` (static voxel props → one mesh), `VxBlast` (one-shot voxel explosions, `vx_blast.gdshader`), `VxAnim` + `VxStrike` (attacks, flinch), `VxLegs`/`VxGait` (normal + reverse-jointed legs), `VxVolley`, `VxFx`/`VxTrails`, `VxShowcase` test scene |
| `src/view/camera/` | `CameraRig` (orbit/pan/zoom/tilt), `TouchGestures` (touch + mouse) |
| `src/view/settings/` | `GameSettings` (explanation level, computer level, saved to user://) |
| `src/view/hud/` | `BattleHud` (buttons/labels, emits intents only), `CombatLogView`, `RecordSheetView`, `AttackPanel`, `SafeArea`, `LessonCard` (tutorial cards), `SinkButtons` (heat sink switches) |
| `src/view/battle/` | `battle_scene.gd` (composition root, wiring only), `MovementInput`, `AttackInput` (weapon + physical phases), `AttackView` (its panel, tip and options), `AttackRows` (side-panel rows), `AimPicker` (aimed-shot button), `MascInput` (MASC button), `BotDriver` (runs computer sides), `BattleFx` (voxel blasts for hits, ammo explosions, kills, collapses; building wall scars), `BattleLaunch` |
| `src/view/menu/` | `ForceBuilderScreen` (start screen: map, budget, lances), `ForceCatalog` (its 'Mech list), `TrainingScreen` (training campaign list, rules notebook, saves results), `UiKit` |
| `data/` | `terrain.json`, `weapons.json`, `construction.json`, `bv_skill.json`, `units/*.json`, `maps/*.json`, `scenarios/*.json`, `missions/standard.json`, `voxels/*.json` — see `docs/data-formats.md` |
| `tests/` | `run_tests.gd` runner, `test_case.gd` base + fixtures, `LoadedDice` (scripted rolls), `fixtures/units/` (made-up loadouts for rule tests, ids `test_*`), `SimBot` (whole-game smoke test), `unit/test_*.gd` |
| `tools/capture.gd` | Render to PNG for visual checks (modes: select, attack, sheet, menu, clanmenu, map=<id>, tutorial, training, notebook) |
| `tools/design_report.gd` | Weight, armor, BV and free slots per design (`-- <id filter>`), for writing new designs |
| `tools/props_capture.gd` | Close-up PNG of map props (`-- out.png [map.json] [yaw] [dist] [hex]`) |
| `tools/ui_smoke.gd` | Plays turns through the battle scene's input handlers headless (CI); `-- city` also shoots buildings |
| `scenes/` | `menu.tscn` (main scene, force builder) → `main.tscn` (battle) |
| `docs/` | `architecture.md`, `rules-coverage.md`, `data-formats.md`, `PLANNING.md` (Android status, roadmap), `voxel-mech-prototype.md` (lab), `graphics/voxel-integration-plan.md` (voxel art into the battle) |
| `export_presets.cfg` | Android export preset; `.github/workflows/android.yml` builds an APK on manual run only |

## Commands
```sh
godot --headless --import                      # once per fresh clone (class cache)
godot --headless -s tests/run_tests.gd         # all tests; append `-- movement` to filter
godot --headless --quit-after 30               # smoke-run main scene, catches script errors
godot --headless -s tools/ui_smoke.gd          # play 4 turns through the battle UI
xvfb-run -a godot --rendering-method gl_compatibility --resolution 1280x720 \
  -s tools/capture.gd -- /tmp/shot.png attack  # screenshot (select|attack|sheet|menu)
```
Run tests + smoke run before every commit. CI runs both (`.github/workflows/ci.yml`).

## Conventions
- Coordinates: `Vector2i(q, r)` axial; move-search keys `Vector3i(q, r, facing)`.
- Levels are integers; water hexes: `level` = surface, `floor_level()` = bottom.
- Randomness only via the controller's `Dice` (seeded games replay identically).
- Explanation text is our own wording; never paste rulebook text.
- Mark unverified rules interpretations with `# TODO(rules): ...` and list them in rules-coverage.
- Use Godot 4.5 APIs; no C# (experimental on Android).
