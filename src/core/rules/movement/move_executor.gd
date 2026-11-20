class_name MoveExecutor
extends RefCounted
## Carries out one validated move for GameController: standing up, moving,
## heat, entering buildings and declaring a charge. Turn order stays in the
## controller. `emit` is GameController._emit (type, data).


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
	for c: Vector2i in entry["entered"]:
		BuildingRules.enter(state, dice, emit, unit, c)
	if charge_target_id >= 0:
		Charge.declare(state, emit, unit, state.unit_by_id(charge_target_id))
	return true
