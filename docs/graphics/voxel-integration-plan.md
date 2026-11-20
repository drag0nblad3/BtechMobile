# Voxel 'Mechs and buildings in the battle game: integration plan

**Status:** proposal, 2026-11-20. Nothing here is implemented yet.
**Starting point:** the Voxel Mech Lab (`docs/voxel-mech-prototype.md`,
`src/view/units/voxel_*.gd`, `scenes/voxel_mech_lab.tscn`), reachable from the launcher.
**Art:** Tyler authors the voxel models. Code ships only the loader, the damage mapping
and the animation hooks, plus the one lab test mech as a fallback.

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
| Model built in code (`fill_box` calls) | Models loaded from Tyler's files under `assets/voxels/<sprite>/` |
| ~2.6 units tall, 0.075 voxels | Fit the hex: about 1.8 units tall (a hex is 2 corner to corner, a level 0.45) |
| Damage = tap ray erases a ball | Damage = `DAMAGE` event erases toward a target fraction for that location |
| Limb snaps when its joint is shot away | Limb drops when the rules say the location is **destroyed** |
| Free physics debris, kept forever | Short, capped debris that freezes and fades |
| Walk test on a straight line | Gait driven by `UnitView.play_path`, matched to hex steps and turns |
| `voxel_mech.gd` 220 lines, lab-specific | Split into small classes (see §8) under the 150-line target |

The lab's mesher (hidden-face culling, per-part rebuild), its two-link IK gait and its
"armor shell over darker core" idea carry over as they are.

## 3. Model files (Tyler's side)

Proposed layout, mirroring the sprite sets so `UnitDef.sprite` picks both:

```
assets/voxels/<sprite>/manifest.json
assets/voxels/<sprite>/<part>.vox      (one MagicaVoxel model per part)
```

```json
{
  "chassis": "hunchback",
  "voxel_size": 0.05,
  "parts": {
    "ct":   {"file": "ct.vox",   "loc": "CT", "parent": null,   "pivot": [0, 1.20, 0]},
    "lt":   {"file": "lt.vox",   "loc": "LT", "parent": "ct",   "pivot": [-0.30, 0.10, 0]},
    "la":   {"file": "la.vox",   "loc": "LA", "parent": "lt",   "pivot": [-0.25, 0.15, 0], "joint": "shoulder"},
    "ll_thigh": {"file": "ll_thigh.vox", "loc": "LL", "parent": "ct", "pivot": [-0.2, -0.3, 0], "joint": "hip"},
    "ll_shin":  {"file": "ll_shin.vox",  "loc": "LL", "parent": "ll_thigh", "joint": "knee"},
    "ll_foot":  {"file": "ll_foot.vox",  "loc": "LL", "parent": "ll_shin",  "joint": "ankle"}
  },
  "palette_roles": {"armor": [1, 2], "structure": [3], "glow": [4], "faction": [5, 6]},
  "muzzles": {"RA": [0.0, -0.4, -0.5], "RT": [0.2, 0.3, -0.3]}
}
```

- **Parts** map many-to-one onto the 8 locations (a leg is thigh + shin + foot).
- **Palette roles** tell the damage code which voxels are armor plating, which are
  internal structure (exposed once armor is gone) and which take the faction color.
- **Muzzles** give a fire origin per location; weapons fire from `MountedWeapon.loc`.
- Reading `.vox` is a small, well-documented chunk format; a ~100-line `VoxFile`
  loader covers it. If Tyler uses another editor, we read that instead (question below).

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

- **Models:** `assets/voxels/buildings/<type>/manifest.json` with one `.vox` per
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

New files (view layer only, one class each, all under 150 lines):

| File | What |
|---|---|
| `src/view/voxels/vox_file.gd` | Reads a `.vox` model into cells + palette |
| `src/view/voxels/voxel_set.gd` | Loads a manifest, caches parsed parts per chassis |
| `src/view/voxels/voxel_part.gd` | Moved from `units/`; palette roles, shared material, surface lists |
| `src/view/voxels/voxel_rig.gd` | Builds the joint hierarchy from the manifest (from `VoxelMech.build_*`) |
| `src/view/voxels/voxel_damage.gd` | Location budgets, crater placement, `apply_state` |
| `src/view/voxels/voxel_debris.gd` | Detach, capped debris pool |
| `src/view/units/voxel_mech.gd` | Slimmed: the model `UnitView` holds, with the animation hooks |
| `src/view/units/voxel_anim.gd` | Walk/jump/fall/strike tweens over the rig |
| `src/view/battle/effect_queue.gd` | Plays fire/damage/crit/destroy events in order |
| `src/view/map/voxel_buildings.gd` | Replaces `BuildingProps` when building sets exist |

Unchanged: everything in `src/core`. The lab scene keeps working on the same classes.

## 9. Phases

Each phase is one PR with tests and a capture; none builds the APK.

1. **Refactor the lab into reusable pieces.** Split `VoxelMech`, move parts to
   `src/view/voxels/`, add HD/CT/LT/RT parts to the test mech, shared material. Lab
   looks the same. Tests: rig has a part for every location; erase is deterministic.
2. **Loader + manifest.** `VoxFile`, `VoxelSet`, manifest validation; the test mech
   rebuilt from files so Tyler has a working example to copy. Doc: "Dropping in voxel
   'Mechs" next to `sprite-integration.md`.
3. **Voxel model in the battle.** `UnitView` picks voxel → sprite → placeholder;
   `VoxelDamage.apply_state` on snap; walk gait during moves; prone/wreck poses.
   Capture mode `voxel` in `tools/capture.gd`; `ui_smoke` runs with voxels on.
4. **Animated combat.** `EffectQueue`; fire, craters per `DAMAGE` step, limb loss,
   ammo explosion, destroyed. Tests: state → same voxel counts with or without events.
5. **More motion.** Jump, fall, stand/fail, punch/kick/charge/DFA, shutdown, limping.
6. **Voxel buildings.** Stacked level models, scars, holes, collapse to rubble, cutaway.
7. **Phone pass.** Profile on device, greedy meshing if needed, debris and shadow
   tuning, the sprite fallback setting.

Phases 1-3 give a playable game with voxel 'Mechs that already show the right damage
when they appear; 4-6 add the show. 3 and 6 are independent once 2 is in.

## 10. Questions for Tyler

1. Which editor are the models made in (MagicaVoxel `.vox`, Qubicle, Goxel, something
   else)? That decides the loader.
2. One file per part (as above), or one file with named layers/groups per part?
3. Voxel size and target height you're working to, so the scale matches the hex.
4. Do the voxel models replace sprites outright, or should sprites stay as the
   low-end-phone option?
