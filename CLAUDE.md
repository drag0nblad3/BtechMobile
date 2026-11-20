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
- Prefer `Edit` over rewriting files. Keep comments short; `##` doc comment on each class.

## Layers (strict)
- `src/core/` — pure rules. `RefCounted` only, **no Nodes, no rendering, no input**.
  Only `GameController` mutates `GameState`; it emits `GameEvent`s.
- `src/view/` — Godot nodes. Reads state, animates events, turns input into controller calls.
  Never changes `GameState` directly.
- Dependencies point view → core, never core → view.

## File map
| Path | What |
|---|---|
| `src/core/hex/hex.gd` | Axial hex math, facings (0=N clockwise), mapsheet labels (XXYY, odd-q) |
| `src/core/map/` | `TerrainType`/`TerrainDb`, `MapTile` (level, depth, building), `BattleMap`, `MapLoader`, `BuildingType`/`Building` (CF, height) |
| `src/core/units/` | `UnitDef`/`UnitDb` (designs), `WeaponDef`/`WeaponDb`, `Unit` (live record sheet), `Location`, `StructureTable`, `CritLayout`/`CritSlot`, `MountedWeapon`, `AmmoBin`, `Pilot` |
| `src/core/state/` | `GameState`, `GameController` (turn flow, initiative, actions), `GameEvent`, `Phase`, `ScenarioLoader` |
| `src/core/rules/movement/` | `MoveMode` (walk/run/jump costs), `MoveCost` (per-hex MP), `MovePlanner` (Dijkstra over hex+facing, backward steps), `JumpPlanner`, `MoveOptions`, `MoveExecutor` (carries out a move for the controller) |
| `src/core/rules/combat/` | `LineOfSight`, `FiringArc`, `ToHit`/`ToHitCalc`, `FireOptions`, `WeaponFire`, `HitTable`, `ClusterTable`, `Damage`, `AmmoExplosion`, `CriticalHits`, `CritEffects` |
| `src/core/rules/heat/` | `HeatScale` (effects by heat level), `HeatPhase` |
| `src/core/rules/piloting/` | `Psr` (piloting rolls, standing up), `MovePsr` (rolls a move costs), `Fall`, `PilotDamage` |
| `src/core/rules/physical/` | `PhysicalOptions` (punch/kick/push), `Charge` (charge, DFA), `Displacement`, `PhysicalPhase` |
| `src/core/rules/buildings/` | `BuildingRules` (entering, wall absorption, collapse), `BuildingFire` (shooting buildings) |
| `src/core/rules/turn/` | `Initiative`, `EndPhase` |
| `src/core/explain/` | `ExplainLevel`, `Explainer` (event → log text per level), `ModsText`, `BvText`, `DamageText`/`HeatText`/`PilotText`/`TerrainText`, `Advisor` (choice advice), `RulesText` (original phase blurbs), `Names`, `Tutorial` (scenario lessons) |
| `src/core/ai/` | `Bot` (plays a side via controller calls, announces reasons), `BotMove`, `BotFire` |
| `src/core/forces/` | `ForceBuilder` (Battle Value budget, lances, deployment, balance text), `BattleValue` (simplified BV 2) |
| `src/core/util/` | `Dice` (seedable), `MinHeap`, `JsonFile` |
| `src/view/hex_layout.gd` | Hex ↔ world space, level height, facing → yaw |
| `src/view/map/` | `MapView` (MultiMesh prisms per terrain), `HexMesh`, `WoodsProps`, `WaterSurfaces`, `BuildingProps`, `HexHighlighter`, `HexPicker` (tap → hex), `FacingMarker` |
| `src/view/shaders/terrain.gdshader` | Triplanar noise terrain |
| `src/view/units/` | `UnitView` (animation, prone/wreck pose), `UnitsLayer`, `SpriteMech` (sprite sets from `assets/mechs/`, see `docs/graphics/sprite-integration.md`), `PlaceholderMech` (fallback) |
| `src/view/camera/` | `CameraRig` (orbit/pan/zoom/tilt), `TouchGestures` (touch + mouse) |
| `src/view/settings/` | `GameSettings` (explanation level, saved to user://) |
| `src/view/hud/` | `BattleHud` (buttons/labels, emits intents only), `CombatLogView`, `RecordSheetView`, `AttackPanel`, `SafeArea`, `LessonCard` (tutorial cards) |
| `src/view/battle/` | `battle_scene.gd` (composition root, wiring only), `MovementInput`, `AttackInput` (weapon + physical phases), `AttackRows` (side-panel rows), `BotDriver` (runs computer sides), `BattleLaunch` |
| `src/view/menu/` | `ForceBuilderScreen` (start screen: map, budget, lances), `UiKit` |
| `data/` | `terrain.json`, `weapons.json`, `units/*.json`, `maps/*.json`, `scenarios/*.json` — see `docs/data-formats.md` |
| `tests/` | `run_tests.gd` runner, `test_case.gd` base + fixtures, `LoadedDice` (scripted rolls), `SimBot` (whole-game smoke test), `unit/test_*.gd` |
| `tools/capture.gd` | Render to PNG for visual checks (modes: select, attack, sheet, menu, map=<id>, tutorial) |
| `tools/ui_smoke.gd` | Plays turns through the battle scene's input handlers headless (CI); `-- city` also shoots buildings |
| `scenes/` | `menu.tscn` (main scene, force builder) → `main.tscn` (battle) |
| `docs/` | `architecture.md`, `rules-coverage.md`, `data-formats.md`, `PLANNING.md` (Android status, roadmap) |
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
