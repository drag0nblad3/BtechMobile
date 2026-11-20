class_name PhysicalOptions
extends RefCounted
## Punches, kicks and pushes one 'Mech could make against an adjacent enemy
## (book pp. 76-83). One kind per turn: one or two punches, one kick, or a push.
## Punch: piloting -1, ceil(tons / 10), Punch table; arm in front or that side.
## Kick: piloting -1, ceil(tons / 5), Kick table (full table on a prone
## target); both hips working, target in front of the feet.
## Push: piloting -1, no damage, both arms, same level, straight ahead of the
## feet; the target is shoved one hex.
## Different levels: a standing target one level up takes punches on the Kick
## table and can't be kicked; one level down takes kicks on the Punch table
## and can't be punched. A prone target can be kicked at the same level and
## punched from one level below.


## [{kind: "punch"|"kick"|"push", limb, to_hit, damage, table: "punch"|"kick"|"full"}]
static func for_target(state: GameState, a: Unit, t: Unit) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for arm in [Location.LA, Location.RA]:
		out.append(_punch(state, a, t, arm))
	for leg in [Location.RL, Location.LL]:
		out.append(_kick(state, a, t, leg))
	out.append(_push(state, a, t))
	return out


static func _push(state: GameState, a: Unit, t: Unit) -> Dictionary:
	var th := ToHit.new()
	var opt := {"kind": "push", "limb": -1, "to_hit": th, "damage": 0, "table": ""}
	if not PhysicalMods.can_reach(state, a, t, th):
		return opt
	if FiringArc.wedge(a.coord, a.facing, t.coord) != 0:
		th.impossible = "Pushes need the target straight ahead of your feet"
	elif t.prone:
		th.impossible = "Can't push a 'Mech that is already down"
	elif PhysicalMods.level_diff(state, a, t) != 0:
		th.impossible = "Pushes need both 'Mechs on the same level"
	elif a.is_location_destroyed(Location.LA) or a.is_location_destroyed(Location.RA):
		th.impossible = "Pushing needs both arms"
	elif PhysicalMods.limb_fired(a, Location.LA) or PhysicalMods.limb_fired(a, Location.RA):
		th.impossible = "Both arms are needed; one fired a weapon"
	elif PhysicalMods.charging(state, t):
		th.impossible = "It is charging this turn and can't be pushed"
	elif PhysicalMods.shoved_already(state, t):
		th.impossible = "Someone is already charging or pushing it this turn"
	if th.impossible != "":
		return opt
	PhysicalMods.add(th, state, a, t)
	th.add("push", -1, "Shoving is easier than punching: -1, but does no damage.")
	for arm in [Location.LA, Location.RA]:
		if a.def.has_actuator(arm, "shoulder") and not a.has_working_actuator(arm, "shoulder"):
			th.add("shoulder hit", 2, "Each broken shoulder: +2 to push.")
	return opt


static func _punch(state: GameState, a: Unit, t: Unit, arm: int) -> Dictionary:
	var th := ToHit.new()
	var dmg := ceili(a.def.tonnage / 10.0)
	var opt := {"kind": "punch", "limb": arm, "to_hit": th, "damage": dmg, "table": "punch"}
	if not PhysicalMods.can_reach(state, a, t, th):
		return opt
	var dl := PhysicalMods.level_diff(state, a, t)
	var arc_id := FiringArc.fire_arc(a.coord, a.torso_facing(), t.coord)
	var side := FiringArc.LEFT if arm == Location.LA else FiringArc.RIGHT
	if a.is_location_destroyed(arm) or not a.has_working_actuator(arm, "shoulder"):
		th.impossible = "%s can't punch" % Location.name_of(arm)
	elif arc_id != FiringArc.FRONT and arc_id != side:
		th.impossible = "Target isn't in front of that arm"
	elif t.prone and dl != 1:
		th.impossible = "You can't punch a 'Mech lying at your feet; kick it"
	elif dl == -1:
		th.impossible = "The target is below you; kick it instead"
	elif PhysicalMods.limb_fired(a, arm):
		th.impossible = "That arm fired a weapon this turn"
	if th.impossible != "":
		return opt
	PhysicalMods.add(th, state, a, t, true, false)
	th.add("punch", -1, "Punches are a little easier than a gun shot: -1.")
	if not a.has_working_actuator(arm, "hand"):
		th.add("no hand", 1, "Punching without a working hand actuator: +1.")
	for act in ["upper_arm", "lower_arm"]:
		if not a.has_working_actuator(arm, act):
			th.add("no " + act.replace("_", " "), 2, "A missing or broken arm actuator: +2, half damage.")
			@warning_ignore("integer_division")
			dmg = dmg / 2
	opt["damage"] = dmg
	if dl == 1 and not t.prone:
		opt["table"] = "kick"  # swinging up at its legs
	return opt


static func _kick(state: GameState, a: Unit, t: Unit, leg: int) -> Dictionary:
	var th := ToHit.new()
	var dmg := ceili(a.def.tonnage / 5.0)
	var opt := {"kind": "kick", "limb": leg, "to_hit": th, "damage": dmg, "table": "kick"}
	if not PhysicalMods.can_reach(state, a, t, th):
		return opt
	var dl := PhysicalMods.level_diff(state, a, t)
	if a.legs_destroyed() > 0 or a.hip_hits() > 0:
		th.impossible = "Can't kick with a damaged hip or a missing leg"
	elif FiringArc.fire_arc(a.coord, a.facing, t.coord) != FiringArc.FRONT:
		th.impossible = "Kicks only hit targets in front of your feet"
	elif dl == 1:
		th.impossible = "The target is above you; punch it instead"
	elif dl == -1 and t.prone:
		th.impossible = "A 'Mech lying below you can only be jumped on"
	elif PhysicalMods.limb_fired(a, leg):
		th.impossible = "That leg fired a weapon this turn"
	if th.impossible != "":
		return opt
	PhysicalMods.add(th, state, a, t)
	th.add("kick", -1, "Kicks are a little easier than a gun shot: -1.")
	for l in [Location.LL, Location.RL]:
		for act in ["upper_leg", "lower_leg"]:
			if not a.has_working_actuator(l, act):
				th.add("%s %s hit" % [Location.name_of(l), act.replace("_", " ")], 2,
						"A broken leg actuator in either leg: +2, half damage.")
				@warning_ignore("integer_division")
				dmg = dmg / 2
		if not a.has_working_actuator(l, "foot"):
			th.add("%s foot hit" % Location.name_of(l), 1, "A broken foot in either leg: +1.")
	opt["damage"] = dmg
	if t.prone:
		opt["table"] = "full"
	elif dl == -1:
		opt["table"] = "punch"  # kicking down at its upper body
	return opt


## Validates a declaration [{kind, limb, target_id}]: two punches or one kick.
static func declare(state: GameState, a: Unit, attacks: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var kicked := false
	var used := {}
	for req: Dictionary in attacks:
		var t := state.unit_by_id(int(req["target_id"]))
		for opt in for_target(state, a, t):
			if opt["kind"] != req["kind"] or opt["limb"] != int(req["limb"]):
				continue
			if not opt["to_hit"].possible() or used.has(opt["limb"]) or kicked:
				continue
			if (opt["kind"] == "kick" or opt["kind"] == "push") and not out.is_empty():
				continue
			kicked = opt["kind"] == "kick" or opt["kind"] == "push"
			used[opt["limb"]] = true
			opt["attacker_id"] = a.id
			opt["target_id"] = t.id
			out.append(opt)
	return out


## Any punch or kick possible against any enemy?
static func any_possible(state: GameState, a: Unit) -> bool:
	for t in state.units:
		if t.side == a.side or t.destroyed or Hex.distance(a.coord, t.coord) != 1:
			continue
		for opt in for_target(state, a, t):
			if opt["to_hit"].possible():
				return true
	return false
