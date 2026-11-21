class_name Quad
extends RefCounted
## Four-legged 'Mechs (book pp. 238-239, errata v0.2). The arm locations are
## the front legs. While all four legs stand, a quad gets -2 to every
## piloting roll, stands up without a roll, fires normally while prone (if no
## hip is hit) and can shift sideways. Lost legs: one is -1 walking MP and +1
## to piloting rolls (bonuses gone); two add a hip hit's effect (-2 MP, +2
## total); three act like a biped on one leg; four leave it immobile. The
## first hip hit only blocks kicks that way and prone firing; later ones count
## like a biped's. No torso twists, punches, pushes or clubs.

const PSR_BONUS := -2
const NO_LEGS := "A four-legged 'Mech has no arms"


## All four legs still on: keeps the quad bonuses.
static func intact(u: Unit) -> bool:
	return u.def.quad and u.legs_destroyed() == 0


## Hip actuators hit in legs still attached.
static func raw_hip_hits(u: Unit) -> int:
	var n := 0
	for loc in Location.legs(u.def):
		if not u.is_location_out(loc) and not u.has_working_actuator(loc, "hip"):
			n += 1
	return n


## Hip hits that count like a biped's (the first one doesn't).
static func counted_hips(u: Unit) -> int:
	return maxi(0, raw_hip_hits(u) - 1)


## Leg actuator hits that slow it (surviving legs, first hip free).
static func actuator_hits(u: Unit) -> int:
	var n := 0
	for loc in Location.legs(u.def):
		if u.is_location_out(loc):
			continue
		for s: CritSlot in u.slots[loc]:
			if s.kind == CritSlot.Kind.ACTUATOR and s.hit and s.name != "hip":
				n += 1
	return n + counted_hips(u)


## Walking MP before heat.
static func walk_base(u: Unit) -> int:
	var lost := u.legs_destroyed()
	var w := u.def.walk_mp
	if lost >= 4:
		return 0
	if lost == 3:
		return mini(w, 1)
	return maxi(mini(w, 1), w - lost - actuator_hits(u))


## Lasting piloting modifiers for legs (replaces the biped ones).
static func psr_mods(u: Unit, th: ToHit) -> void:
	var lost := u.legs_destroyed()
	if lost == 0:
		th.add("four legs", PSR_BONUS, "Four legs are steady: -2 to every piloting roll while all of them stand.")
	elif lost <= 2:
		th.add("legs destroyed", lost, "Each lost leg of a four-legged 'Mech: +1 (it keeps its balance on the rest).")
	else:
		th.add("legs destroyed", 4, "Down to one leg: +4, like a two-legged 'Mech on one leg.")
	var act := -mini(1, raw_hip_hits(u))
	for loc in Location.legs(u.def):
		if not u.is_location_out(loc):
			act += Psr.leg_actuator_mod(u, loc)
	if act > 0:
		th.add("leg actuators", act, "Each damaged upper or lower leg actuator, and each hip after the first: +1.")


## Rolls owed for running with lost legs (one lost leg costs none).
static func running_leg_rolls(u: Unit) -> int:
	return 0 if u.legs_destroyed() <= 1 else 1


## A prone quad fires as if standing: no +2, leg weapons work.
static func fires_standing(u: Unit) -> bool:
	return intact(u) and raw_hip_hits(u) == 0


## Roof and bridge support: counts one weight class lighter.
static func support_class(u: Unit, cls: int) -> int:
	return maxi(0, cls - 1) if u.def.quad else cls
