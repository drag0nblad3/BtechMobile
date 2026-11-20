class_name JumpPlanner
extends RefCounted
## Jumping: land in any hex within jump MP (1 MP per hex, straight line),
## facing any way, ignoring terrain costs. Can't land on another 'Mech or in
## deep water, and can't clear anything taller than start level + jump MP.
## TODO(rules): verify elevation limits and landing in water.


static func plan(state: GameState, unit: Unit) -> MoveOptions:
	var opts := MoveOptions.new()
	opts.unit = unit
	opts.mode = MoveMode.Kind.JUMP
	opts.budget = MoveMode.budget(unit, MoveMode.Kind.JUMP)
	var start := opts.start_key()
	opts.cost[start] = 0
	opts.can_end[start] = true
	if opts.budget <= 0:
		return opts
	var from_tile := state.map.get_tile(unit.coord)
	var ceiling := (from_tile.level if from_tile else 0) + opts.budget
	for c: Vector2i in state.map.coords():
		var d := Hex.distance(unit.coord, c)
		if d == 0 or d > opts.budget or not _clear(state, unit.coord, c, ceiling):
			continue
		var tile := state.map.get_tile(c)
		var ok := tile.depth < 2 and state.unit_at(c) == null
		for f in 6:
			var k := MoveOptions.key(c, f)
			opts.cost[k] = d
			opts.prev[k] = start
			opts.can_end[k] = ok
	return opts


static func _clear(state: GameState, a: Vector2i, b: Vector2i, ceiling: int) -> bool:
	for c in Hex.line(a, b):
		var t := state.map.get_tile(c)
		if t and t.level + t.terrain.los_height > ceiling and c != a:
			return false
	return true
