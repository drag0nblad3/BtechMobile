class_name QuadKick
extends RefCounted
## Kicks by four-legged 'Mechs (book p. 238). A front kick needs only the two
## front hips. A "mule kick" hits a target in the rear arc with the rear legs:
## both rear hips working and no leg lost. Only the kicking pair's leg
## actuators change the roll and damage. Bipeds kick with both legs.


## The legs a kick with `leg` uses: both legs for a biped; the front or rear
## pair for a quad.
static func pair(a: Unit, leg: int) -> Array[int]:
	var out: Array[int] = [Location.LL, Location.RL]
	if a.def.quad and Location.is_arm(leg):
		out = [Location.LA, Location.RA]
	return out


static func is_mule(a: Unit, leg: int) -> bool:
	return a.def.quad and Location.is_leg(leg)


## The arc the target must be in, measured from the feet.
static func arc_needed(a: Unit, leg: int) -> int:
	return FiringArc.REAR if is_mule(a, leg) else FiringArc.FRONT


## Why this kick can't be made by damage ("" if it can).
static func problem(a: Unit, leg: int) -> String:
	if not a.def.quad:
		return "Can't kick with a damaged hip or a missing leg" if a.legs_destroyed() > 0 or a.hip_hits() > 0 else ""
	var mule := is_mule(a, leg)
	for l in pair(a, leg):
		if a.is_location_out(l) or not a.has_working_actuator(l, "hip"):
			return "Needs both %s legs with working hips" % ("rear" if mule else "front")
	if mule and not Quad.intact(a):
		return "A four-legged 'Mech that lost a leg can't mule kick"
	return ""


## Kick options for a quad: front kicks with either front leg, mule kicks with either rear leg.
static func limbs(a: Unit) -> Array[int]:
	var out: Array[int] = [Location.RL, Location.LL]
	if a.def.quad:
		out = [Location.RA, Location.LA, Location.RL, Location.LL]
	return out
