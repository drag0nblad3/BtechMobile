class_name ForcedWithdrawal
extends RefCounted
## Forced Withdrawal (book p. 230). A crippled 'Mech retreats: it can't stand
## still and must end each move at least one hex closer to its home edge when
## it can (backward moves are fine), and it may leave the battlefield by that
## edge. A 'Mech that can't get closer two turns in a row surrenders (counts
## as destroyed) in the End Phase. It can still shoot but can't hold
## objectives. TODO(rules): "spend at least half its MP getting closer" is
## enforced only through the end hex being closer.


static func withdrawing(state: GameState, u: Unit) -> bool:
	var ms := state.mission
	return ms.def != null and ms.def.forced_withdrawal and ms.crippled.has(u.id) \
			and not u.destroyed and not ms.exited.has(u.id)


static func edge_distance(state: GameState, u: Unit, c: Vector2i) -> int:
	return MapEdges.distance(state.map, c, state.mission.def.home_edge(u.side))


## Why this move breaks the withdrawal rules, or "".
static func problem(state: GameState, u: Unit, opts: MoveOptions, target: Vector3i, leaving: bool) -> String:
	if not withdrawing(state, u) or leaving:
		return ""
	var now := edge_distance(state, u, u.coord)
	var best := now
	for c: Vector2i in opts.reachable_hexes():
		best = mini(best, edge_distance(state, u, c))
	if best >= now:
		return ""  # nothing closer is reachable
	if edge_distance(state, u, MoveOptions.coord_of(target)) >= now:
		return "Withdrawing: it must end at least one hex closer to its home edge (%s)" % \
				state.mission.def.home_edge(u.side)
	return ""


## Start of turn: remember how far each withdrawing 'Mech is from home.
static func start_turn(state: GameState) -> void:
	var ms := state.mission
	ms.withdraw_from.clear()
	for u in state.units:
		if withdrawing(state, u):
			ms.withdraw_from[u.id] = edge_distance(state, u, u.coord)


## End Phase: a 'Mech that failed to get closer two turns running gives up.
static func end_phase(state: GameState, emit: Callable) -> void:
	var ms := state.mission
	for u in state.units:
		if not ms.withdraw_from.has(u.id) or not withdrawing(state, u):
			continue
		if edge_distance(state, u, u.coord) < int(ms.withdraw_from[u.id]):
			ms.withdraw_fails[u.id] = 0
			continue
		ms.withdraw_fails[u.id] = int(ms.withdraw_fails.get(u.id, 0)) + 1
		if ms.withdraw_fails[u.id] >= 2:
			Damage.destroy_unit(u, "surrendered: it couldn't withdraw")
			Damage.announce(emit, u)
