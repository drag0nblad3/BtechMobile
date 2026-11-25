class_name AssetMove
extends RefCounted
## Movement for Assets (book pp. 141-144): the same MP every turn, no
## movement modes, no piloting rolls. RUN is a normal move; WALK means it
## declared backward movement: half MP (round up), may back up, no level
## changes. Jump infantry only jump (JUMP); others can't. Infantry have no facing, so turning
## is free. A vehicle starting on pavement that stays on it gets +1 MP.
## An Asset starting in a burning hex takes 4 damage and must leave it.


static func plan(state: GameState, u: Unit, mode: int) -> MoveOptions:
	var card := u.asset.card
	var jumper := card.motive == "j" and not card.immobile()
	if jumper and mode == MoveMode.Kind.JUMP:
		return _jump(state, u)
	var backward := mode == MoveMode.Kind.WALK
	var stuck := card.immobile() or u.asset.carried_by >= 0 or jumper or mode == MoveMode.Kind.JUMP
	var mp := 0 if stuck else u.walk_mp()
	var budget := ceili(mp / 2.0) if backward else mp
	var indexed := AssetStacking.occupancy(state, u)
	var opts := _search(state, u, mode, budget, backward, false, indexed)
	if budget > 0 and paved_bonus(state, u):
		_merge(opts, _search(state, u, mode, budget + 1, backward, true, indexed))
		opts.budget = budget + 1
	_leave_fire(state, u, opts)
	return opts


## Button and log name for a movement mode: 'Mechs walk/run/jump, combat
## vehicles cruise/flank; Assets
## "Move", "Reverse" (declared backward movement) or "Jump".
static func mode_name(u: Unit, mode: int) -> String:
	if u.vehicle != null and mode >= 0 and mode < MoveMode.VEHICLE_NAMES.size():
		return MoveMode.VEHICLE_NAMES[mode]
	if u.asset == null:
		return MoveMode.name_of(mode)
	match mode:
		MoveMode.Kind.WALK:
			return "Reverse"
		MoveMode.Kind.JUMP:
			return "Jump"
	return "Move"


## +1 MP for staying on pavement all move (p. 142): not VTOLs or foot troops.
static func paved_bonus(state: GameState, u: Unit) -> bool:
	var card := u.asset.card
	if card.motive == "v" or (card.is_infantry() and not card.mechanized):
		return false
	return Roads.is_road(state.map.get_tile(u.coord))


static func _search(state: GameState, u: Unit, mode: int, budget: int, backward: bool,
		road_only: bool, indexed: Variant = null) -> MoveOptions:
	var opts := MoveOptions.new()
	opts.unit = u
	opts.mode = mode
	opts.budget = budget
	var start := opts.start_key()
	opts.cost[start] = 0
	opts.can_end[start] = true
	var heap := MinHeap.new()
	heap.push(0, start)
	var nimble := u.asset.card.nimble()
	while not heap.is_empty():
		var top := heap.pop()
		var k: Vector3i = top[1]
		if int(top[0]) > int(opts.cost[k]):
			continue
		for step in _steps(state, u, k, nimble, backward, road_only, indexed):
			var nk: Vector3i = step[0]
			var ng: int = int(opts.cost[k]) + int(step[1])
			if ng > budget or (opts.cost.has(nk) and int(opts.cost[nk]) <= ng):
				continue
			opts.cost[nk] = ng
			opts.prev[nk] = k
			var c := MoveOptions.coord_of(nk)
			opts.can_end[nk] = c == u.coord or can_stop(state, u, c, indexed)
			if c == u.coord or AssetStacking.can_pass(state, u, c, indexed):
				heap.push(ng, nk)  # an enemy hex can be entered to stop in, not crossed
	return opts


## [[key, mp]]: turns (free for infantry), forward, and backward if declared.
static func _steps(state: GameState, u: Unit, k: Vector3i, nimble: bool, backward: bool,
		road_only: bool, indexed: Variant = null) -> Array:
	var c := MoveOptions.coord_of(k)
	var out := []
	var dirs: Array = range(6) if nimble else [k.z]
	if not nimble:
		out.append([MoveOptions.key(c, Hex.rotate(k.z, -1)), 1])
		out.append([MoveOptions.key(c, Hex.rotate(k.z, 1)), 1])
	for d: int in dirs:
		for back in ([false, true] if backward and not nimble else [false]):
			var to := Hex.neighbor(c, d + (3 if back else 0))
			if road_only and not Roads.is_road(state.map.get_tile(to)):
				continue
			var mp := AssetMoveCost.enter_cost(state, u, c, to, backward)
			if mp == AssetMoveCost.PROHIBITED or not _may_step(state, u, to, indexed):
				continue
			out.append([MoveOptions.key(to, d), mp])
	return out


## Entering a hex at all: friends or a hex it may stop in; no fire for foot troops.
static func _may_step(state: GameState, u: Unit, c: Vector2i, indexed: Variant = null) -> bool:
	var tile := state.map.get_tile(c)
	if tile.on_fire and u.asset.card.kind == AssetCard.INFANTRY:
		return false  # conventional infantry can't cross fire (p. 148)
	return AssetStacking.can_pass(state, u, c, indexed) or AssetStacking.can_end(state, u, c, indexed)


## A legal place to finish: stacking, and never a burning hex (p. 148).
static func can_stop(state: GameState, u: Unit, c: Vector2i, indexed: Variant = null) -> bool:
	var tile := state.map.get_tile(c)
	if tile == null or (tile.on_fire and not u.asset.card.has("FR")):
		return false
	return AssetStacking.can_end(state, u, c, indexed)


static func _jump(state: GameState, u: Unit) -> MoveOptions:
	var opts := JumpPlanner.plan(state, u)
	var indexed := AssetStacking.occupancy(state, u)
	for k: Vector3i in opts.cost:
		var c := MoveOptions.coord_of(k)
		if c != u.coord:
			opts.can_end[k] = AssetMoveCost.may_enter(u.asset.card, state.map.get_tile(c)) \
					and can_stop(state, u, c, indexed)
	_leave_fire(state, u, opts)
	return opts


static func _merge(into: MoveOptions, extra: MoveOptions) -> void:
	for k: Vector3i in extra.cost:
		if into.cost.has(k) and int(into.cost[k]) <= int(extra.cost[k]):
			continue
		var cur := k
		while extra.prev.has(cur):  # take the whole paved route
			into.cost[cur] = extra.cost[cur]
			into.prev[cur] = extra.prev[cur]
			into.can_end[cur] = extra.can_end[cur]
			cur = extra.prev[cur]


## Starting in fire: staying put isn't allowed while it can get out.
static func _leave_fire(state: GameState, u: Unit, opts: MoveOptions) -> void:
	if not state.map.get_tile(u.coord).on_fire or u.asset.card.has("FR"):
		return
	for k: Vector3i in opts.can_end:
		if opts.can_end[k] and MoveOptions.coord_of(k) != u.coord:
			for f in 6:
				opts.can_end[MoveOptions.key(u.coord, f)] = false
			return


## Carries out a planned move (MoveExecutor hands Assets here).
static func run(state: GameState, emit: Callable, u: Unit, target: Vector3i, mode: int) -> bool:
	var opts := plan(state, u, mode)
	if not opts.can_reach(target):
		return false
	var path: Array[Vector3i] = opts.path_to(target)
	var from := opts.start_key()
	var moved := target != from
	var jumped := opts.mode == MoveMode.Kind.JUMP
	if state.map.get_tile(u.coord).on_fire and not u.asset.card.has("FR"):
		AssetDamage.take(emit, u, 4, -1, "fire", ["AI"])  # began its turn burning (p. 148)
	u.hexes_moved = Hex.distance(u.coord, MoveOptions.coord_of(target)) if jumped \
			else MoveOptions.hexes_entered(path, u.coord)
	u.coord = MoveOptions.coord_of(target)
	u.facing = target.z
	u.has_moved = true
	u.move_mode = opts.mode if moved else -1
	if VtolFlight.is_vtol(u):
		VtolFlight.settle(state.map, u)
	if not u.asset.card.has("FR"):
		u.outside_heat += Fire.move_heat(state.map, path, MoveOptions.coord_of(from), jumped)
	emit.call(GameEvent.UNIT_MOVED, {"unit_id": u.id, "from": from, "path": path,
			"mode": u.move_mode, "mp": opts.cost.get(target, 0), "hexes": u.hexes_moved, "asset": true})
	return true
