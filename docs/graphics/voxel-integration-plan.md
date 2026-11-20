# Voxel 'Mechs and buildings in the battle game: integration plan

**Status:** proposal, 2026-11-20. Nothing here is implemented yet.
**Starting point:** the Voxel Mech Lab (`docs/voxel-mech-prototype.md`,
`src/view/units/voxel_*.gd`, `scenes/voxel_mech_lab.tscn`), reachable from the launcher.
**Art:** Tyler is building one version of the voxel models with another AI. Claude built a
second version in `src/view/vox/` that uses a plain-text model format (no outside editor) and
a Hunchback model, so the two can be compared. **Update, same day:** §3 now describes that
format. The other build (Voxel Mech Lab files) is untouched.

## 1. Ground rules

1. **The rules engine stays the source of truth.** Voxel loss is cosmetic. Nothing in
   `src/view` reads a voxel count to decide a game result, and nothing in `src/core`
   learns that voxels exist. The view turns `GameEvent`s and `Unit` state into visuals.
2. **The picture must agree with the record sheet.** At any moment, a location's look is
   a function of that location's armor and internal structure left (and whether it is
   destroyed). Animations add drama on the way there; they never decide where it ends.
3. **Same game, same scars.** Crater placement uses its own RNG seeded from
   `(unit id, event index)`, never the controller's `Dice`, so seeded replays look
   identical and cosmetic rolls can't change rules rolls.
4. **Three looks coexist.** Model choice per unit: voxel set if one exists, else sprite
   set, else `PlaceholderMech`. A setting can force sprites on weak phones.

## 2. What the lab has, and what the game needs from it

| Lab today | Needed in the battle |
|---|---|
| One `Torso` part, no head | Separate **HD, CT, LT, RT** parts so all 8 locations can show damage |
| Model built in code (`fill_box` calls) | Models loaded from text files in `data/voxels/` (§3) |
| ~2.6 units tall, 0.075 voxels | Fit the hex: about 1.8 units tall (a hex is 2 corner to corner, a level 0.45) |
| Damage = tap ray erases a ball | Damage = `DAMAGE` event erases toward a target fraction for that location |
| Limb snaps when its joint is shot away | Limb drops when the rules say the location is **destroyed** |
| Free physics debris, kept forever | Short, capped debris that freezes and fades |
| Walk test on a straight line | Gait driven by `UnitView.play_path`, matched to hex steps and turns |
| `voxel_mech.gd` 220 lines, lab-specific | Split into small classes (see §8) under the 150-line target |

The lab's mesher (hidden-face culling, per-part rebuild), its two-link IK gait and its
"armor shell over darker core" idea carry over as they are.

## 3. Model files: plain text, no editor

Tyler would rather not use outside tools such as MagicaVoxel, so models are JSON
**box recipes** in `data/voxels/<sprite>.json`, fully described in
[`voxel-model-format.md`](voxel-model-format.md). In short:

- One shared grid (x right, y up, -z front). Each part is a list of `box`, `shell` (armor
  layer over a frame core) and `erase` steps, tagged with its hit location, parent and joint.
- Left/right parts are written once and `mirror`ed. The Hunchback's hunch is a mirrored
  left torso plus `add` shapes.
- Material roles (`armor` / `structure`) tell the damage code what to chip away first.
- `muzzles` give fire origins per location.
- Any AI (or person) can write or edit these as text, and git diffs stay readable. The file
  `data/voxels/hunchback.json` is about 50 lines for about 6,200 voxels.

Defaults chosen instead of asking: one JSON file per design, named after the unit's `sprite`
field; voxel size 0.05 (a 'Mech about 1.85 units tall, just under a hex); the sprite loader
stays as the fallback for designs with no voxel model and for slow phones.

## 4. Damage: rules → voxels

### Per location
Each location keeps two cosmetic budgets, recomputed from the `Unit` record:

- `armor_lost = 1 - armor_left / armor_max` (front and rear tracked separately for
  CT/LT/RT, so rear hits scar the back)
- `structure_lost = 1 - structure_left / structure_max`

| Rules state | Look |
|---|---|
| Armor partly gone | Craters in the armor-role voxels until that fraction of them is removed |
| Armor gone | Plating stripped across most of the face; structure-role voxels visible |
| Structure damaged | Craters bite into structure voxels; sparks/smoke emitter on that part |
| Arm or leg destroyed | The limb (and everything below its joint) drops off as debris |
| Side torso destroyed | Most of that torso part blown away; its arm drops (`Location.arm_of_torso`) |
| Head destroyed | Cockpit part erased to its frame |
| CT destroyed / engine kill | Wreck pose: collapse, scorch tint, smoke column |
| Ammo explosion (`AMMO_EXPLOSION`) | Inner burst from that location, extra debris |
| Critical (`CRITICAL`) on a weapon | Barrel voxels at that muzzle knocked off (optional, phase 3) |

### Where craters land
For a `DAMAGE` event: pick the surface of the struck part that faces the attacker
(front or rear by the event's `rear` flag), choose a deterministic point there, erase a
ball sized by damage (e.g. 2 voxels radius per 5 points), then keep eroding until the
location's armor/structure budget is met. Each `steps` entry of a transferred hit
scars its own location. Cluster weapons become several small craters.

### Rebuilding from state
`VoxelDamage.apply_state(unit)` reaches the same picture with no animation (scenario
load, `snap_to_state`, explanation-level changes). Events animate; state decides.

### Timing
Today `battle_scene._on_event` calls `refresh_unit`, which reads the **final** state.
With animated hits, damage must play in order: add a small view-side `EffectQueue`
that plays `WEAPON_FIRED → DAMAGE → CRITICAL → UNIT_DESTROYED` one after another and
holds `UnitsLayer.is_busy()` until done. The bot driver already waits on `busy`.

## 5. Animation hooks

All hooks live on the voxel model and are called by `UnitView`; sprite and placeholder
models get no-op versions so `UnitView` never checks which kind it holds.

| Trigger | Hook | Notes |
|---|---|---|
| `UNIT_MOVED` walk/run, `DISPLACED` | `walk(seconds, run)` | Gait phase advances with the tween; run = shorter cycle. Turns in place = short shuffle |
| `UNIT_MOVED` mode jump | `jump(from, to)` | Crouch, rise on an arc, land with a knee bend |
| Backward steps | `walk(..., reverse)` | Gait phase runs backward |
| `FALL` | `fall(levels)` | Tip toward a side, then `show_condition` prone pose |
| `WENT_PRONE`, `STAND` (ok/failed) | `go_prone()`, `stand_up(ok)` | Failed stand = rise and slump back |
| `WEAPON_FIRED` | `fire(loc, target_pos, weapon)` | Torso turns to target, muzzle flash at `muzzles[loc]`, tracer/missile trail |
| `PHYSICAL` punch/kick/club | `strike(kind, limb)` | Arm or leg swing; push/charge reuse walk + lean |
| `CHARGE_DECLARED` charge/DFA | `charge()`, `jump()` + slam | |
| `SHUTDOWN` | `power(off)` | Glow-role voxels dim, head droops |
| Heat level | `heat(level)` | Optional shimmer/tint on glow voxels |
| `UNIT_DESTROYED` | `wreck(reason)` | Collapse, smoke |
| Limb gone | (state) | Walk keeps going on a destroyed leg as a hop/limp |

`VoxelGait` stays a pure static function; its stride is retuned so one walk cycle spans
two hexes at `UnitView.STEP_TIME`.

## 6. Buildings

The rules give buildings **no damage track** (book pp. 130-137 as implemented): hits only
earn a Destroy Check, and a destroyed hex becomes rubble. The visuals follow the events:

| Event (`GameEvent.BUILDING` kind) | Look |
|---|---|
| `shot`, `cover_hit` with damage | Crater on the wall facing the shooter; scars build up but never imply collapse |
| `destroy_check` passed | Bigger chunk out, dust |
| `collapsed` | Upper voxels fall level by level, then settle into a rubble pile; `map_view.rebuild()` swaps terrain |
| `flattened` (civilian) | Squashed flat under the 'Mech |
| `smash`, `entry_failed`, `shoved_in` | Hole punched in the wall on the side the 'Mech came from |
| `fire` / `MapTile.on_fire` | Existing `FireProps` flames plus scorched voxel tint |

- **Models:** `data/voxels/buildings/<type>.json` in the same text format, one part per
  level slice (ground, middle, roof), stacked to `Building.height`. Building type colors
  stay as a tint on the faction/role palette.
- **'Mechs inside:** today's see-through blocks keep a 'Mech visible. Voxel buildings
  need a cutaway: when a unit stands in the hex (or the camera is low), hide levels
  above the unit's and fade the near walls.
- **Scars aren't saved:** cosmetic building damage lives only in the view. That's fine
  until there are save games; then store a small per-hex scar seed next to the save.

## 7. Phone performance

The lab test mech is a few thousand voxels across 11 parts. Budgets to hold on Android
(Mobile renderer), to be measured on Tyler's phone, not guessed:

| Item | Budget / approach |
|---|---|
| Voxels per 'Mech | ≤ 6,000 at 0.05 size; tune `voxel_size` per chassis weight |
| Triangles per 'Mech | ≤ 15k after face culling; add greedy meshing if over |
| Draw calls | One shared material for all voxel parts (palette texture, not per-part materials): ≈ 12 parts × 12 'Mechs ≈ 150 |
| Mesh rebuild | Only the struck part, at most one rebuild per part per frame; spread an event's craters over frames |
| Erase cost | Index voxels by part once at load; erase walks a precomputed surface list, not every cell |
| Debris | Max 8 rigid bodies on the map; freeze after 2 s, fade after 10 s, oldest removed first |
| Picking | Not needed in battle (rules choose the location); keep `pick_ray` lab-only |
| Shadows | One directional shadow, short distance; voxel models don't cast at Map View zoom |
| Fallback | Setting "'Mech models: voxel / sprite"; auto-suggest sprites if frame time stays > 33 ms |

Godot 4.5's GDScript is fast enough for culled meshing of a few thousand cells per hit;
if profiling says otherwise, the mesher is the one piece worth moving to a compute or
precomputed-chunk approach (still no C#).

## 8. Code shape

Claude's version already follows this layout (see §10): everything lives in `src/view/vox/`,
in one class per file, and nothing in `src/core` changes. Still to add:

| File | What |
|---|---|
| `src/view/units/unit_view.gd` (edit) | Picks `VxMech` when `data/voxels/<sprite>.json` exists, else sprite, else placeholder |
| `src/view/battle/effect_queue.gd` | Plays fire/damage/crit/destroy events in order |
| `src/view/map/vx_buildings.gd` | Replaces `BuildingProps` when building models exist |

## 9. Phases

Each phase is one PR with tests and a capture; none builds the APK.

1. ~~Reusable pieces with all 8 locations~~ (done in Claude's version).
2. ~~Loader + text format + example model~~ (done: `VxModel`, `hunchback.json`).
3. **Voxel model in the battle.** `UnitView` picks voxel → sprite → placeholder;
   `VxMech.show_unit` on snap; walk gait during moves; prone/wreck poses.
   Capture mode `voxel` in `tools/capture.gd`; `ui_smoke` runs with voxels on.
4. **Animated combat.** `EffectQueue`; fire from the weapon's location, craters per
   `DAMAGE` step, limb loss, ammo explosion, destroyed. (Hooks and effects exist.)
5. **More motion.** Charge/DFA, shutdown, limping on a damaged leg. (Walk, run, jump,
   fall, stand, punch and kick exist.)
6. **Voxel buildings.** Stacked level models in the same text format, scars, holes,
   collapse to rubble, cutaway.
7. **Phone pass.** Profile on device, greedy meshing if needed, debris and shadow
   tuning, the sprite fallback setting.
8. **More 'Mechs.** One JSON per design, starting with the most-used ones.

## 10. What is already built (Claude's version)

Phases 1, 2 and most of 4 and 5 exist as a stand-alone test scene, not yet in the battle:

| File | What |
|---|---|
| `data/voxels/hunchback.json` | Hunchback HBK-4G, all 8 locations, ~6,200 voxels, ~10,600 triangles |
| `src/view/vox/vx_model.gd` | Reads and checks the text format (mirror, add, errors) |
| `src/view/vox/vx_part.gd` | Culled-face mesher, one shared material, scorched edges, no floating voxels |
| `src/view/vox/vx_damage.gd` | Record sheet → voxels (seeded crater order per location) |
| `src/view/vox/vx_mech.gd` | Builds the rig, shows a `Unit`, drops destroyed limbs, muzzles |
| `src/view/vox/vx_anim.gd`, `vx_gait.gd` | Walk/run gait, jump, fall, stand (and failed stand), punch, kick, torso twist + recoil |
| `src/view/vox/vx_fx.gd` | Muzzle flash, laser beam, cannon shell, impact smoke |
| `src/view/vox/vx_showcase.gd`, `vx_stage.gd` | Test scene: hits go through the real `HitTable` and `Damage` on a live `Unit` |
| `tests/unit/test_vx_model.gd` | Format, mirror, record-sheet mapping, limb loss, leg solve |
| `tools/capture_vx.gd` | Screenshots for review |

Still to do: hook `VxMech` into `UnitView` (phase 3), the `EffectQueue` (phase 4), voxel
buildings (phase 6) and the phone profiling pass (phase 7).
