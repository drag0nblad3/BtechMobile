class_name LineOfSight
extends RefCounted
## Line of sight between two units (book pp. 56-58, 66).
## LOS level = the ground under a 'Mech (water: the bottom) + its height
## (2 standing, 1 prone); water never blocks, an intervening water hex counts
## from its bottom. A hex between them intervenes if its top (hill
## level; woods +2; a building's roof) is at least both LOS levels, or at
## least the attacker's and next to it, or at least the target's and next
## to it. An intervening hill or building blocks; woods add 1 (light) or 2
## (heavy) and 3 points block. Adjacent 'Mechs always see each other.
## On a line along a hexside the target's side picks the hexes: we take the
## side worse for the attacker.
## Partial cover: a standing target next to a hex one level above its own
## ground, on the line, unless the attacker's LOS level is higher.

const WOODS_BLOCK := 3  ## Intervening woods points that block line of sight.


## {blocked, reason, woods (points), light, heavy (hex counts),
##  cover: Vector2i (hex giving partial cover, or Hex.INVALID)}
static func check(map: BattleMap, from: Unit, to: Unit) -> Dictionary:
	var t_floor := Roofs.floor_of(map, to)
	return _best(map, from.coord, to.coord, los_level(map, from), los_level(map, to),
			t_floor if not to.prone else 999)


## Line of sight from a unit to a building hex whose roof is at `height`.
static func check_hex(map: BattleMap, from: Unit, c: Vector2i, height: int) -> Dictionary:
	if _submerged(map, from):
		var out := _blank()
		out["blocked"] = true
		out["reason"] = "underwater"
		return out
	return _best(map, from.coord, c, los_level(map, from), height, 999)


static func los_level(map: BattleMap, u: Unit) -> int:
	return Roofs.floor_of(map, u) + (1 if u.prone else 2)


## Kept for callers that want the top level a 'Mech occupies.
static func height_of(map: BattleMap, u: Unit) -> int:
	return los_level(map, u) - 1


## Woods to-hit value of a hex: light 1, heavy 2.
static func woods_value(tile: MapTile) -> int:
	match tile.terrain.id:
		"light_woods":
			return 1
		"heavy_woods":
			return 2
	return 0


## Traces both sides of a divided line and keeps the one worse for the attacker.
static func _best(map: BattleMap, a: Vector2i, b: Vector2i, a_lvl: int, b_lvl: int, cover_floor: int) -> Dictionary:
	var r1 := _trace(map, Hex.line(a, b), a_lvl, b_lvl, cover_floor)
	var alt := Hex.line(a, b, -1.0)
	if alt == Hex.line(a, b):
		return r1
	var r2 := _trace(map, alt, a_lvl, b_lvl, cover_floor)
	if r1["blocked"] != r2["blocked"]:
		return r1 if r1["blocked"] else r2
	if int(r1["woods"]) != int(r2["woods"]):
		return r1 if int(r1["woods"]) > int(r2["woods"]) else r2
	return r2 if r1["cover"] == Hex.INVALID else r1


static func _trace(map: BattleMap, line: Array[Vector2i], a_lvl: int, b_lvl: int, cover_floor: int) -> Dictionary:
	var out := _blank()
	var n := line.size()
	for i in range(1, n - 1):
		var tile := map.get_tile(line[i])
		if tile == null:
			continue
		var next_a := i == 1
		var next_b := i == n - 2
		var ground := tile.floor_level() + (tile.building.height if tile.building != null else 0)
		if _intervenes(ground, a_lvl, b_lvl, next_a, next_b):
			out["blocked"] = true
			out["reason"] = "%s at %s" % ["building" if tile.building != null else "hill", Hex.label(tile.coord)]
			return out
		var w := woods_value(tile)
		if w > 0 and _intervenes(tile.level + tile.terrain.los_height, a_lvl, b_lvl, next_a, next_b):
			out["woods"] += w
			out["light" if w == 1 else "heavy"] += 1
		if next_b and ground == cover_floor + 1 and a_lvl <= b_lvl \
				and (tile.building == null or not tile.building.type.civilian):
			out["cover"] = tile.coord
	if out["woods"] >= WOODS_BLOCK:
		out["blocked"] = true
		out["reason"] = "%d points of woods in the way" % out["woods"]
	return out


static func _intervenes(top: int, a_lvl: int, b_lvl: int, next_a: bool, next_b: bool) -> bool:
	return (top >= a_lvl and top >= b_lvl) or (next_a and top >= a_lvl) or (next_b and top >= b_lvl)


static func _blank() -> Dictionary:
	return {"blocked": false, "reason": "", "woods": 0, "light": 0, "heavy": 0, "cover": Hex.INVALID}


## Fully under water: it can't shoot a building across the water line.
static func _submerged(map: BattleMap, u: Unit) -> bool:
	var tile := map.get_tile(u.coord)
	if tile == null or not tile.is_water():
		return false
	return tile.depth >= 2 or (tile.depth == 1 and u.prone)
