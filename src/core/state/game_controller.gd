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
	if state.turn == 1 and not state.conditions.is_clear():
		_emit(GameEvent.CONDITIONS, {"names": state.conditions.names()})
	MissionFlow.start_turn(state, dice, _emit_cb)
	_set_phase(Phase.Kind.INITIATIVE)
	_roll_initiative()
	_begin_phase(Phase.Kind.MOVEMENT)


## Moves a unit to a planned (hex, facing) key. Returns false if illegal.
## With `charge_target_id`, the move ends in a charge (walk/run) or death from
## above (jump) against the enemy straight ahead; it must be legal.
## `then_prone` drops it to the ground at the end of the move (1 MP);
## `smash` fails building entry rolls on purpose to force Destroy Checks;
## `leave` then moves off the battlefield where the mission allows (MissionFlow).
func submit_move(unit: Unit, target: Vector3i, mode: int, charge_target_id: int = -1,
		then_prone := false, smash := false, leave := false) -> bool:
	if not _may_act(unit, Phase.Kind.MOVEMENT):
		return false
	if MissionFlow.move_problem(state, unit, target, mode, leave) != "":
		return false
	if not MoveExecutor.run(state, dice, _emit_cb, unit, target, mode, charge_target_id, then_prone, smash):
		return false
	AssetTransport.follow(state, unit)
	if leave and not unit.destroyed and not unit.prone and unit.coord == MoveOptions.coord_of(target):
		MissionFlow.leave(state, _emit_cb, unit)
	_unit_done()
	return true


## Infantry boards a friendly transport in its hex (APC Special, p. 148),
## as its move or right after it. Returns false if it can't.
func board(rider: Unit, carrier: Unit) -> bool:
	if state.phase != Phase.Kind.MOVEMENT or state.game_over:
		return false
	var acting := rider.side == state.active_side() and pending_units().has(rider)
	if not acting and not (rider.has_moved and rider.asset != null and rider.asset.carried_by < 0):
		return false
	if AssetTransport.board_problem(state, rider, carrier) != "":
		return false
	AssetTransport.board(state, _emit_cb, rider, carrier)
	if acting:
		_unit_done()
	return true


## Infantry gets off its transport into the transport's hex; it can't
## fire this turn. Returns false if it can't.
func deploy(rider: Unit) -> bool:
	if state.phase != Phase.Kind.MOVEMENT or state.game_over or rider.asset == null:
		return false
	var carrier := state.unit_by_id(rider.asset.carried_by)
	if carrier == null or not (carrier.has_moved or rider.side == state.active_side()):
		return false
	if AssetTransport.deploy_problem(state, rider) != "":
		return false
	AssetTransport.deploy(state, _emit_cb, rider)
	return true


## Engages MASC before moving (book p. 204). Returns whether it worked;
## false also when it can't be engaged (Masc.problem).
func engage_masc(unit: Unit) -> bool:
	if not _may_act(unit, Phase.Kind.MOVEMENT) or Masc.problem(unit) != "":
		return false
	return Masc.engage(dice, _emit_cb, unit)


## Engages the supercharger before moving (book p. 204), like engage_masc.
func engage_supercharger(unit: Unit) -> bool:
	if not _may_act(unit, Phase.Kind.MOVEMENT) or Supercharger.problem(unit) != "":
		return false
	return Supercharger.engage(dice, _emit_cb, unit)


## Drops a standing 'Mech to the ground instead of moving: harder to hit
## from range, easier from next door. Standing up later costs 2 MP and a roll.
## To move first and then drop, use submit_move(..., then_prone = true).
func go_prone(unit: Unit) -> bool:
	if not _may_act(unit, Phase.Kind.MOVEMENT) or unit.prone or unit.masc_used or unit.sc_used \
			or unit.asset != null:
		return false
	MoveExecutor.go_prone(_emit_cb, unit)
	_unit_done()
	return true


## Declares weapon fire: shots = [{weapon: index, target_id}]. An empty list
## holds fire. Impossible shots are dropped. Returns false if out of turn.
func declare_fire(unit: Unit, shots: Array) -> bool:
	if not _may_act(unit, Phase.Kind.WEAPON_ATTACK):
		return false
	var decl := FireOptions.declare(state, unit, shots)
	state.declared_fire.append_array(decl)
	IndirectFire.record(state, decl)
	AssetIndirect.record(state, unit, decl)
	unit.has_fired = true
	_emit(GameEvent.FIRE_DECLARED, {"unit_id": unit.id, "shots": FireOptions.summary(unit, decl)})
	_unit_done()
	return true


## Declares physical attacks: [{kind: "punch"|"kick", limb, target_id}].
## An empty list makes none. Returns false if out of turn.
func declare_physical(unit: Unit, attacks: Array) -> bool:
	if not _may_act(unit, Phase.Kind.PHYSICAL_ATTACK):
		return false
	var hexes := attacks.filter(func(r: Dictionary) -> bool: return r.has("hex"))
	var decl := BuildingMelee.declare(state, unit, hexes[0]["hex"], hexes) if not hexes.is_empty() \
			else PhysicalOptions.declare(state, unit, attacks)
	state.declared_physical.append_array(decl)
	unit.has_physical = true
	_unit_done()
	return true


## Twists the torso one hexside left (-1), right (+1) or back (0) before
## declaring fire. Arms and torso weapons follow; leg weapons don't.
## Picks up a tree or girder as a club instead of firing this turn.
func pick_up_club(unit: Unit) -> bool:
	if not _may_act(unit, Phase.Kind.WEAPON_ATTACK):
		return false
	var club := MeleeWeapons.club_here(state, unit)
	if club == "":
		return false
	unit.club = club
	unit.has_fired = true
	_emit(GameEvent.CLUB, {"unit_id": unit.id, "club": club})
	_unit_done()
	return true


## Ultra AC double fire or LB-X cluster ammo (WeaponModes), before declaring.
func set_weapon_mode(unit: Unit, index: int, mode: String) -> bool:
	if not _may_act(unit, Phase.Kind.WEAPON_ATTACK) or index < 0 or index >= unit.weapons.size():
		return false
	var w := unit.weapons[index]
	if not WeaponModes.modes(w).has(mode):
		return false
	w.mode = mode
	return true


## Asks to shut a 'Mech down ("off") or restart it ("on") at the next Heat Phase; "" cancels.
func request_power(unit: Unit, want: String) -> bool:
	if unit == null or VoluntaryShutdown.problem(unit, want) != "":
		return false
	unit.power_request = want
	return true


## Asks to have `n` heat sinks switched off from the next End Phase (p. 103).
func request_sinks_off(unit: Unit, n: int) -> bool:
	if unit == null or HeatSinkSwitch.problem(unit, n) != "":
		return false
	unit.sinks_off_request = n
	return true


func set_torso_twist(unit: Unit, dir: int) -> bool:
	if not _may_act(unit, Phase.Kind.WEAPON_ATTACK) or unit.prone or unit.def.quad or unit.arms_flipped:
		return false
	unit.torso_twist = clampi(dir, -1, 1)
	return true


## Flips the arms backwards (or back again) before declaring fire (ArmFlip).
func set_arms_flipped(unit: Unit, on: bool) -> bool:
	if not _may_act(unit, Phase.Kind.WEAPON_ATTACK) or (on and ArmFlip.problem(unit) != ""):
		return false
	unit.arms_flipped = on
	return true


## A player's (usually the bot's) stated reason for its next action. Changes
## nothing; the log shows it when explanations are on.
func announce(unit: Unit, text: String) -> void:
	_emit(GameEvent.INTENT, {"unit_id": unit.id, "text": text})


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
	var r := Initiative.roll(dice, state.sides_alive(), InitiativeDie.bonuses(state))
	var forced := MissionFlow.forced_initiative(state)
	if forced >= 0 and r["order"].has(forced):  # the mission hands this side the win
		r["order"].erase(forced)
		r["order"].append(forced)
		r["forced"] = forced
	state.initiative_rolls = r["rolls"]
	state.initiative_order.assign(r["order"])
	if forced < 0:  # a forced win doesn't move the Initiative Die
		InitiativeDie.update(state, r["order"])
	_emit(GameEvent.INITIATIVE, r)


func _begin_phase(p: int) -> void:
	_set_phase(p)
	if p == Phase.Kind.WEAPON_ATTACK:
		LowVisibility.sensor_checks(state, dice, _emit_cb)
	state.order_index = 0
	state.side_order = UnequalNumbers.order(UnequalNumbers.eligible(state, _done_in_phase),
			state.initiative_order)
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
			WeaponFire.resolve_declared(state, dice, _emit_cb)
			Psr.end_of_phase(state, dice, _emit_cb)
			if not _check_game_over():
				_begin_phase(Phase.Kind.PHYSICAL_ATTACK)
		Phase.Kind.PHYSICAL_ATTACK:
			PhysicalPhase.resolve(state, dice, _emit_cb)
			Psr.end_of_phase(state, dice, _emit_cb)
			if not _check_game_over():
				_heat_and_end()


func _heat_and_end() -> void:
	_set_phase(Phase.Kind.HEAT)
	HeatPhase.run(state, dice, _emit_cb)
	_set_phase(Phase.Kind.END)
	EndPhase.run(state, dice, _emit_cb)
	MissionFlow.end_phase(state, _emit_cb)
	if not _check_game_over(true):
		start_turn()


## Game ends when at most one side has a 'Mech left, or as the mission says.
func _check_game_over(end_of_turn := false) -> bool:
	AssetTransport.check_losses(state, _emit_cb)
	Crippled.update(state, dice, _emit_cb)
	var r := MissionFlow.outcome(state, end_of_turn)
	if r.is_empty():
		return false
	state.game_over = true
	state.winner = r["winner"]
	_emit(GameEvent.GAME_OVER, r)
	return true


func _set_phase(p: int) -> void:
	state.phase = p
	_emit(GameEvent.PHASE_CHANGED, {"phase": p})


func _emit(t: StringName, d: Dictionary) -> void:
	var e := GameEvent.new(t, d)
	history.append(e)
	event.emit(e)
