class_name MissionFlow
extends RefCounted
## Mission hooks for GameController: turn start (Random Duration, withdrawal
## bookkeeping), moves (withdrawal limits, leaving the battlefield), End
## Phase scoring, and whether the battle is over.


static func start_turn(state: GameState, dice: Dice, emit: Callable) -> void:
	var ms := state.mission
	if ms.def == null:
		return
	Crippled.update(state, dice, emit)
	ForcedWithdrawal.start_turn(state)
	Scanning.start_turn(state)
	if ms.def.random_duration and ms.last_turn == 0 and RandomDuration.roll(state, dice, emit):
		ms.last_turn = state.turn


## After the End Phase: surrenders, scans, then objective Victory Points.
static func end_phase(state: GameState, dice: Dice, emit: Callable) -> void:
	var ms := state.mission
	if ms.def == null:
		return
	ForcedWithdrawal.end_phase(state, emit)
	Scanning.end_phase(state, dice, emit)
	FragileObjectives.end_phase(state, dice, emit)  # broken counters score nothing
	if ms.def.scoring == "":
		return
	for side in state.sides():
		var n := ObjectiveControl.score(state, side)
		if n > 0:
			ms.add_vp(side, n)
			emit.call(GameEvent.MISSION, {"kind": "vp", "side": side, "vp": n, "total": ms.vp[side]})


## The side that wins initiative this turn by mission rule, or -1.
static func forced_initiative(state: GameState) -> int:
	var m := state.mission.def
	if m == null or m.initiative_side < 0 or state.turn > m.initiative_turns:
		return -1
	return m.initiative_side


## Why this move isn't allowed by the mission, or "".
static func move_problem(state: GameState, u: Unit, target: Vector3i, mode: int, leaving: bool) -> String:
	if state.mission.def == null:
		return "No mission lets units leave the battlefield" if leaving else ""
	var opts := MovePlanner.plan(state, u, mode)
	if not opts.can_reach(target):
		return ""  # the controller rejects it anyway
	if leaving:
		if opts.budget - int(opts.cost.get(target, 0)) < 1:
			return "Leaving the battlefield takes 1 more MP"
		if exit_kind(state, u, MoveOptions.coord_of(target)) == "":
			return "It can't leave the battlefield from there"
	return ForcedWithdrawal.problem(state, u, opts, target, leaving)


## How `u` may leave the battlefield from hex `c`: "withdraw", "mission" or "".
static func exit_kind(state: GameState, u: Unit, c: Vector2i) -> String:
	var m := state.mission.def
	if m == null:
		return ""
	if ForcedWithdrawal.withdrawing(state, u) and MapEdges.on_edge(state.map, c, m.home_edge(u.side)):
		return "withdraw"
	if m.scan == "units" and int(state.mission.scans.get(u.id, 0)) == 0:
		return ""  # Sensor Check: only 'Mechs with readings may leave to score
	if m.exit != "" and state.turn >= m.exit_from_turn and (m.exit_side < 0 or m.exit_side == u.side):
		var edge := m.home_edge(u.side) if m.exit == "home" else m.home_edge(1 - u.side)
		if MapEdges.on_edge(state.map, c, edge):
			return "mission"
	return ""


## Takes `u` off the battlefield.
static func leave(state: GameState, emit: Callable, u: Unit) -> void:
	var kind := exit_kind(state, u, u.coord)
	state.mission.exited[u.id] = kind
	u.destroyed = true
	u.destroyed_reason = "left the battlefield"
	u.destroyed_announced = true
	var vp := VictoryPoints.unit_value(u) if kind == "mission" else ceili(VictoryPoints.unit_value(u) / 2.0)
	if kind == "mission" and state.mission.def.scan == "units":  # Sensor Check: 1 VP per scan
		vp = int(state.mission.scans.get(u.id, 0))
		state.mission.add_vp(u.side, vp)
	elif kind == "mission" and not state.mission.def.unit_vp:
		vp = 0  # e.g. Steel Rain: what it carries off scores, not the 'Mech
	emit.call(GameEvent.UNIT_EXITED, {"unit_id": u.id, "kind": kind, "vp": vp})


## {} while the battle goes on, else {winner, why, scores?}.
static func outcome(state: GameState, end_of_turn: bool) -> Dictionary:
	var ms := state.mission
	var alive: Array[int] = []
	for u in state.all_units():
		if ms.remains(u) and not alive.has(u.side):
			alive.append(u.side)
	if ms.def == null or not ms.def.uses_vp():
		if alive.size() > 1:
			return {}
		return {"winner": alive[0] if alive.size() == 1 else -1, "why": "last side standing"}
	var turns := ms.last_turn if ms.def.random_duration else ms.def.turns
	var time_up := end_of_turn and turns > 0 and state.turn >= turns
	var r := VictoryPoints.result(state)
	if time_up or alive.is_empty():
		return r
	if alive.size() == 1 and r["winner"] == alive[0]:
		r["why"] += " (the other side has nothing left on the field)"
		return r
	return {}
