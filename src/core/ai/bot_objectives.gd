class_name BotObjectives
extends RefCounted
## Mission sense for the bot's movement: standing on objectives it can score
## (and not letting the enemy hold them), and leaving by a mission exit when
## that scores.

const HOLD_WEIGHT := 4.0  ## Value per VP of an objective it would stand on.
const PULL := 0.4  ## Per hex nearer the closest objective worth taking.
const SCAN_WEIGHT := 2.0  ## Ending within scanning range of something worth scanning.


## Extra score for ending at `c`, and a phrase for the reason ("" if none).
static func bonus(state: GameState, u: Unit, c: Vector2i) -> Array:
	var m := state.mission.def
	if m == null or state.mission.crippled.has(u.id):
		return [0.0, ""]
	var held := MobileObjectives.carried_by(state, u)
	if held != null and m.exit_side == u.side:  # Steel Rain: take it home
		return [HOLD_WEIGHT - PULL * MapEdges.distance(state.map, c, m.home_edge(u.side)), "carrying the cache toward its home edge"]
	if held != null:
		return [HOLD_WEIGHT, "carrying the objective (it holds it wherever it goes)"]
	if m.scan in ["units", "intel"]:
		return _scan_bonus(state, u, c)
	if m.objectives.is_empty() or m.scoring == "":
		return [0.0, ""]
	var best := 1 << 20
	for o in m.objectives:
		if o.destroyed or o.carrier_id >= 0:
			continue
		if o.potential:  # Objective Raid: scan it first
			if Hex.distance(c, o.coord) <= Scanning.RANGE:
				return [SCAN_WEIGHT, "to scan the possible objective at %s" % Hex.label(o.coord)]
			best = mini(best, Hex.distance(c, o.coord) - Scanning.RANGE)
			continue
		if o.in_radius(c):
			var grab := o.mobile and c == o.coord and MobileObjectives.free_hand(u) >= 0
			return [HOLD_WEIGHT * maxi(1, o.vp) + (2.0 if grab else 0.0),
					("to pick up the objective at %s" if grab else "to hold the objective at %s") % Hex.label(o.coord)]
		best = mini(best, Hex.distance(c, o.coord) - o.radius)
	return [0.0 if best == 1 << 20 else -PULL * best, ""]


## Being in scanning range at the End Phase (Scanning).
static func _scan_bonus(state: GameState, u: Unit, c: Vector2i) -> Array:
	var best := 1 << 20
	if state.mission.def.scan == "units":
		for e in state.units:
			if e.side != u.side and not e.destroyed:
				if Hex.distance(c, e.coord) <= Scanning.RANGE:
					return [SCAN_WEIGHT, "to scan %s in the End Phase" % Names.unit(e)]
				best = mini(best, Hex.distance(c, e.coord) - Scanning.RANGE)
	else:
		for o in state.mission.def.objectives:
			if o.kind == "intel" and not o.claimed.has(u.side):
				if Hex.distance(c, o.coord) <= Scanning.RANGE:
					return [SCAN_WEIGHT * 1.5, "to scan the building at %s for intel" % Hex.label(o.coord)]
				best = mini(best, Hex.distance(c, o.coord) - Scanning.RANGE)
	return [0.0 if best == 1 << 20 else -PULL * best, ""]


## A move that leaves by a mission exit and scores, or {}.
static func exit_plan(state: GameState, u: Unit) -> Dictionary:
	var m := state.mission.def
	if m == null or m.exit == "" or state.turn < m.exit_from_turn:
		return {}
	if m.scoring == "steel_rain" and MobileObjectives.carried_by(state, u) == null:
		return {}  # only worth leaving with a cache
	for mode in [MoveMode.Kind.RUN, MoveMode.Kind.WALK, MoveMode.Kind.JUMP]:
		var opts := MovePlanner.plan(state, u, mode)
		for c: Vector2i in opts.reachable_hexes():
			if MissionFlow.exit_kind(state, u, c) != "mission":
				continue
			for k in opts.end_keys_in(c):
				if opts.budget - int(opts.cost.get(k, 0)) >= 1:
					var why := "leaves by the enemy's edge to score %d VP" % VictoryPoints.unit_value(u)
					if m.scoring == "steel_rain":
						why = "carries the cache off the map by its home edge: it stays theirs and keeps scoring"
					elif m.scan == "units":
						why = "leaves by its home edge with its sensor readings: %d VP" % int(state.mission.scans.get(u.id, 0))
					return {"key": k, "mode": mode, "charge": -1, "leave": true, "reason": why}
	return {}
