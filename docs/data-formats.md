# Data formats

## `data/terrain.json`
`{"terrain": [{"id", "token" (1 char), "name", "move_cost", "los_height"?, "water"?, "color", "detail_color"}]}`

Terrain tokens: `c` clear, `r` rough, `u` rubble, `L` light woods, `H` heavy woods,
`p` pavement, `w` water.

Also `"buildings": [{"id", "name", "cf", "move_cost", "psr_mod", "color"}]`: building
classes light, medium, heavy and hardened.

## `data/maps/<id>.json`
```json
{"name": "Test Valley", "rows": ["c0 L1 H2 r0 p0 w0d1 ..."]}
```
- One string per mapsheet row (YY), one space-separated token per column (XX).
- Token = terrain token + level, optional `d` + water depth: `c2` clear level 2,
  `w0d2` water surface level 0, depth 2.
- Columns use "odd-q" offset: even-numbered mapsheet columns (02, 04…) sit half a hex lower.
- Optional `"buildings": [{"hex": "0703", "type": "medium", "height": 2}]` puts a building
  of that class, `height` levels tall, on a hex. A collapsed building leaves rubble.

## `data/weapons.json`
`{"weapons": [{"id", "name", "type" (energy|ballistic|missile), "heat", "damage", "missiles"?,
"group"?, "min"?, "short", "medium", "long", "slots", "ammo_per_ton"?,
"bv", "ammo_bv"?}]}`
- `bv` is the weapon's Battle Value; `ammo_bv` is the value of one ton of its ammo.
- Ranges are the top of each bracket in hexes. `min` > 0 adds a minimum-range penalty.
- Missile weapons: `damage` is per missile, `missiles` is the rack size, `group` is the
  damage cluster (LRMs hit in groups of 5, SRMs missile by missile).

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
- Equipment items: a weapon id (`@rear` for rear-firing), `ammo:<weapon id>` (one ton),
  `heat_sink`, `jump_jet`. They fill free critical slots in the order listed, after the
  engine, gyro, cockpit and actuators (see `CritLayout`).
- `heat_sinks` is the total. The first 10 are inside the engine; list the rest as
  `heat_sink` items. A test checks heat sinks, jump jets and armor maximums.
- `sprite` names a folder under `assets/mechs/`; empty means the box placeholder.

## `data/scenarios/<id>.json`
```json
{"map": "test_valley", "units": [{"def": "atlas_as7d", "side": 0, "hex": "0616", "facing": 0}]}
```
`hex` is a mapsheet label; `facing` 0 = north, clockwise.
Optional: `"name"`, `"bot_sides"` (sides the computer plays) and `"lessons"` for a
guided scenario (see `data/scenarios/tutorial.json`): each lesson has `"event"` (a
`GameEvent` type), optional filters `"turn"`, `"phase"` (e.g. "Movement"),
`"unit_side"`, `"min_heat"`, and the `"title"` and `"text"` shown once.
