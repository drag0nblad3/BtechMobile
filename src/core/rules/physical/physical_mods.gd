class_name PhysicalMods
extends RefCounted
## Checks and modifiers shared by every physical attack (book pp. 76-77).
## The base is the attacker's piloting skill; all the usual ranged attack
## modifiers apply except heat and sensors (no range: the target is adjacent).
## Death from above also ignores terrain. Physical rolls are not piloting
## rolls, so piloting roll modifiers (gyro hits and so on) don't count.


## Adjacent enemy, attacker standing, ground within one level. Sets
## th.impossible and returns false otherwise.
static func can_reach(state: GameState, a: Unit, t: Unit, th: ToHit) -> bool:
	if t == null or t.destroyed or t.side == a.side:
		th.impossible = "No enemy target"
	elif Hex.distance(a.coord, t.coord) != 1:
		th.impossible = "Physical attacks need an adjacent target"
	elif a.prone:
		th.impossible = "Can't make physical attacks while prone"
	elif absi(level_diff(state, a, t)) > 1:
		th.impossible = "Target is too far above or below you"
	return th.impossible == ""


## Piloting, both 'Mechs' movement, terrain, partial cover, prone and immobile
## targets. `terrain` false skips woods and partial cover (death from above).
static func add(th: ToHit, state: GameState, a: Unit, t: Unit, terrain: bool = true,
		cover: bool = true) -> void:
	th.add("Piloting", a.pilot.piloting, "Physical attacks use piloting skill, not gunnery.")
	ToHitCalc.add_movement(th, a, t)
	if terrain:
		var tile := state.map.get_tile(t.coord)
		var tw := LineOfSight.woods_value(tile) if tile else 0
		if tw > 0:
			th.add("target in woods", tw, "Woods get in the way of fists and feet too.")
		if cover and ToHitCalc.in_partial_cover(state.map, t):
			th.add("partial cover", 1, "The target's legs are under water.")
		elif BuildingRules.half_inside(state.map, t):
			th.add("partial cover", 1, "The target stands half inside a one-level building.")
		var inside := BuildingRules.inside_mod(state.map, t)
		if inside > 0:
			th.add("inside a building", inside, "The target is fighting from inside a building: +2.")
	if t.prone:
		th.add("target prone", -2, "A 'Mech on the ground next to you is easy to hit: -2.")
	if ToHitCalc.is_immobile(t):
		th.add("target immobile", -4, "A 'Mech that can't move can't dodge: -4.")


## Target's ground level minus the attacker's.
static func level_diff(state: GameState, a: Unit, t: Unit) -> int:
	return _floor(state, t) - _floor(state, a)


static func limb_fired(a: Unit, loc: int) -> bool:
	for w in a.weapons:
		if w.loc == loc and w.fired:
			return true
	return false


## Already the target of a charge, death from above or push this turn?
static func shoved_already(state: GameState, t: Unit) -> bool:
	for d: Dictionary in state.declared_physical:
		if int(d["target_id"]) == t.id and d["kind"] in ["charge", "dfa", "push"]:
			return true
	return false


## Busy charging or jumping onto someone this turn?
static func charging(state: GameState, u: Unit) -> bool:
	for d: Dictionary in state.declared_physical:
		if int(d["attacker_id"]) == u.id and d["kind"] in ["charge", "dfa"]:
			return true
	return false


static func _floor(state: GameState, u: Unit) -> int:
	var tile := state.map.get_tile(u.coord)
	return tile.floor_level() if tile else 0
