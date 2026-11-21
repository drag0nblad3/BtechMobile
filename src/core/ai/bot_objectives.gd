class_name BotObjectives
extends RefCounted
## Mission sense for the bot's movement: standing on objectives it can score
## (and not letting the enemy hold them), and leaving by a mission exit when
## that scores.

const HOLD_WEIGHT := 4.0  ## Value per VP of an objective it would stand on.
const PULL := 0.4  ## Per hex nearer the closest objective worth taking.


## Extra score for ending at `c`, and a phrase for the reason ("" if none).
static func bonus(state: GameState, u: Unit, c: Vector2i) -> Array:
	var m := state.mission.def
	if m == null or m.objectives.is_empty() or m.scoring == "" or state.mission.crippled.has(u.id):
		return [0.0, ""]
	var best := 1 << 20
	for o in m.objectives:
		if o.in_radius(c):
			return [HOLD_WEIGHT * maxi(1, o.vp), "to hold the objective at %s" % Hex.label(o.coord)]
		best = mini(best, Hex.distance(c, o.coord) - o.radius)
	return [-PULL * best, ""]


## A move that leaves by a mission exit and scores, or {}.
static func exit_plan(state: GameState, u: Unit) -> Dictionary:
	var m := state.mission.def
	if m == null or m.exit == "" or state.turn < m.exit_from_turn:
		return {}
	for mode in [MoveMode.Kind.RUN, MoveMode.Kind.WALK, MoveMode.Kind.JUMP]:
		var opts := MovePlanner.plan(state, u, mode)
		for c: Vector2i in opts.reachable_hexes():
			if MissionFlow.exit_kind(state, u, c) != "mission":
				continue
			for k in opts.end_keys_in(c):
				if opts.budget - int(opts.cost.get(k, 0)) >= 1:
					return {"key": k, "mode": mode, "charge": -1, "leave": true,
							"reason": "leaves by the enemy's edge to score %d VP" % VictoryPoints.unit_value(u)}
	return {}
