class_name IndirectFire
extends RefCounted
## Indirect fire: LRMs may arc over terrain at a target the shooter can't see
## if a friendly 'Mech can see it and calls the shot ("spotter").
## TODO(rules): verify modifiers: +1 indirect, the spotter's own movement
## (+1 walked, +2 ran, +3 jumped), +1 more if the spotter also fires this phase.
## Woods count between spotter and target; the shooter's range still applies.


## Best friendly 'Mech that can see the target (lowest added modifier), or null.
static func spotter(state: GameState, attacker: Unit, target: Unit) -> Unit:
	var best: Unit = null
	var best_cost := 99
	for u in state.units_of_side(attacker.side):
		if u == attacker or u.destroyed or u.shutdown or not u.pilot.conscious:
			continue
		var los := LineOfSight.check(state.map, u, target)
		if los["blocked"]:
			continue
		var cost := _spotter_mod(state, u) + int(los["woods"])
		if cost < best_cost:
			best = u
			best_cost = cost
	return best


static func add_mods(th: ToHit, state: GameState, spotter: Unit) -> void:
	th.add("indirect fire", 1, "You can't see the target, so %s spots for you; the missiles arc over the terrain." % Names.unit(spotter))
	var m := MoveMode.attacker_mod(spotter.move_mode)
	if m > 0:
		th.add("spotter %s" % MoveMode.verb(spotter.move_mode), m, "Your spotter's own movement spoils its aim for you too.")
	if _spotter_fires(state, spotter):
		th.add("spotter firing", 1, "Your spotter is also shooting this phase, so it's busier: +1.")


static func _spotter_mod(state: GameState, u: Unit) -> int:
	return MoveMode.attacker_mod(u.move_mode) + (1 if _spotter_fires(state, u) else 0)


static func _spotter_fires(state: GameState, u: Unit) -> bool:
	for d: Dictionary in state.declared_fire:
		if int(d["attacker_id"]) == u.id:
			return true
	return false
