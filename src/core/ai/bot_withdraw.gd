class_name BotWithdraw
extends RefCounted
## Bot moves for a crippled 'Mech under Forced Withdrawal: leave the map if
## it can this turn, otherwise get as close to its home edge as possible.


## A BotMove-style plan: {key, mode, reason, charge, leave}.
static func plan(state: GameState, u: Unit) -> Dictionary:
	var best := {}
	var best_d := 1 << 20
	for mode in [MoveMode.Kind.RUN, MoveMode.Kind.WALK, MoveMode.Kind.JUMP]:
		var opts := MovePlanner.plan(state, u, mode)
		for c: Vector2i in opts.reachable_hexes():
			for k in opts.end_keys_in(c):
				var leave := opts.budget - int(opts.cost.get(k, 0)) >= 1 \
						and MissionFlow.exit_kind(state, u, c) == "withdraw"
				var d := -1 if leave else ForcedWithdrawal.edge_distance(state, u, c)
				if d < best_d:
					best_d = d
					best = {"key": k, "mode": mode, "charge": -1, "leave": leave,
							"reason": "is crippled and %s" % ("leaves the battlefield to save itself" if leave
									else "falls back toward its home edge")}
	if best.is_empty():
		return {"key": MoveOptions.key(u.coord, u.facing), "mode": MoveMode.Kind.WALK, "charge": -1,
				"leave": false, "reason": "is crippled but can't move"}
	return best
