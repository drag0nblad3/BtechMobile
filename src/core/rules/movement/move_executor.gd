class_name MoveExecutor
extends RefCounted
## Carries out one validated move for GameController: standing up, moving,
## the piloting rolls the move costs, heat, entering buildings and declaring a
## charge. Turn order stays in the controller. `emit` is GameController._emit.


## Drops a standing 'Mech prone where it is (1 MP, counts as walking).
## TODO(rules): the book also allows dropping prone after moving.
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
	if target == opts.minimum_move:
		charge_target_id = -1  # minimum movement can't charge (p. 49)
	var entry := BuildingRules.plan_entry(state.map, unit, opts.path_to(target), mode == MoveMode.Kind.JUMP)
	var path: Array[Vector3i] = entry["path"]
	if entry["collapse"]:
		target = path[path.size() - 1]
		charge_target_id = -1
	var from := opts.start_key()
	var moved: bool = int(opts.cost[target]) > 0 or target != from
	if unit.prone and moved and not Psr.try_stand(state, dice, emit, unit):
		unit.has_moved = true
		unit.move_mode = MoveMode.Kind.WALK
		unit.heat_generated += MoveMode.heat(MoveMode.Kind.WALK, 0)
		Damage.announce(emit, unit)
		return true
	var fall := _action_rolls(state, dice, emit, unit, path, from, mode)
	if not fall.is_empty():
		path = path.slice(0, int(fall["end"]))
		target = path[-1] if not path.is_empty() else from
		charge_target_id = -1
	var mp: int = opts.cost.get(target, 0)
	unit.hexes_moved = Hex.distance(unit.coord, MoveOptions.coord_of(target)) \
			if mode == MoveMode.Kind.JUMP else MoveOptions.hexes_entered(path, unit.coord)
	unit.coord = MoveOptions.coord_of(target)
	unit.facing = target.z
	unit.has_moved = true
	unit.move_mode = mode if moved else -1
	unit.heat_generated += MoveMode.heat(mode, unit.hexes_moved) if moved else 0
	emit.call(GameEvent.UNIT_MOVED, {"unit_id": unit.id, "from": from, "path": path,
			"mode": unit.move_mode, "mp": mp, "hexes": unit.hexes_moved})
	if not fall.is_empty():
		Fall.fall(state, dice, emit, unit, int(fall["levels"]), fall["reason"])
	for c: Vector2i in entry["entered"]:
		if _passes(path, c):
			BuildingRules.enter(state, dice, emit, unit, c)
	if moved:
		MovePsr.after_move(unit, mode, unit.hexes_moved)
	Psr.resolve_pending(state, dice, emit, unit)
	unit.psr_pending.clear()
	if charge_target_id >= 0 and not unit.prone:
		Charge.declare(state, emit, unit, state.unit_by_id(charge_target_id))
	return true


## Rolls each action PSR as the hex is entered. On a failure returns
## {end: path length kept, levels, reason}; else {}.
static func _action_rolls(state: GameState, dice: Dice, emit: Callable, unit: Unit,
		path: Array[Vector3i], from: Vector3i, mode: int) -> Dictionary:
	for r in MovePsr.action_rolls(state, unit, path, from, mode):
		if Psr.roll(dice, emit, unit, r["reason"], int(r["mod"])):
			continue
		var keep: int = r["index"] + (0 if r["back"] else 1)
		return {"end": keep, "levels": r["levels"], "reason": r["reason"]}
	return {}


static func _passes(path: Array[Vector3i], c: Vector2i) -> bool:
	for k in path:
		if MoveOptions.coord_of(k) == c:
			return true
	return false
