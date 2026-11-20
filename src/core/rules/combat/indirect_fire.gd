class_name IndirectFire
extends RefCounted
## Indirect fire: LRMs may arc over terrain at a target the shooter can't see
## if a friendly 'Mech can see it and calls the shot ("spotter").
## Book p. 70: +1 indirect, + the spotter's attacker movement modifier, and
## +1 if the spotter also attacks this phase (its own attacks get +1 too).
## Terrain counts from the spotter; the shooter's range still applies.
## A 'Mech spots one target per turn (p. 62).
## TODO(rules): a spotter may not charge or DFA that turn (not enforced).


## Best friendly 'Mech that can see the target (lowest added modifier), or null.
static func spotter(state: GameState, attacker: Unit, target: Unit) -> Unit:
	var best: Unit = null
	var best_cost := 99
	for u in state.units_of_side(attacker.side):
		if u == attacker or u.destroyed or u.shutdown or not u.pilot.conscious:
			continue
		var spots := spotting_target(state, u)
		if spots >= 0 and spots != target.id:
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


## Target a 'Mech spots this turn, or -1.
static func spotting_target(state: GameState, u: Unit) -> int:
	var rec: Dictionary = state.spotting.get(u.id, {})
	return int(rec["target"]) if not rec.is_empty() and int(rec["turn"]) == state.turn else -1


## +1 to a spotter's own attacks.
static func add_spotting_mod(th: ToHit, state: GameState, attacker: Unit) -> void:
	if spotting_target(state, attacker) >= 0 and not _has(th, "spotting"):
		th.add("spotting", 1, "You're also calling shots for a friend's indirect fire: +1 to your own.")


## After a 'Mech declares: note who spots for its indirect shots, then add
## the spotter modifiers to shots declared earlier this phase.
static func record(state: GameState, decl: Array[Dictionary]) -> void:
	for d in decl:
		var th: ToHit = d["to_hit"]
		if th.spotter_id >= 0:
			state.spotting[th.spotter_id] = {"target": d["target_id"], "turn": state.turn}
	for d in state.declared_fire:
		var th: ToHit = d["to_hit"]
		add_spotting_mod(th, state, state.unit_by_id(int(d["attacker_id"])))
		if th.spotter_id >= 0 and not _has(th, "spotter firing") \
				and _spotter_fires(state, state.unit_by_id(th.spotter_id)):
			th.add("spotter firing", 1, "Your spotter is also shooting this phase, so it's busier: +1.")


static func _has(th: ToHit, label: String) -> bool:
	for m in th.mods:
		if m["label"] == label:
			return true
	return false
