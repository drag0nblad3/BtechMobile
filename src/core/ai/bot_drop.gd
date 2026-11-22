class_name BotDrop
extends RefCounted
## Where the computer aims a combat drop: next to the objective that most
## needs it (one an enemy is carrying first, then any free one), on open
## ground, not crowded by enemies; otherwise a few hexes from the nearest
## enemy. It faces the nearest enemy.


## {hex, facing, reason}
static func plan(state: GameState, u: Unit) -> Dictionary:
	var goal := _goal(state, u)
	var best := Hex.INVALID
	var best_s := -INF
	for c: Vector2i in state.map.coords():
		var t := state.map.get_tile(c)
		if state.unit_at(c) != null or t.building != null or t.is_water():
			continue
		var s := -absf(Hex.distance(c, goal["hex"]) - float(goal["range"]))
		for e in state.units:
			if e.side != u.side and not e.destroyed and Hex.distance(c, e.coord) <= 1:
				s -= 1.5
		s -= 0.2 * t.terrain.move_cost  # rough and woods don't change the roll, but slow it later
		if s > best_s:
			best_s = s
			best = c
	if best == Hex.INVALID:
		best = Deployment.center(state.map)
	var e := BotMove.nearest_enemy(state, u, best)
	var facing := Hex.direction_to(best, e.coord) if e else 0
	return {"hex": best, "facing": facing, "reason": "combat drops near %s %s" % [Hex.label(goal["hex"]), goal["why"]]}


static func _goal(state: GameState, u: Unit) -> Dictionary:
	var m := state.mission.def
	if m != null:
		for o in m.objectives:
			var c := MobileObjectives.carrier(state, o)
			if c != null and c.side != u.side and not c.destroyed and not state.mission.exited.has(c.id):
				return {"hex": c.coord, "range": 2, "why": "to stop the 'Mech carrying off an objective"}
		for o in m.objectives:
			if not o.destroyed and o.carrier_id < 0:
				return {"hex": o.coord, "range": 1, "why": "to secure the objective"}
	var e := BotMove.nearest_enemy(state, u, Deployment.center(state.map))
	if e:
		return {"hex": e.coord, "range": 4, "why": "to join the fight"}
	return {"hex": Deployment.center(state.map), "range": 0, "why": "in the middle of the field"}
