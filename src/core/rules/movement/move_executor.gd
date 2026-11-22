class_name MoveExecutor
extends RefCounted
## Carries out one validated move for GameController: standing up, moving,
## the piloting rolls the move costs, heat, entering buildings and declaring a
## charge. Turn order stays in the controller. `emit` is GameController._emit.


## Drops a standing 'Mech prone where it is (1 MP, counts as walking).
static func go_prone(emit: Callable, unit: Unit) -> void:
	unit.prone = true
	unit.has_moved = true
	unit.move_mode = MoveMode.Kind.WALK
	unit.heat_generated += MoveMode.heat(MoveMode.Kind.WALK, 0)
	emit.call(GameEvent.WENT_PRONE, {"unit_id": unit.id})


## Returns false if the target can't be reached in this mode. `then_prone`
## drops the 'Mech to the ground at the end (1 MP, no charge).
static func run(state: GameState, dice: Dice, emit: Callable, unit: Unit, target: Vector3i,
		mode: int, charge_target_id: int, then_prone := false, smash := false) -> bool:
	if unit.asset != null:
		return AssetMove.run(state, emit, unit, target, mode)
	var opts := MovePlanner.plan(state, unit, mode)
	if not opts.can_reach(target):
		return false
	if then_prone and (charge_target_id >= 0 or not ProneMoves.can_drop_after(opts, target)):
		return false
	if target == opts.minimum_move:
		charge_target_id = -1  # minimum movement can't charge (p. 49)
	var path: Array[Vector3i] = opts.path_to(target)
	var from := opts.start_key()
	var moved: bool = int(opts.cost[target]) > 0 or target != from
	if unit.prone and moved and not opts.turn_only \
			and not _stand(state, dice, emit, unit, opts.budget - int(opts.cost[target])):
		unit.has_moved = true
		unit.move_mode = MoveMode.Kind.WALK
		unit.heat_generated += MoveMode.heat(MoveMode.Kind.WALK, 0)
		Masc.apply_failure(state, dice, emit, unit)
		Supercharger.apply_failure(state, dice, emit, unit)
		Psr.resolve_pending(state, dice, emit, unit)
		unit.psr_pending.clear()
		Damage.announce(emit, unit)
		PilotDamage.resolve_owed(state, dice, emit)  # Movement Phase: roll at once
		return true
	var found: Array[Unit] = []
	var bump := HiddenUnits.blocked_path(state, unit, path, mode)
	if not bump.is_empty():  # stops next to a hidden enemy (p. 230)
		path = path.slice(0, int(bump["keep"]))
		target = path[-1] if not path.is_empty() else from
		charge_target_id = -1
		then_prone = false
		moved = int(opts.cost.get(target, 0)) > 0 or target != from
		HiddenUnits.reveal(state, emit, bump["hidden"], "an enemy tried to walk into its hex", true)
		found.append(bump["hidden"])
	var fall := _action_rolls(state, dice, emit, unit, path, from, mode)
	if not fall.is_empty():
		path = path.slice(0, int(fall["end"]))
		target = path[-1] if not path.is_empty() else from
		charge_target_id = -1
	var mp: int = opts.cost.get(target, 0)
	unit.hexes_moved = Hex.distance(unit.coord, MoveOptions.coord_of(target)) \
			if mode == MoveMode.Kind.JUMP else MoveOptions.hexes_entered(path, unit.coord)
	var decks := Bridges.decks_entered(state.map, MoveOptions.coord_of(from), path, mode == MoveMode.Kind.JUMP)
	if MoveOptions.coord_of(target) != unit.coord:
		unit.on_bridge = Bridges.ends_on_deck(state.map, MoveOptions.coord_of(from), path, mode == MoveMode.Kind.JUMP)
	unit.coord = MoveOptions.coord_of(target)
	unit.facing = target.z
	var on_new_roof := mode == MoveMode.Kind.JUMP and moved and Roofs.has_roof(state.map.get_tile(unit.coord))
	if mode == MoveMode.Kind.JUMP and moved:
		unit.on_roof = false
	unit.has_moved = true
	unit.move_mode = mode if moved else -1
	unit.heat_generated += MoveMode.heat(mode, unit.hexes_moved, JumpJets.improved(unit.def)) if moved else 0
	unit.outside_heat += Fire.move_heat(state.map, path, MoveOptions.coord_of(from), mode == MoveMode.Kind.JUMP)
	emit.call(GameEvent.UNIT_MOVED, {"unit_id": unit.id, "from": from, "path": path,
			"mode": unit.move_mode, "mp": mp, "hexes": unit.hexes_moved})
	var under := HiddenUnits.enemy_at(state, unit.side, unit.coord) if mode == MoveMode.Kind.JUMP else null
	if under:  # landed on a hidden enemy: it's found and the jumper is shoved aside
		HiddenUnits.reveal(state, emit, under, "an enemy jumped onto its hex", true)
		found.append(under)
		on_new_roof = false
		# TODO(rules): the book resolves point-blank shots before this domino effect.
		Displacement.push_nearest(state, dice, emit, unit, Hex.rotate(unit.facing, 3))
	if not fall.is_empty():
		Fall.fall(state, dice, emit, unit, int(fall["levels"]), fall["reason"])
	if on_new_roof:
		Roofs.landed(state, dice, emit, unit)
	elif not unit.on_roof:
		for c: Vector2i in BuildingRules.entered(state.map, MoveOptions.coord_of(from), path, mode == MoveMode.Kind.JUMP):
			BuildingRules.enter(state, dice, emit, unit, c, target == opts.careful_entry, smash)
	for c in decks:
		Bridges.check_support(state, dice, emit, unit, c)
	Minefields.after_move(state, dice, emit, unit, path, MoveOptions.coord_of(from), mode == MoveMode.Kind.JUMP)
	Masc.apply_failure(state, dice, emit, unit)
	Supercharger.apply_failure(state, dice, emit, unit)
	if moved:
		MovePsr.after_move(unit, mode, unit.hexes_moved, state.conditions, charge_target_id >= 0)
	HullBreach.check_exposed(state, emit, unit)
	Psr.resolve_pending(state, dice, emit, unit)
	unit.psr_pending.clear()
	PilotDamage.resolve_owed(state, dice, emit)  # Movement Phase: roll at once
	if then_prone and not unit.prone and not unit.destroyed:
		ProneMoves.drop(emit, unit)
	found.append_array(HiddenUnits.reveal_around(state, emit, unit))
	for h in found:  # each may answer with a point-blank attack (PointBlank)
		if h.can_act() and not unit.destroyed:
			state.point_blank.append({"unit_id": h.id, "target_id": unit.id})
	if charge_target_id >= 0 and not unit.prone:
		if not moved:  # charging from the hex next door still spends MP
			unit.move_mode = mode
		Charge.declare(state, emit, unit, state.unit_by_id(charge_target_id), opts.budget - mp)
	return true


## Rolls each action PSR as the hex is entered. On a failure returns
## {end: path length kept, levels, reason}; else {}.
static func _action_rolls(state: GameState, dice: Dice, emit: Callable, unit: Unit,
		path: Array[Vector3i], from: Vector3i, mode: int) -> Dictionary:
	for r in MovePsr.action_rolls(state, unit, path, from, mode):
		if Psr.roll(dice, emit, unit, r["reason"], int(r["mod"]), state):
			continue
		var keep: int = r["index"] + (0 if r["back"] else 1)
		return {"end": keep, "levels": r["levels"], "reason": r["reason"]}
	return {}


## Tries to stand, again after each failure while the move leaves 2 spare MP
## for another try (p. 51). Each failure is a fall in place.
static func _stand(state: GameState, dice: Dice, emit: Callable, unit: Unit, spare: int) -> bool:
	while not Psr.try_stand(state, dice, emit, unit):
		spare -= 2
		if spare < 0 or unit.destroyed or not unit.pilot.conscious or not Psr.can_stand(unit):
			return false
	return true
