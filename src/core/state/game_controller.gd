class_name GameController
extends RefCounted
## The only thing that mutates GameState. UI and AI submit actions here;
## every change is announced through `event` so views stay in sync.

signal event(e: GameEvent)

var state: GameState
var dice: Dice
var history: Array[GameEvent] = []


func _init(game_state: GameState, seed_value: int = 0) -> void:
	state = game_state
	dice = Dice.new(seed_value)


func start_turn() -> void:
	state.turn += 1
	for u in state.units:
		u.reset_for_turn()
	_emit(GameEvent.TURN_STARTED, {"turn": state.turn})
	_set_phase(Phase.Kind.INITIATIVE)
	_roll_initiative()
	_set_phase(Phase.Kind.MOVEMENT)
	_advance_to_side_with_work()


## Moves a unit to a planned (hex, facing) key. Returns false if illegal.
func submit_move(unit: Unit, target: Vector3i, mode: int) -> bool:
	if state.phase != Phase.Kind.MOVEMENT or unit.has_moved:
		return false
	if unit.side != state.active_side():
		return false
	var opts := MovePlanner.plan(state, unit, mode)
	if not opts.can_reach(target):
		return false
	var path := opts.path_to(target)
	var from := opts.start_key()
	unit.hexes_moved = MoveOptions.hexes_entered(path, unit.coord)
	unit.coord = MoveOptions.coord_of(target)
	unit.facing = target.z
	unit.has_moved = true
	unit.move_mode = mode
	_emit(GameEvent.UNIT_MOVED, {
		"unit_id": unit.id, "from": from, "path": path, "mode": mode, "mp": opts.cost[target],
	})
	state.order_index += 1
	_advance_to_side_with_work()
	return true


## Units of the active side that may still act this phase.
func pending_units() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in state.units_of_side(state.active_side()):
		if not u.has_moved:
			out.append(u)
	return out


## Initiative: each side rolls 2d6, rerolling ties. Loser moves first.
func _roll_initiative() -> void:
	var sides := state.sides()
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
	state.order_index = 0
	_emit(GameEvent.INITIATIVE, {"rolls": rolls, "order": sides})


## Unit-by-unit alternation, loser first. Unequal unit counts are
## handled by skipping sides with nothing left (see TW "Unequal Numbers").
## TODO(rules): proper unequal-numbers batching.
func _alternating_order(sides: Array[int]) -> Array[int]:
	var out: Array[int] = []
	var most := 0
	for s in sides:
		most = maxi(most, state.units_of_side(s).size())
	for i in most:
		out.append_array(sides)
	return out


func _advance_to_side_with_work() -> void:
	while state.order_index < state.side_order.size():
		if not pending_units().is_empty():
			_emit(GameEvent.ACTIVE_SIDE, {"side": state.active_side()})
			return
		state.order_index += 1
	_end_movement_phase()


## Later phases are stubs until their rule modules exist.
func _end_movement_phase() -> void:
	for p in [Phase.Kind.WEAPON_ATTACK, Phase.Kind.PHYSICAL_ATTACK,
			Phase.Kind.HEAT, Phase.Kind.END]:
		_set_phase(p)
	start_turn()


func _set_phase(p: int) -> void:
	state.phase = p
	_emit(GameEvent.PHASE_CHANGED, {"phase": p})


func _emit(t: StringName, d: Dictionary) -> void:
	var e := GameEvent.new(t, d)
	history.append(e)
	event.emit(e)
