class_name MovePlanner
extends RefCounted
## Finds every reachable (hex, facing) for a unit with Dijkstra search.
## Steps: turn one hexside left/right (1 MP), move forward into the faced
## hex, or (walking only) back into the hex behind (MoveCost). Quads can
## also shift sideways (LateralShift).
## Jumping is a separate search (JumpPlanner).


static func plan(state: GameState, unit: Unit, mode: int) -> MoveOptions:
	if unit.asset != null:
		return AssetMove.plan(state, unit, mode)
	if mode == MoveMode.Kind.JUMP:
		return JumpPlanner.plan(state, unit)
	if unit.prone and not Psr.can_stand(unit):
		return ProneMoves.turn_options(unit, mode)
	var opts := MoveOptions.new()
	opts.unit = unit
	opts.mode = mode
	opts.budget = MoveMode.budget(unit, mode)
	var start := opts.start_key()
	opts.cost[start] = 0
	opts.can_end[start] = true
	var indexed := AssetStacking.occupancy(state, unit)
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
		for step in _successors(state, unit, k, mode, indexed):
			var nk: Vector3i = step[0]
			var ng: int = g + step[1]
			if ng > opts.budget:
				continue
			if opts.cost.has(nk) and opts.cost[nk] <= ng:
				continue
			opts.cost[nk] = ng
			opts.prev[nk] = k
			opts.can_end[nk] = _can_end_in(state, unit, MoveOptions.coord_of(nk), indexed)
			heap.push(ng, nk)
	if mode == MoveMode.Kind.RUN and not unit.prone and not unit.on_roof and unit.vehicle == null:
		_careful_entry(state, unit, opts, start)
	if mode == MoveMode.Kind.RUN and opts.budget >= 1 and not unit.prone and not unit.on_roof:
		_minimum_move(state, unit, opts, start)
	return opts


## Minimum movement (book p. 49): a 'Mech with any MP may always run one hex
## directly forward, even if that hex costs more; it uses all its MP.
static func _minimum_move(state: GameState, unit: Unit, opts: MoveOptions, start: Vector3i) -> void:
	var to := Hex.neighbor(unit.coord, start.z)
	var nk := MoveOptions.key(to, start.z)
	if opts.cost.has(nk):
		return
	var mp := enter_cost(state, unit, unit.coord, to, MoveMode.Kind.RUN, max_level_change(unit))
	if mp == MoveCost.PROHIBITED or not can_pass(state, unit, to):
		return
	opts.cost[nk] = opts.budget
	opts.prev[nk] = start
	opts.can_end[nk] = _can_end_in(state, unit, to)
	opts.minimum_move = nk


## Careful entry (book p. 133): running, a 'Mech may spend its whole move
## entering the building hex straight ahead, even one of a class too heavy
## for it to force its way into, if it has the MP to pay for the hex.
static func _careful_entry(state: GameState, unit: Unit, opts: MoveOptions, start: Vector3i) -> void:
	var to := Hex.neighbor(unit.coord, start.z)
	var tile := state.map.get_tile(to)
	if tile == null or tile.building == null or tile.building.type.civilian:
		return
	var nk := MoveOptions.key(to, start.z)
	if not opts.cost.has(nk):
		var mp := MoveCost.enter_cost(state.map, unit.coord, to, MoveMode.Kind.RUN, max_level_change(unit))
		var other := state.unit_at(to)
		if mp == MoveCost.PROHIBITED or mp > opts.budget or (other != null and other != unit):
			return
		opts.cost[nk] = mp
		opts.prev[nk] = start
		opts.can_end[nk] = true
	if opts.prev.get(nk) == start:
		opts.careful_entry = nk


## MP to enter a hex: combat vehicles use their own costs (VehicleMoveCost);
## a Terrain Master 'Mech pays less (TerrainMaster).
static func enter_cost(state: GameState, unit: Unit, from: Vector2i, to: Vector2i, mode: int, max_change: int) -> int:
	if unit.vehicle != null:
		return VehicleMoveCost.enter_cost(state.map, unit, from, to)
	if unit.ba != null:
		return BaMoveCost.enter_cost(state.map, from, to, mode)
	var mp := MoveCost.enter_cost(state.map, from, to, mode, max_change)
	if mp == MoveCost.PROHIBITED:
		return mp
	return maxi(1, mp - TerrainMaster.discount(state.map, unit, from, to))


## Levels a 'Mech may change per hex moving forward: 2, or 1 with a hip hit or
## a destroyed leg (book pp. 90, 99). Backward: 1, or none with that damage.
static func max_level_change(unit: Unit, backward: bool = false) -> int:
	var hurt := unit.hip_hits() > 0 or unit.legs_destroyed() > 0
	if backward:
		return 0 if hurt else 1
	return 1 if hurt else MoveCost.MAX_LEVEL_CHANGE


## Returns [[next_key, mp_cost], ...].
static func _successors(state: GameState, unit: Unit, k: Vector3i, mode: int, indexed: Variant = null) -> Array:
	if unit.on_roof:
		return Roofs.successors(state, unit, k, mode)
	var c := MoveOptions.coord_of(k)
	var f := k.z
	var out := [
		[MoveOptions.key(c, Hex.rotate(f, -1)), 1],
		[MoveOptions.key(c, Hex.rotate(f, 1)), 1],
	]
	var to := Hex.neighbor(c, f)
	var mp := enter_cost(state, unit, c, to, mode, max_level_change(unit))
	if mp != MoveCost.PROHIBITED and can_pass(state, unit, to, indexed):
		out.append([MoveOptions.key(to, f), mp])
	# Backward: walking only, at most one level up or down (book p. 46).
	if mode == MoveMode.Kind.WALK:
		var back := Hex.neighbor(c, f + 3)
		var bmp := enter_cost(state, unit, c, back, mode, max_level_change(unit, true))
		if bmp != MoveCost.PROHIBITED and can_pass(state, unit, back, indexed):
			out.append([MoveOptions.key(back, f), bmp])
	out.append_array(LateralShift.steps(state, unit, c, f, mode, indexed))
	return out


## Units may move through friendly units but not enemy units (AssetStacking).
static func can_pass(state: GameState, unit: Unit, c: Vector2i, indexed: Variant = null) -> bool:
	var tile := state.map.get_tile(c)
	if tile != null and tile.building != null and not tile.building.admits(unit.def.tonnage):
		return false  # too light to force its way into this class (p. 132)
	return AssetStacking.can_pass(state, unit, c, indexed)


## Only one 'Mech may end its movement in a hex (infantry Assets can join it).
static func _can_end_in(state: GameState, unit: Unit, c: Vector2i, indexed: Variant = null) -> bool:
	return AssetStacking.can_end(state, unit, c, indexed)
