class_name MovePlanner
extends RefCounted
## Finds every reachable (hex, facing) for a unit with Dijkstra search.
## Steps: turn one hexside left/right (1 MP) or move forward into the
## faced hex (MoveCost). Backward walking is not implemented yet.


static func plan(state: GameState, unit: Unit, mode: int) -> MoveOptions:
	var opts := MoveOptions.new()
	opts.unit = unit
	opts.mode = mode
	opts.budget = MoveMode.budget(unit, mode)
	var start := opts.start_key()
	opts.cost[start] = 0
	opts.can_end[start] = true
	var heap := MinHeap.new()
	heap.push(0, start)
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
	return opts


## Returns [[next_key, mp_cost], ...].
static func _successors(state: GameState, unit: Unit, k: Vector3i, mode: int) -> Array:
	var c := MoveOptions.coord_of(k)
	var f := k.z
	var out := [
		[MoveOptions.key(c, Hex.rotate(f, -1)), 1],
		[MoveOptions.key(c, Hex.rotate(f, 1)), 1],
	]
	var to := Hex.neighbor(c, f)
	var mp := MoveCost.enter_cost(state.map, c, to, mode)
	if mp != MoveCost.PROHIBITED and _can_pass(state, unit, to):
		out.append([MoveOptions.key(to, f), mp])
	return out


## Units may move through friendly units but not enemy units.
static func _can_pass(state: GameState, unit: Unit, c: Vector2i) -> bool:
	var other := state.unit_at(c)
	return other == null or other == unit or other.side == unit.side


## Only one 'Mech may end its movement in a hex.
static func _can_end_in(state: GameState, unit: Unit, c: Vector2i) -> bool:
	var other := state.unit_at(c)
	return other == null or other == unit
