class_name SteelRain
extends RefCounted
## Steel Rain setup (book p. 218): the defender places five mobile
## objectives (control radius 0), at least 5 hexes from each other and from
## both home edges. The attacker deploys normally and may carry objectives
## off by its home edge; the defender's 'Mechs combat drop, half (rounded
## up) on turn 1 and the rest on turn 2.
## TODO(rules): counter hexes are picked at random within the limits.

const COUNTERS := 5
const GAP := 5


static func place(m: Mission, out: Dictionary, map: BattleMap, att: int, dice: Dice) -> void:
	m.attacker = att
	m.exit = "home"
	m.exit_side = att
	m.exit_from_turn = 1
	m.scoring = "steel_rain"
	out["drop"] = 1 - att
	var taken: Array[Vector2i] = []
	for i in COUNTERS:
		var pool: Array[Vector2i] = []
		for c: Vector2i in map.coords():
			if _ok(map, m, c, taken):
				pool.append(c)
		if pool.is_empty():
			break
		var c := pool[dice.pick(pool.size())]
		taken.append(c)
		var o := Objective.make(c, 0, 1 - att, 1)
		o.mobile = true
		m.objectives.append(o)
	out["notes"].append("%s raids five supply caches and may carry them off by its home edge; %s drops from orbit (half on turn 1, the rest on turn 2)." % [
			Names.side(att), Names.side(1 - att)])


static func _ok(map: BattleMap, m: Mission, c: Vector2i, taken: Array[Vector2i]) -> bool:
	var t := map.get_tile(c)
	if t.is_water() and t.depth >= 2:
		return false
	for side in 2:
		if MapEdges.distance(map, c, m.home_edge(side)) < GAP:
			return false
	for o in taken:
		if Hex.distance(c, o) < GAP:
			return false
	return true


## Puts the dropping side's 'Mechs in reserve.
static func reserve_side(state: GameState, side: int) -> void:
	var mine := state.units_of_side(side)
	var first := ceili(mine.size() / 2.0)
	for i in mine.size():
		CombatDrop.reserve(state, mine[i], 1 if i < first else 2)
