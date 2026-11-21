# Data formats

## `data/terrain.json`
`{"terrain": [{"id", "token" (1 char), "name", "move_cost", "los_height"?, "water"?, "flammable"? (flamers can set it alight), "color", "detail_color"}]}`

Terrain tokens: `c` clear, `r` rough, `u` rubble, `L` light woods, `H` heavy woods,
`p` pavement, `w` water.

Also `"buildings": [{"id", "name", "civilian"?, "threshold", "destroy_tn", "entry_class", "roof_support"?, "fire_heat"?, "color"}]`:
building classes civilian, light, medium, heavy and hardened. `entry_class` is the lightest
weight class (0 light .. 3 assault) that may force its way in; `roof_support` is the
heaviest class its roof holds without a Destroy Check (none if missing); `fire_heat` is the
heat per building level that sets it alight.

## `data/maps/<id>.json`
```json
{"name": "Test Valley", "rows": ["c0 L1 H2 r0 p0 w0d1 ..."]}
```
- One string per mapsheet row (YY), one space-separated token per column (XX).
- Token = terrain token + level, optional `d` + water depth: `c2` clear level 2,
  `w0d2` water surface level 0, depth 2.
- Columns use "odd-q" offset: even-numbered mapsheet columns (02, 04…) sit half a hex lower.
- Optional `"fires": ["1005"]` sets hexes burning from the start.
- Optional `"buildings": [{"hex": "0703", "type": "medium", "height": 2}]` puts a building
  of that class, `height` levels tall, on a hex. A collapsed building leaves rubble.

## `data/weapons.json`
`{"weapons": [{"id", "name", "type" (energy|ballistic|missile), "heat", "damage", "missiles"?,
"group"?, "min"?, "short", "medium", "long", "slots", "ammo_per_ton"?,
"tons", "bv", "ammo_bv"?}]}`
- `tons` and `slots` follow the Core Rulebook weapon tables.
- `indirect: true` (LRMs) lets the weapon fire without line of sight through a spotter.
- `bv` is the weapon's Battle Value; `ammo_bv` is the value of one ton of its ammo.
- Ranges are the top of each bracket in hexes. `min` > 0 adds a minimum-range penalty.
- Missile weapons: `damage` is per missile, `missiles` is the rack size, `group` is the
  damage cluster (LRMs hit in groups of 5, SRMs missile by missile).
- `beacon: true` (Narc): a hit attaches a homing pod instead of damage; `ammo_damage` overrides
  the explosion damage per shot. Narc-equipped missiles are `ammo:<launcher>:narc`.
- `rapid`: most shots in one attack (Ultra ACs 2, rotary ACs 6); `rotary: true` lets it pick
  1-6 shots and jam (`RotaryAc`).
- `artemis_builtin: true` (ATMs) gives Artemis IV without an FCS item. `munitions: {"er": {"label", ...}}`
  lists alternative ammo that overrides any stats (damage, group, ranges); each loads from its own
  `ammo:<launcher>:<kind>` bins and is picked as the firing mode (`Atm`).
- `tech: "clan"` marks Clan versions; their ids start `c_` (`c_er_medium_laser`) and keep the
  book's names. `to_hit` is the weapon's own modifier (pulse -2, ER pulse -1, heavy lasers +1).

## `data/bv_skill.json`
`{"multipliers": [[...9 numbers...] x 9]}`: row = gunnery 0-8, column = piloting 0-8;
the unit's Battle Value is multiplied by the entry for its pilot (4/5 = 1.0).

## `data/units/<id>.json`
```json
{"id": "atlas_as7d", "name": "Atlas", "model": "AS7-D", "tonnage": 100,
 "walk_mp": 3, "jump_mp": 0, "heat_sinks": 20, "sprite": "atlas", "role": "one line",
 "armor": {"HD": 9, "CT": 47, "LT": 32, "RT": 32, "LA": 34, "RA": 34, "LL": 41, "RL": 41},
 "rear_armor": {"CT": 14, "LT": 10, "RT": 10},
 "missing_actuators": {"LA": ["lower_arm", "hand"]},
 "equipment": {"RT": ["ac20", "ammo:ac20"], "CT": ["medium_laser@rear"], "LL": ["heat_sink"]}}
```
- Location codes: `HD CT LT RT LA RA LL RL`. Internal structure comes from tonnage.
- Equipment items: a weapon id (`@rear` for rear-firing, `+artemis` for a launcher with
  Artemis IV), `ammo:<weapon id>` (one ton; `ammo:<id>:cluster` for LB-X cluster rounds),
  `heat_sink`, `jump_jet`, `ams` (anti-missile system; give it `ammo:ams`), `targeting_computer` (its slots are sized automatically), `guardian_ecm` (Guardian ECM suite, 1.5 t, 2 slots), `masc` (MASC; tons and slots sized automatically: tonnage / 20, Clan / 25), `c3_master` (C3 Master, 5 t, 5 slots), `c3_slave` (C3 Slave, 1 t, 1 slot), `supercharger` (1 slot, sized automatically: engine tons / 10), `tsm` (triple-strength myomer: list six `tsm` slots, e.g. `"tsm*3"`; no weight). They fill free critical slots in the order listed, after the
  engine, gyro, cockpit and actuators (see `CritLayout`).
- `heat_sinks` is the total. The first 10 are inside the engine and weigh nothing; an engine of
  rating 275+ holds rating/25 without slots (`DesignWeight.engine_sink_capacity`). List the rest as
  `heat_sink` items. `"heat_sink_type": "double"` makes them all doubles (2 heat,
  3 slots each). A `case` item puts CASE in that location. `hatchet` or `sword` in an arm mounts that physical weapon.
  `"engine_type": "xl"` puts 3 engine slots in each side torso; `"structure_type": "endo_steel"`
  and `"armor_type": "ferro_fibrous"` need their bulky slots listed as `endo_steel` /
  `ferro_fibrous` items (14 each for Inner Sphere, 7 for Clan; `"endo_steel*7"` repeats an item). A test checks heat sinks, jump jets and armor maximums.
- `"quad": true`: a four-legged 'Mech. Its armor and equipment use `FLL`, `FRL`, `RLL`, `RRL`
  for the legs (the front legs live in the arm slots; `LA`/`RA` also work). Every leg has 6 slots
  and leg actuators; structure for the front legs comes from the leg column.
- `"tech_base": "clan"` (ClanTech): XL engines take 2 slots a side, double heat sinks 2 slots,
  CASE is free in every location (don't list `case`), ferro-fibrous gives 19.2 points a ton and a
  targeting computer 1 t per 5 t of linked weapons. Use Clan weapons (`c_*`).
- OmniMechs (`OmniConfig`): one file per chassis with `"configs": [{"model": "Prime", "equipment": {...}, ...}]`.
  The top level holds the fixed parts (engine, armor, structure, fixed `equipment` such as
  endo/ferro slots); each config adds its pod `equipment` per location and may override any
  other key (`heat_sinks`, `jump_mp`, `role`, `heat_sink_type`). Each config becomes design
  `<id>_<model>` (`timber_wolf_prime`) with `omni`, `chassis` and `config` set.
- The design must weigh its tonnage (test): structure 10%, engine by rating
  (`data/construction.json`, rating = tonnage × walk MP), gyro rating/100 rounded up,
  XL half, endo steel structure half, cockpit 3, 1 t per heat sink over 10, jump jets 0.5/1/2 t by weight class, 16 armor
  points per ton (17.92 ferro-fibrous, rounded up to the half ton), weapon tons, 1 t per ammo item.
- `sprite` names a folder under `assets/mechs/`; empty means the box placeholder.

Maps may also list `"surface": {"ice": ["XXYY"], "mud": [...], "snow": [...]}` (p. 124) and `"fog": {"light": ["XXYY"], "heavy": ["XXYY"]}` (fog banks, book p. 124).

## `data/scenarios/<id>.json`
```json
{"map": "test_valley", "units": [{"def": "atlas_as7d", "side": 0, "hex": "0616", "facing": 0}]}
```
`hex` is a mapsheet label; `facing` 0 = north, clockwise.
Optional: `"name"`, `"bot_sides"` (sides the computer plays) and `"lessons"` for a
guided scenario (see `data/scenarios/tutorial.json`): each lesson has `"event"` (a
`GameEvent` type), optional filters `"turn"`, `"phase"` (e.g. "Movement"),
`"unit_side"`, `"min_heat"`, and the `"title"` and `"text"` shown once.
Optional `"conditions"` (battlefield conditions, book pp. 120-121), e.g.
`{"cold": 2, "gravity": 0.8, "night": true}`: `cold` / `heat` are Extreme Cold / Heat
levels 0-3, `gravity` is in G (rounded to 0.1), and the flags `low_visibility`, `wind`,
`rain`, `snowfall`, `night` switch those conditions on.
Optional `"mission"` (book pp. 212-233; see `Mission`): `name`, `summary`, `turns`
(0 = no limit), `random_duration`, `victory` (`"last_standing"` or `"vp"`), `unit_vp`,
`forced_withdrawal`, `scoring` (`"each"`, `"pairs"`, `"threshold"`), `objectives`
(`[{"hex", "radius", "owner", "vp"}]`), `home_edges` (per side: `north`/`south`/`east`/`west`),
`exit` (`"home"` or `"enemy_home"`: the edge units may leave by to score) and `exit_from_turn`.
