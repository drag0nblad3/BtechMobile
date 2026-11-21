class_name MeleeWeapons
extends RefCounted
## Hatchets, swords and clubs (pp. 79, 81-82, 194-196). One physical weapon
## attack replaces all other physical attacks that turn.
## Hatchet: piloting -1, ceil(tons / 5). Sword: piloting -2, ceil(tons / 10) + 1.
## Both: arm not fired, target in front or that arm's side; destroyed hand or
## shoulder: no attack; missing/broken lower arm and broken upper arm +2 each.
## Club (a tree from woods or a girder from rubble, picked up in the weapon
## phase instead of firing): piloting -1, ceil(tons / 5), target in front,
## no arm weapons fired, both hands and shoulders working, +2 per broken
## upper/lower arm actuator; the target makes a piloting roll. A tree breaks
## after one hit. They use the full Hit Location Table, also against a prone
## target on the same level (-2) or one level up; a standing target one level
## up takes the swing on the Kick table, one level down on the Punch table
## (no +4 when the level forces it). A prone target one level down can't be
## reached (p. 77).
## TODO(rules): the optional Punch/Kick table at +4 isn't offered.

const KINDS := ["hatchet", "sword"]
const LOW_PRONE := "Only death from above reaches a prone 'Mech a level below"


## Hit table for a swing at a target `dl` levels up (p. 77): "full", "kick"
## (up at a standing 'Mech's legs), "punch" (down at its upper body), or ""
## when it can't be reached (prone, one level down).
static func swing_table(dl: int, prone: bool) -> String:
	if dl == 0 or (dl == 1 and prone):
		return "full"
	if prone:
		return ""
	return "kick" if dl == 1 else "punch"


static func damage(kind: String, tons: int) -> int:
	match kind:
		"sword":
			return ceili(tons / 10.0) + 1
	return ceili(tons / 5.0)  # hatchet, club


static func options(state: GameState, a: Unit, t: Unit) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in a.def.melee.size():
		out.append(_weapon(state, a, t, i))
	if a.club != "":
		out.append(_club(state, a, t))
	return out


static func _weapon(state: GameState, a: Unit, t: Unit, i: int) -> Dictionary:
	var m: Dictionary = a.def.melee[i]
	var kind: String = m["kind"]
	var arm: int = m["loc"]
	var th := ToHit.new()
	var opt := {"kind": kind, "limb": arm, "to_hit": th, "damage": damage(kind, a.def.tonnage), "table": "full"}
	if not PhysicalMods.can_reach(state, a, t, th, "punch"):
		return opt
	var arc_id := FiringArc.fire_arc(a.coord, a.torso_facing(), t.coord)
	var side := FiringArc.LEFT if arm == Location.LA else FiringArc.RIGHT
	if a.melee_lost.has(i) or a.is_location_out(arm):
		th.impossible = "The %s is destroyed" % kind
	elif a.arms_flipped:
		th.impossible = "Its arms are flipped backwards this turn"
	elif not a.has_working_actuator(arm, "shoulder"):
		th.impossible = "A broken shoulder can't swing a %s" % kind
	elif a.def.has_actuator(arm, "hand") and not a.has_working_actuator(arm, "hand"):
		th.impossible = "A broken hand can't hold the %s" % kind
	elif arc_id != FiringArc.FRONT and arc_id != side:
		th.impossible = "Target isn't in front of that arm"
	elif PhysicalMods.limb_fired(a, arm):
		th.impossible = "That arm fired a weapon this turn"
	elif swing_table(PhysicalMods.level_diff(state, a, t), t.prone) == "":
		th.impossible = LOW_PRONE
	if th.impossible != "":
		return opt
	opt["table"] = swing_table(PhysicalMods.level_diff(state, a, t), t.prone)
	PhysicalMods.add(th, state, a, t)
	if kind == "sword":
		th.add("sword", -2, "A sword is a precise weapon: -2.")
	else:
		th.add("hatchet", -1, "A hatchet is easier to land than a gun shot: -1.")
	for act in ["upper_arm", "lower_arm"]:
		if not a.has_working_actuator(arm, act):
			th.add("no " + act.replace("_", " "), 2, "A missing or broken arm actuator: +2.")
	return opt


static func _club(state: GameState, a: Unit, t: Unit) -> Dictionary:
	var th := ToHit.new()
	var opt := {"kind": "club", "limb": -1, "to_hit": th, "damage": damage("club", a.def.tonnage), "table": "full"}
	if not PhysicalMods.can_reach(state, a, t, th, "punch"):
		return opt
	var why := grip_problem(a)
	if why != "":
		th.impossible = why
	elif FiringArc.fire_arc(a.coord, a.torso_facing(), t.coord) != FiringArc.FRONT:
		th.impossible = "Clubs only hit targets in front of you"
	elif PhysicalMods.limb_fired(a, Location.LA) or PhysicalMods.limb_fired(a, Location.RA):
		th.impossible = "An arm fired a weapon this turn"
	elif swing_table(PhysicalMods.level_diff(state, a, t), t.prone) == "":
		th.impossible = LOW_PRONE
	if th.impossible != "":
		return opt
	opt["table"] = swing_table(PhysicalMods.level_diff(state, a, t), t.prone)
	PhysicalMods.add(th, state, a, t)
	th.add("club", -1, "A club swing: -1.")
	for arm in [Location.LA, Location.RA]:
		for act in ["upper_arm", "lower_arm"]:
			if not a.has_working_actuator(arm, act):
				th.add("%s %s hit" % [Location.code(arm), act.replace("_", " ")], 2, "Each broken arm actuator: +2.")
	return opt


## Why a 'Mech can't hold a club ("" if it can): two working hands and shoulders.
static func grip_problem(u: Unit) -> String:
	for arm in [Location.LA, Location.RA]:
		if not u.has_working_actuator(arm, "shoulder") or not u.has_working_actuator(arm, "hand"):
			return "A club needs both hands and both shoulders working"
	return ""


## What club this 'Mech could pick up where it stands ("" none).
static func club_here(state: GameState, u: Unit) -> String:
	if u.club != "" or u.prone or grip_problem(u) != "":
		return ""
	var tile := state.map.get_tile(u.coord)
	if tile == null or tile.building != null:
		return ""
	if tile.terrain.id.ends_with("woods"):
		return "tree"
	if tile.terrain.id == "rubble":
		return "girder"
	return ""
