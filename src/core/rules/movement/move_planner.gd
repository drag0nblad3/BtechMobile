class_name MovePlanner
extends RefCounted
## Finds every reachable (hex, facing) for a unit with Dijkstra search.
## Steps: turn one hexside left/right (1 MP), move forward into the faced
## hex, or (walking only) back into the hex behind (MoveCost).
## Jumping is a separate search (JumpPlanner).


static func plan(state: GameState, unit: Unit, mode: int) -> MoveOptions:
	if mode == MoveMode.Kind.JUMP:
		return JumpPlanner.plan(state, unit)
	var opts := MoveOptions.new()
	opts.unit = unit
	opts.mode = mode
	opts.budget = MoveMode.budget(unit, mode)
	var start := opts.start_key()
	opts.cost[start] = 0
	opts.can_end[start] = true
	var heap := MinHeap.new()
	heap.push(0, start)
	if unit.prone and opts.budget >= 0 and Psr.can_stand(unit):
		# Standing up (2 MP, already taken off the budget) lets it face any way.
		for f in 6:
			var sk := MoveOptions.key(unit.coord, f)
			if sk != start:
				opts.cost[sk] = 0
				opts.prev[sk] = start
				opts.can_end[sk] = true
				heap.push(0, sk)
	while not heap.is_empty():
		var top := heap.pop()
		var g: int = top[0]
		var k: Vector3i = top[1]
		if g > opts.cost[k]:
			continue
		for step in _successors(state, unit, k, mode):
			var nk: Vector3i = step[0]
			var ng: int = g + step[1]
			if ng > opts.budget:
				continue
			if opts.cost.has(nk) and opts.cost[nk] <= ng:
				continue
			opts.cost[nk] = ng
			opts.prev[nk] = k
			opts.can_end[nk] = _can_end_in(state, unit, MoveOptions.coord_of(nk))
			heap.push(ng, nk)
	if mode == MoveMode.Kind.RUN and opts.budget >= 1 and not unit.prone:
		_minimum_move(state, unit, opts, start)
	return opts


## Minimum movement (book p. 49): a 'Mech with any MP may always run one hex
## directly forward, even if that hex costs more; it uses all its MP.
static func _minimum_move(state: GameState, unit: Unit, opts: MoveOptions, start: Vector3i) -> void:
	var to := Hex.neighbor(unit.coord, start.z)
	var nk := MoveOptions.key(to, start.z)
	if opts.cost.has(nk):
		return
	var mp := MoveCost.enter_cost(state.map, unit.coord, to, MoveMode.Kind.RUN, max_level_change(unit))
	if mp == MoveCost.PROHIBITED or not _can_pass(state, unit, to):
		return
	opts.cost[nk] = opts.budget
	opts.prev[nk] = start
	opts.can_end[nk] = _can_end_in(state, unit, to)
	opts.minimum_move = nk


## Levels a 'Mech may change per hex moving forward: 2, or 1 with a hip hit or
## a destroyed leg (book pp. 90, 99). Backward: 1, or none with that damage.
static func max_level_change(unit: Unit, backward: bool = false) -> int:
	var hurt := unit.hip_hits() > 0 or unit.legs_destroyed() > 0
	if backward:
		return 0 if hurt else 1
	return 1 if hurt else MoveCost.MAX_LEVEL_CHANGE


## Returns [[next_key, mp_cost], ...].
static func _successors(state: GameState, unit: Unit, k: Vector3i, mode: int) -> Array:
	var c := MoveOptions.coord_of(k)
	var f := k.z
	var out := [
		[MoveOptions.key(c, Hex.rotate(f, -1)), 1],
		[MoveOptions.key(c, Hex.rotate(f, 1)), 1],
	]
	var to := Hex.neighbor(c, f)
	var mp := MoveCost.enter_cost(state.map, c, to, mode, max_level_change(unit))
	if mp != MoveCost.PROHIBITED and _can_pass(state, unit, to):
		out.append([MoveOptions.key(to, f), mp])
	# Backward: walking only, at most one level up or down (book p. 46).
	if mode == MoveMode.Kind.WALK:
		var back := Hex.neighbor(c, f + 3)
		var bmp := MoveCost.enter_cost(state.map, c, back, mode, max_level_change(unit, true))
		if bmp != MoveCost.PROHIBITED and _can_pass(state, unit, back):
			out.append([MoveOptions.key(back, f), bmp])
	return out


## Units may move through friendly units but not enemy units.
static func _can_pass(state: GameState, unit: Unit, c: Vector2i) -> bool:
	var other := state.unit_at(c)
	return other == null or other == unit or other.side == unit.side


## Only one 'Mech may end its movement in a hex.
static func _can_end_in(state: GameState, unit: Unit, c: Vector2i) -> bool:
	var other := state.unit_at(c)
	return other == null or other == unit
