class_name ObjectiveRaid
extends RefCounted
## Objective Raid setup (book p. 217): 1D6+6 potential objectives, placed
## in turn by the two sides, each at least 7 hexes from the placing side's
## home edge and 3 from any other counter. One roll sets every counter's
## control radius (1-3: 0, 4-6: 1); another makes them fragile (1-3),
## mobile (4-5) or both (6).
## TODO(rules): players choose the hexes; we pick them at random within the limits.

const HOME_GAP := 7
const SPACING := 3


static func place(m: Mission, map: BattleMap, dice: Dice, notes: Array) -> void:
	var n := dice.d6() + 6
	var radius := 0 if dice.d6() <= 3 else 1
	var v := dice.d6()
	var fragile := v <= 3 or v == 6
	var mobile := v >= 4
	var taken: Array[Vector2i] = []
	for i in n:
		var side := i % 2
		var pool: Array[Vector2i] = []
		for c: Vector2i in map.coords():
			if _ok(map, c, m.home_edge(side), taken):
				pool.append(c)
		if pool.is_empty():
			continue
		var c := pool[dice.pick(pool.size())]
		taken.append(c)
		var o := Objective.make(c, radius, -1, 1)
		o.potential = true
		o.fragile = fragile
		o.mobile = mobile
		m.objectives.append(o)
	notes.append("%d possible objectives, control radius %d, %s. Scan them to find the real ones." % [
			taken.size(), radius, "fragile and mobile" if fragile and mobile else ("fragile" if fragile else "mobile")])


static func _ok(map: BattleMap, c: Vector2i, edge: String, taken: Array[Vector2i]) -> bool:
	var t := map.get_tile(c)
	if t.is_water() and t.depth >= 2 or MapEdges.distance(map, c, edge) < HOME_GAP:
		return false
	for o in taken:
		if Hex.distance(c, o) < SPACING:
			return false
	return true
