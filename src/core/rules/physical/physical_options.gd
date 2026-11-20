class_name PhysicalOptions
extends RefCounted
## Punches and kicks one 'Mech could make against an adjacent enemy.
## A 'Mech may punch with each arm, or kick once, per turn.
## Punch: piloting skill, ceil(tons / 10) damage. Kick: piloting - 2,
## ceil(tons / 5) damage, and the target must make a piloting roll.
## TODO(rules): level differences, prone targets and actuator rules simplified.


## [{kind: "punch"|"kick", limb: Location, to_hit: ToHit, damage: int}]
static func for_target(state: GameState, a: Unit, t: Unit) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for arm in [Location.LA, Location.RA]:
		out.append(_punch(state, a, t, arm))
	for leg in [Location.RL, Location.LL]:
		out.append(_kick(state, a, t, leg))
	out.append(_push(state, a, t))
	return out


## Push: both arms, target straight ahead, piloting -1, no damage; the target
## is shoved one hex back and must roll to stay up.
static func _push(state: GameState, a: Unit, t: Unit) -> Dictionary:
	var th := ToHit.new()
	var opt := {"kind": "push", "limb": -1, "to_hit": th, "damage": 0}
	if not _common(state, a, t, th):
		return opt
	if FiringArc.wedge(a.coord, a.torso_facing(), t.coord) != 0:
		th.impossible = "Pushes need the target straight ahead"
	elif t.prone:
		th.impossible = "Can't push a 'Mech that is already down"
	elif _arm_fired(a, Location.LA) or _arm_fired(a, Location.RA):
		th.impossible = "Both arms are needed; one fired a weapon"
	elif a.is_location_destroyed(Location.LA) or a.is_location_destroyed(Location.RA):
		th.impossible = "Pushing needs both arms"
	if th.impossible == "":
		th.add("push", -1, "Shoving is easier than punching: -1, but does no damage.")
	return opt


static func _common(state: GameState, a: Unit, t: Unit, th: ToHit) -> bool:
	if t == null or t.destroyed or t.side == a.side:
		th.impossible = "No enemy target"
	elif Hex.distance(a.coord, t.coord) != 1:
		th.impossible = "Physical attacks need an adjacent target"
	elif a.prone:
		th.impossible = "Can't make physical attacks while prone"
	elif absi(_floor(state, a) - _floor(state, t)) > 1:
		th.impossible = "Target is too far above or below you"
	if th.impossible != "":
		return false
	th.add("Piloting", a.pilot.piloting, "Physical attacks use piloting skill, not gunnery.")
	ToHitCalc.add_movement(th, a, t)
	var tile := state.map.get_tile(t.coord)
	var tw := LineOfSight.woods_value(tile) if tile else 0
	if tw > 0:
		th.add("target in woods", tw, "Woods get in the way of fists and feet too.")
	if t.shutdown or not t.pilot.conscious:
		th.add("target immobile", -4, "A 'Mech that can't move is easy to hit.")
	return true


static func _punch(state: GameState, a: Unit, t: Unit, arm: int) -> Dictionary:
	var th := ToHit.new()
	var dmg := ceili(a.def.tonnage / 10.0)
	var opt := {"kind": "punch", "limb": arm, "to_hit": th, "damage": dmg}
	if not _common(state, a, t, th):
		return opt
	var arc_id := FiringArc.fire_arc(a.coord, a.torso_facing(), t.coord)
	var side := FiringArc.LEFT if arm == Location.LA else FiringArc.RIGHT
	if a.is_location_destroyed(arm) or not a.has_working_actuator(arm, "shoulder"):
		th.impossible = "%s can't punch" % Location.name_of(arm)
	elif arc_id != FiringArc.FRONT and arc_id != side:
		th.impossible = "Target isn't in front of that arm"
	elif t.prone:
		th.impossible = "You can't punch a 'Mech lying on the ground; kick it"
	elif _arm_fired(a, arm):
		th.impossible = "That arm fired a weapon this turn"
	if th.impossible != "":
		return opt
	if not a.has_working_actuator(arm, "hand"):
		th.add("no hand", 1, "Punching without a working hand actuator: +1.")
	for act in ["upper_arm", "lower_arm"]:
		if not a.has_working_actuator(arm, act):
			th.add("no " + act.replace("_", " "), 2, "A missing or broken arm actuator: +2, half damage.")
			dmg = ceili(dmg / 2.0)
	opt["damage"] = dmg
	return opt


static func _kick(state: GameState, a: Unit, t: Unit, leg: int) -> Dictionary:
	var th := ToHit.new()
	var dmg := ceili(a.def.tonnage / 5.0)
	var opt := {"kind": "kick", "limb": leg, "to_hit": th, "damage": dmg}
	if not _common(state, a, t, th):
		return opt
	if a.legs_destroyed() > 0 or not a.has_working_actuator(leg, "hip"):
		th.impossible = "Can't kick with a damaged hip or a missing leg"
	elif FiringArc.fire_arc(a.coord, a.facing, t.coord) != FiringArc.FRONT:
		th.impossible = "Kicks only hit targets in front of you"
	if th.impossible != "":
		return opt
	th.add("kick", -2, "Kicks are easier to land than punches: -2.")
	for act in ["upper_leg", "lower_leg"]:
		if not a.has_working_actuator(leg, act):
			th.add("no " + act.replace("_", " "), 2, "A broken leg actuator: +2, half damage.")
			dmg = ceili(dmg / 2.0)
	if not a.has_working_actuator(leg, "foot"):
		th.add("foot hit", 1, "A broken foot: +1.")
	opt["damage"] = dmg
	return opt


static func _arm_fired(a: Unit, arm: int) -> bool:
	for w in a.weapons:
		if w.loc == arm and w.fired:
			return true
	return false


static func _floor(state: GameState, u: Unit) -> int:
	var tile := state.map.get_tile(u.coord)
	return tile.floor_level() if tile else 0


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
