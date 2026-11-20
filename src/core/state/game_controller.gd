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
## With `charge_target_id`, the move ends in a charge (walk/run) or death from
## above (jump) against the enemy straight ahead; it must be legal.
func submit_move(unit: Unit, target: Vector3i, mode: int, charge_target_id: int = -1) -> bool:
	if not _may_act(unit, Phase.Kind.MOVEMENT):
		return false
	var opts := MovePlanner.plan(state, unit, mode)
	if not opts.can_reach(target):
		return false
	var path := opts.path_to(target)
	var from := opts.start_key()
	var mp: int = opts.cost[target]
	if unit.prone and mp > 0 and not Psr.try_stand(state, dice, _emit_cb, unit):
		unit.has_moved = true
		unit.move_mode = MoveMode.Kind.WALK
		unit.heat_generated += MoveMode.heat(MoveMode.Kind.WALK, 0)
		Damage.announce(_emit_cb, unit)
		_unit_done()
		return true
	unit.hexes_moved = Hex.distance(unit.coord, MoveOptions.coord_of(target)) \
			if mode == MoveMode.Kind.JUMP else MoveOptions.hexes_entered(path, unit.coord)
	unit.coord = MoveOptions.coord_of(target)
	unit.facing = target.z
	unit.has_moved = true
	unit.move_mode = mode if mp > 0 else -1
	unit.heat_generated += MoveMode.heat(mode, unit.hexes_moved) if mp > 0 else 0
	_emit(GameEvent.UNIT_MOVED, {"unit_id": unit.id, "from": from, "path": path,
			"mode": unit.move_mode, "mp": mp, "hexes": unit.hexes_moved})
	if charge_target_id >= 0:
		_declare_charge(unit, state.unit_by_id(charge_target_id))
	_unit_done()
	return true


## Records a charge/DFA if legal; the unit then skips weapon and physical attacks.
func _declare_charge(unit: Unit, t: Unit) -> void:
	var kind := "dfa" if unit.move_mode == MoveMode.Kind.JUMP else "charge"
	var opt := Charge.option(state, unit, t, kind)
	if not opt["to_hit"].possible():
		return
	opt["attacker_id"] = unit.id
	opt["target_id"] = t.id
	state.declared_physical.append(opt)
	unit.has_fired = true
	unit.has_physical = true
	_emit(GameEvent.CHARGE_DECLARED, {"unit_id": unit.id, "target_id": t.id, "kind": kind,
			"need": opt["to_hit"].target()})


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


## Declares physical attacks: [{kind: "punch"|"kick", limb, target_id}].
## An empty list makes none. Returns false if out of turn.
func declare_physical(unit: Unit, attacks: Array) -> bool:
	if not _may_act(unit, Phase.Kind.PHYSICAL_ATTACK):
		return false
	var decl := PhysicalOptions.declare(state, unit, attacks)
	state.declared_physical.append_array(decl)
	unit.has_physical = true
	_unit_done()
	return true


## Twists the torso one hexside left (-1), right (+1) or back (0) before
## declaring fire. Arms and torso weapons follow; leg weapons don't.
func set_torso_twist(unit: Unit, dir: int) -> bool:
	if not _may_act(unit, Phase.Kind.WEAPON_ATTACK) or unit.prone:
		return false
	unit.torso_twist = clampi(dir, -1, 1)
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
			return u.has_physical or not PhysicalOptions.any_possible(state, u)
	return true


func _unit_done() -> void:
	if _check_game_over():
		return
	state.order_index += 1
	_advance_to_side_with_work()


func _roll_initiative() -> void:
	var r := Initiative.roll(dice, state.sides_alive())
	state.initiative_rolls = r["rolls"]
	state.side_order = Initiative.alternating_order(state, r["order"])
	_emit(GameEvent.INITIATIVE, r)


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
