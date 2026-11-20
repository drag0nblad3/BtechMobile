class_name GameController
extends RefCounted
## The only thing that mutates GameState. UI and AI submit actions here;
## every change is announced through `event` so views stay in sync.
## Turn: Initiative -> Movement -> Weapon Attack -> Physical Attack -> Heat -> End.
## In the three action phases sides alternate unit by unit, loser first;
## attacks are declared in that order and resolved together at phase end.

signal event(e: GameEvent)

var state: GameState
var dice: Dice
var history: Array[GameEvent] = []
var _emit_cb := Callable(self, "_emit")


func _init(game_state: GameState, seed_value: int = 0) -> void:
	state = game_state
	dice = Dice.new(seed_value)


func start_turn() -> void:
	if state.game_over:
		return
	state.turn += 1
	for u in state.units:
		u.reset_for_turn()
	_emit(GameEvent.TURN_STARTED, {"turn": state.turn})
	_set_phase(Phase.Kind.INITIATIVE)
	_roll_initiative()
	_begin_phase(Phase.Kind.MOVEMENT)


## Moves a unit to a planned (hex, facing) key. Returns false if illegal.
func submit_move(unit: Unit, target: Vector3i, mode: int) -> bool:
	if not _may_act(unit, Phase.Kind.MOVEMENT):
		return false
	var opts := MovePlanner.plan(state, unit, mode)
	if not opts.can_reach(target):
		return false
	var path := opts.path_to(target)
	var from := opts.start_key()
	var mp: int = opts.cost[target]
	unit.hexes_moved = MoveOptions.hexes_entered(path, unit.coord)
	unit.coord = MoveOptions.coord_of(target)
	unit.facing = target.z
	unit.has_moved = true
	unit.move_mode = mode if mp > 0 else -1
	unit.heat_generated += HeatScale.MOVE_HEAT[mode + 1] if mp > 0 else 0
	_emit(GameEvent.UNIT_MOVED, {"unit_id": unit.id, "from": from, "path": path,
			"mode": unit.move_mode, "mp": mp, "hexes": unit.hexes_moved})
	_unit_done()
	return true


## Declares weapon fire: shots = [{weapon: index, target_id}]. An empty list
## holds fire. Impossible shots are dropped. Returns false if out of turn.
func declare_fire(unit: Unit, shots: Array) -> bool:
	if not _may_act(unit, Phase.Kind.WEAPON_ATTACK):
		return false
	var decl := FireOptions.declare(state, unit, shots)
	state.declared_fire.append_array(decl)
	unit.has_fired = true
	var summary := []
	for d in decl:
		summary.append({"weapon": unit.weapons[d["weapon_index"]].def.name,
				"target_id": d["target_id"], "need": d["to_hit"].target()})
	_emit(GameEvent.FIRE_DECLARED, {"unit_id": unit.id, "shots": summary})
	_unit_done()
	return true


## Units of the active side that may still act this phase.
func pending_units() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in state.units_of_side(state.active_side()):
		if u.can_act() and not _done_in_phase(u):
			out.append(u)
	return out


func _may_act(unit: Unit, phase: int) -> bool:
	return not state.game_over and state.phase == phase \
			and unit.side == state.active_side() and pending_units().has(unit)


func _done_in_phase(u: Unit) -> bool:
	match state.phase:
		Phase.Kind.MOVEMENT:
			return u.has_moved
		Phase.Kind.WEAPON_ATTACK:
			return u.has_fired
		Phase.Kind.PHYSICAL_ATTACK:
			return true  # Physical attacks arrive with the physical module.
	return true


func _unit_done() -> void:
	state.order_index += 1
	_advance_to_side_with_work()


## Initiative: each side rolls 2d6, rerolling ties. Loser moves first.
func _roll_initiative() -> void:
	var sides := state.sides_alive()
	var rolls := {}
	var unique := false
	while not unique:
		var seen := {}
		unique = true
		for s in sides:
			rolls[s] = dice.roll_2d6()
			if seen.has(rolls[s]):
				unique = false
			seen[rolls[s]] = true
	sides.sort_custom(func(a, b): return rolls[a] < rolls[b])
	state.initiative_rolls = rolls
	state.side_order = _alternating_order(sides)
	_emit(GameEvent.INITIATIVE, {"rolls": rolls, "order": sides})


## Unit-by-unit alternation, loser first; sides with nothing left are skipped.
## TODO(rules): proper unequal-numbers batching.
func _alternating_order(sides: Array[int]) -> Array[int]:
	var out: Array[int] = []
	var most := 0
	for s in sides:
		most = maxi(most, state.units_of_side(s).size())
	for i in most:
		out.append_array(sides)
	return out


func _begin_phase(p: int) -> void:
	_set_phase(p)
	state.order_index = 0
	_advance_to_side_with_work()


func _advance_to_side_with_work() -> void:
	while state.order_index < state.side_order.size():
		if not pending_units().is_empty():
			_emit(GameEvent.ACTIVE_SIDE, {"side": state.active_side()})
			return
		state.order_index += 1
	_end_phase()


func _end_phase() -> void:
	match state.phase:
		Phase.Kind.MOVEMENT:
			Psr.end_of_phase(state, dice, _emit_cb)
			if not _check_game_over():
				_begin_phase(Phase.Kind.WEAPON_ATTACK)
		Phase.Kind.WEAPON_ATTACK:
			_resolve_fire()
			Psr.end_of_phase(state, dice, _emit_cb)
			if not _check_game_over():
				_begin_phase(Phase.Kind.PHYSICAL_ATTACK)
		Phase.Kind.PHYSICAL_ATTACK:
			PhysicalPhase.resolve(state, dice, _emit_cb)
			Psr.end_of_phase(state, dice, _emit_cb)
			if not _check_game_over():
				_heat_and_end()


func _resolve_fire() -> void:
	for d in state.declared_fire:
		var a := state.unit_by_id(d["attacker_id"])
		WeaponFire.resolve(state, dice, _emit_cb, a, a.weapons[d["weapon_index"]],
				state.unit_by_id(d["target_id"]), d["to_hit"])
	state.declared_fire.clear()


func _heat_and_end() -> void:
	_set_phase(Phase.Kind.HEAT)
	HeatPhase.run(state, dice, _emit_cb)
	_set_phase(Phase.Kind.END)
	EndPhase.run(state, dice, _emit_cb)
	if not _check_game_over():
		start_turn()


## Game ends when at most one side has a 'Mech left.
func _check_game_over() -> bool:
	var alive := state.sides_alive()
	if alive.size() > 1:
		return false
	state.game_over = true
	state.winner = alive[0] if alive.size() == 1 else -1
	_emit(GameEvent.GAME_OVER, {"winner": state.winner})
	return true


func _set_phase(p: int) -> void:
	state.phase = p
	_emit(GameEvent.PHASE_CHANGED, {"phase": p})


func _emit(t: StringName, d: Dictionary) -> void:
	var e := GameEvent.new(t, d)
	history.append(e)
	event.emit(e)
