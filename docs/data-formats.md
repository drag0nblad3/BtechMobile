# Data formats

## `data/terrain.json`
`{"terrain": [{"id", "token" (1 char), "name", "move_cost", "los_height"?, "water"?, "color", "detail_color"}]}`

## `data/maps/<id>.json`
```json
{"name": "Test Valley", "rows": ["c0 L1 H2 r0 p0 w0d1 ..."]}
```
- One string per mapsheet row (YY), one space-separated token per column (XX).
- Token = terrain token + level, optional `d` + water depth: `c2` clear level 2,
  `w0d2` water surface level 0, depth 2.
- Columns use "odd-q" offset: even-numbered mapsheet columns (02, 04…) sit half a hex lower.

## `data/units/<id>.json`
`{"id", "name", "model", "tonnage", "walk_mp", "jump_mp"}` — grows with armor/weapons later.

## `data/scenarios/<id>.json`
```json
{"map": "test_valley", "units": [{"def": "atlas_as7d", "side": 0, "hex": "0616", "facing": 0}]}
```
`hex` is a mapsheet label; `facing` 0 = north, clockwise.
