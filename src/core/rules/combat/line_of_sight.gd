class_name LineOfSight
extends RefCounted
## Line of sight between two units, with the woods it passes through.
## A 'Mech is two levels tall: its height is its floor level + 1 (prone: + 0).
## TODO(rules): simplified classic rules. A hill blocks if it is higher than
## both units; woods count if their top is at least as high as both units.
## A building blocks like a hill as tall as its roof.
## Divided LOS (line along hexsides) uses one side only (see Hex.line).

const WOODS_BLOCK := 3  ## Intervening woods points that block line of sight.


## {blocked: bool, reason: String, woods: int (intervening points),
##  light: int, heavy: int (counts of intervening woods hexes)}
static func check(map: BattleMap, from: Unit, to: Unit) -> Dictionary:
	var a := height_of(map, from)
	var t := height_of(map, to)
	var top := maxi(a, t)
	var out := {"blocked": false, "reason": "", "woods": 0, "light": 0, "heavy": 0}
	if _submerged(map, from) or _submerged(map, to):
		out["blocked"] = true
		out["reason"] = "underwater"
		return out
	var line := Hex.line(from.coord, to.coord)
	for i in range(1, line.size() - 1):
		var tile := map.get_tile(line[i])
		if tile == null:
			continue
		if tile.level > top:
			out["blocked"] = true
			out["reason"] = "hill at %s" % Hex.label(tile.coord)
			return out
		if tile.building != null and tile.level + tile.building.height > top:
			out["blocked"] = true
			out["reason"] = "building at %s" % Hex.label(tile.coord)
			return out
		var w := woods_value(tile)
		if w > 0 and tile.level + tile.terrain.los_height >= top:
			out["woods"] += w
			out["light" if w == 1 else "heavy"] += 1
	if out["woods"] >= WOODS_BLOCK:
		out["blocked"] = true
		out["reason"] = "%d points of woods in the way" % out["woods"]
	return out


static func height_of(map: BattleMap, u: Unit) -> int:
	var tile := map.get_tile(u.coord)
	var floor_lvl := tile.floor_level() if tile else 0
	return floor_lvl + (0 if u.prone else 1)


## Woods to-hit value of a hex: light 1, heavy 2.
static func woods_value(tile: MapTile) -> int:
	match tile.terrain.id:
		"light_woods":
			return 1
		"heavy_woods":
			return 2
	return 0


## Fully under water (depth 2+, or depth 1 while prone).
## TODO(rules): underwater combat is not modeled; such units can't be targeted.
static func _submerged(map: BattleMap, u: Unit) -> bool:
	var tile := map.get_tile(u.coord)
	if tile == null or not tile.is_water():
		return false
	return tile.depth >= 2 or (tile.depth == 1 and u.prone)
