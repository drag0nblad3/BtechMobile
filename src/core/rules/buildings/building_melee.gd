class_name BuildingMelee
extends RefCounted
## Punching, kicking or swinging at an adjacent building hex (book p. 135):
## physical attacks against buildings always hit, and the damage counts
## toward the attacker's Destroy Check like weapon damage. One kind per turn
## as usual (two punches, or one kick or weapon swing). Kicks need the
## building to fill the level of the attacker's legs, punches and swings the
## level above. TODO(rules): which levels each attack reaches is our reading.


## [{kind, limb, to_hit, damage}] against the building at `c`.
static func options(state: GameState, a: Unit, c: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var why := _problem(state, a, c)
	for arm in [Location.LA, Location.RA]:
		out.append(_punch(state, a, c, arm, why))
	out.append(_kick(state, a, c, why))
	for i in a.def.melee.size():
		out.append(_swing(state, a, c, a.def.melee[i]["kind"], a.def.melee[i]["loc"], why, a.melee_lost.has(i)))
	if a.club != "":
		out.append(_swing(state, a, c, "club", -1, why, false))
	return out


## Validates [{kind, limb, hex}] like PhysicalOptions.declare.
static func declare(state: GameState, a: Unit, c: Vector2i, attacks: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for req: Dictionary in attacks:
		for opt in options(state, a, c):
			if opt["kind"] != req["kind"] or opt["limb"] != int(req["limb"]) or not opt["to_hit"].possible():
				continue
			if not out.is_empty() and (opt["kind"] != "punch" or out[0]["kind"] != "punch" or out[0]["limb"] == opt["limb"]):
				continue
			opt["attacker_id"] = a.id
			opt["target_id"] = -1
			opt["target_hex"] = c
			out.append(opt)
	return out


## Resolves one declared attack on a building (always hits).
static func resolve(state: GameState, emit: Callable, a: Unit, d: Dictionary) -> void:
	var c: Vector2i = d["target_hex"]
	emit.call(GameEvent.PHYSICAL, {"attacker_id": a.id, "target_id": -1, "target_hex": c,
			"kind": d["kind"], "limb": d["limb"], "roll": 0, "need": 2, "hit": true,
			"damage": d["damage"], "mods": d["to_hit"].mods})
	BuildingDamage.add(state, a.id, c, d["damage"])
	if d["kind"] == "club" and a.club == "tree":
		a.club = ""


static func _problem(state: GameState, a: Unit, c: Vector2i) -> String:
	var tile := state.map.get_tile(c)
	if tile == null or tile.building == null:
		return "No building there"
	if Hex.distance(a.coord, c) != 1:
		return "Physical attacks need an adjacent building"
	if a.prone:
		return "Can't make physical attacks while prone"
	return ""


## Does the building in `c` fill the level `up` above the attacker's feet?
static func _reaches(state: GameState, a: Unit, c: Vector2i, up: int) -> bool:
	var own := state.map.get_tile(a.coord)
	var feet := own.level + (own.building.height if a.on_roof and own.building else 0)
	var tile := state.map.get_tile(c)
	var lvl := feet + up
	return tile.level < lvl and tile.level + tile.building.height >= lvl


static func _opt(kind: String, limb: int, damage: int, why: String) -> Dictionary:
	var th := ToHit.new()
	th.impossible = why
	if why == "":
		th.auto_hit = "Buildings can't dodge"
	return {"kind": kind, "limb": limb, "to_hit": th, "damage": damage}


static func _punch(state: GameState, a: Unit, c: Vector2i, arm: int, why: String) -> Dictionary:
	var dmg := ceili(a.def.tonnage / 10.0)
	if why == "":
		var arc_id := FiringArc.fire_arc(a.coord, a.torso_facing(), c)
		if a.is_location_out(arm) or not a.has_working_actuator(arm, "shoulder"):
			why = "%s can't punch" % Location.name_of(arm)
		elif arc_id != FiringArc.FRONT and arc_id != (FiringArc.LEFT if arm == Location.LA else FiringArc.RIGHT):
			why = "The building isn't in front of that arm"
		elif PhysicalMods.limb_fired(a, arm):
			why = "That arm fired a weapon this turn"
		elif not _reaches(state, a, c, 2):
			why = "The building is too low to punch; kick it"
	for act in ["upper_arm", "lower_arm"]:
		if not a.has_working_actuator(arm, act):
			@warning_ignore("integer_division")
			dmg = dmg / 2
	return _opt("punch", arm, dmg, why)


static func _kick(state: GameState, a: Unit, c: Vector2i, why: String) -> Dictionary:
	var dmg := ceili(a.def.tonnage / 5.0)
	if why == "":
		if a.legs_destroyed() > 0 or a.hip_hits() > 0:
			why = "Can't kick with a damaged hip or a missing leg"
		elif FiringArc.fire_arc(a.coord, a.facing, c) != FiringArc.FRONT:
			why = "Kicks only hit buildings in front of your feet"
		elif PhysicalMods.limb_fired(a, Location.RL) or PhysicalMods.limb_fired(a, Location.LL):
			why = "A leg fired a weapon this turn"
		elif not _reaches(state, a, c, 1):
			why = "The building is below your feet"
	for l in [Location.LL, Location.RL]:
		for act in ["upper_leg", "lower_leg"]:
			if not a.has_working_actuator(l, act):
				@warning_ignore("integer_division")
				dmg = dmg / 2
	return _opt("kick", Location.RL, dmg, why)


static func _swing(state: GameState, a: Unit, c: Vector2i, kind: String, arm: int, why: String, lost: bool) -> Dictionary:
	if why == "":
		var arc_id := FiringArc.fire_arc(a.coord, a.torso_facing(), c)
		if lost or (arm >= 0 and a.is_location_out(arm)):
			why = "The %s is destroyed" % kind
		elif arm < 0 and MeleeWeapons.grip_problem(a) != "":
			why = MeleeWeapons.grip_problem(a)
		elif arm >= 0 and not a.has_working_actuator(arm, "shoulder"):
			why = "A broken shoulder can't swing a %s" % kind
		elif arc_id != FiringArc.FRONT and (arm < 0 or arc_id != (FiringArc.LEFT if arm == Location.LA else FiringArc.RIGHT)):
			why = "The building isn't in front of you"
		elif PhysicalMods.limb_fired(a, Location.LA if arm < 0 else arm) or (arm < 0 and PhysicalMods.limb_fired(a, Location.RA)):
			why = "That arm fired a weapon this turn"
		elif not _reaches(state, a, c, 2):
			why = "The building is too low to swing at"
	return _opt(kind, arm, MeleeWeapons.damage(kind, a.def.tonnage), why)
