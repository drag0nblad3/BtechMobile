class_name MoveExecutor
extends RefCounted
## Carries out one validated move for GameController: standing up, moving,
## heat, entering buildings and declaring a charge. Turn order stays in the
## controller. `emit` is GameController._emit (type, data).


## Drops a standing 'Mech prone where it is (costs its movement for the turn).
static func go_prone(emit: Callable, unit: Unit) -> void:
	unit.prone = true
	unit.has_moved = true
	unit.move_mode = MoveMode.Kind.WALK
	unit.heat_generated += MoveMode.heat(MoveMode.Kind.WALK, 0)
	emit.call(GameEvent.WENT_PRONE, {"unit_id": unit.id})


## Returns false if the target can't be reached in this mode.
static func run(state: GameState, dice: Dice, emit: Callable, unit: Unit, target: Vector3i,
		mode: int, charge_target_id: int) -> bool:
	var opts := MovePlanner.plan(state, unit, mode)
	if not opts.can_reach(target):
		return false
	var entry := BuildingRules.plan_entry(state.map, unit, opts.path_to(target), mode == MoveMode.Kind.JUMP)
	var path: Array[Vector3i] = entry["path"]
	if entry["collapse"]:
		target = path[path.size() - 1]
		charge_target_id = -1
	var from := opts.start_key()
	var skid := Skid.find(state.map, path, from, mode)
	if not skid.is_empty() and not unit.prone:
		if Psr.roll(dice, emit, unit, "turning on pavement at a run", skid["mod"]):
			skid = {}
		else:
			path = path.slice(0, skid["index"])
			target = path[path.size() - 1] if not path.is_empty() else from
			charge_target_id = -1
	var mp: int = opts.cost[target]
	if unit.prone and mp > 0 and not Psr.try_stand(state, dice, emit, unit):
		unit.has_moved = true
		unit.move_mode = MoveMode.Kind.WALK
		unit.heat_generated += MoveMode.heat(MoveMode.Kind.WALK, 0)
		Damage.announce(emit, unit)
		return true
	unit.hexes_moved = Hex.distance(unit.coord, MoveOptions.coord_of(target)) \
			if mode == MoveMode.Kind.JUMP else MoveOptions.hexes_entered(path, unit.coord)
	unit.coord = MoveOptions.coord_of(target)
	unit.facing = target.z
	unit.has_moved = true
	unit.move_mode = mode if mp > 0 else -1
	unit.heat_generated += MoveMode.heat(mode, unit.hexes_moved) if mp > 0 else 0
	emit.call(GameEvent.UNIT_MOVED, {"unit_id": unit.id, "from": from, "path": path,
			"mode": unit.move_mode, "mp": mp, "hexes": unit.hexes_moved})
	if mp > 0:
		MovePsr.after_move(state, unit, path, mode)
	for c: Vector2i in entry["entered"]:
		if _passes(path, c):
			BuildingRules.enter(state, dice, emit, unit, c)
	if not skid.is_empty():
		Skid.slide(state, dice, emit, unit, skid["dir"], skid["hexes"])
	if charge_target_id >= 0:
		Charge.declare(state, emit, unit, state.unit_by_id(charge_target_id))
	return true


static func _passes(path: Array[Vector3i], c: Vector2i) -> bool:
	for k in path:
		if MoveOptions.coord_of(k) == c:
			return true
	return false
