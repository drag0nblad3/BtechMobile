class_name Avalanche
extends RefCounted
## Avalanches (book p. 125, errata p. 125). A 'Mech that falls in a snow hex
## next to a lower hex slides into one (a snow hex first, else at random);
## that step sets its direction. While it lands in snow and the next hex
## that way is lower still, it makes a piloting roll (only its own damage
## modifiers) and slides on if it fails. One fall is resolved at the end:
## the starting levels, plus the height dropped, plus 1 per heavy woods hex
## it slid into. TODO(rules): sliding into another 'Mech (domino effect) —
## the slide stops short of an occupied hex.


## Slides `u` if its fall starts an avalanche. Returns the levels to fall.
static func slide(state: GameState, dice: Dice, emit: Callable, u: Unit, levels: int) -> int:
	var start := state.map.get_tile(u.coord)
	if start == null or start.surface != Surfaces.SNOW:
		return levels
	var lower := _lower_neighbors(state, u.coord)
	if lower.is_empty():
		return levels
	var snowy := lower.filter(func(c: Vector2i) -> bool: return state.map.get_tile(c).surface == Surfaces.SNOW)
	var pool := snowy if not snowy.is_empty() else lower
	var next: Vector2i = pool[dice.pick(pool.size())]
	var dir := Hex.direction_to(u.coord, next)
	var path: Array[Vector3i] = []
	var woods := 0
	var from := MoveOptions.key(u.coord, u.facing)
	while true:
		path.append(MoveOptions.key(next, u.facing))
		var tile := state.map.get_tile(next)
		if tile.terrain.id == "heavy_woods":
			woods += 1
		if tile.surface != Surfaces.SNOW:
			break
		var after := Hex.neighbor(next, dir)
		var at := state.map.get_tile(after)
		if at == null or at.floor_level() >= tile.floor_level() or state.unit_at(after) != null:
			break
		if Psr.roll(dice, emit, u, "sliding in an avalanche", 0):
			break
		next = after
	var end := MoveOptions.coord_of(path[-1])
	var drop := start.floor_level() - state.map.get_tile(end).floor_level()
	u.coord = end
	emit.call(GameEvent.DISPLACED, {"unit_id": u.id, "from": from, "path": path, "why": "avalanche"})
	return levels + drop + woods


static func _lower_neighbors(state: GameState, c: Vector2i) -> Array:
	var here := state.map.get_tile(c).floor_level()
	var out := []
	for d in 6:
		var n := Hex.neighbor(c, d)
		var t := state.map.get_tile(n)
		if t != null and t.floor_level() < here and state.unit_at(n) == null:
			out.append(n)
	return out
