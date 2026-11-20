class_name JumpPlanner
extends RefCounted
## Jumping (book p. 50): 1 MP per hex along any shortest path, landing facing
## any way, ignoring terrain costs. No hex on the way (or the landing hex) may
## be higher than the start level + jump MP; woods don't count, buildings do.
## In water the start level is the bottom; a 'Mech in depth 2+ can't jump and
## leg jump jets don't work in depth 1. It can't land on another 'Mech.
## Landing in depth 1+ water costs a piloting roll (MovePsr).
## TODO(rules): landing on building roofs isn't modeled, so building hexes
## can't be landed in.


static func plan(state: GameState, unit: Unit) -> MoveOptions:
	var opts := MoveOptions.new()
	opts.unit = unit
	opts.mode = MoveMode.Kind.JUMP
	opts.budget = jump_mp(state, unit)
	var start := opts.start_key()
	opts.cost[start] = 0
	opts.can_end[start] = true
	if opts.budget <= 0:
		return opts
	var from_tile := state.map.get_tile(unit.coord)
	var ceiling := (from_tile.floor_level() if from_tile else 0) + opts.budget
	var layer: Array[Vector2i] = [unit.coord]
	var seen := {unit.coord: true}
	for d in range(1, opts.budget + 1):
		var next: Array[Vector2i] = []
		for c in layer:
			for dir in 6:
				var n := Hex.neighbor(c, dir)
				if seen.has(n) or Hex.distance(unit.coord, n) != d:
					continue
				var tile := state.map.get_tile(n)
				if tile == null or _height(tile) > ceiling:
					continue
				seen[n] = true
				next.append(n)
				var ok := state.unit_at(n) == null and tile.building == null
				for f in 6:
					var k := MoveOptions.key(n, f)
					opts.cost[k] = d
					opts.prev[k] = start
					opts.can_end[k] = ok
		layer = next
	return opts


## Jump MP here: none from depth 2+ water, no leg jets in depth 1.
static func jump_mp(state: GameState, unit: Unit) -> int:
	if unit.prone:
		return 0
	var tile := state.map.get_tile(unit.coord)
	if tile != null and tile.is_water():
		if tile.depth >= 2:
			return 0
		return maxi(0, unit.jump_mp() - unit.leg_jump_jets())
	return unit.jump_mp()


## Ground height that limits a jump: hex level, plus a building's height.
static func _height(tile: MapTile) -> int:
	return tile.level + (tile.building.height if tile.building != null else 0)
