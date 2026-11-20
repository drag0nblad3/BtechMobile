class_name ProneFire
extends RefCounted
## Firing while prone (book p. 67): the 'Mech props itself up on one arm.
## Weapons in that arm and in the legs can't fire; with no arm left it can't
## fire at all. We pick the arm for the player: the one whose weapons matter
## least (less total damage), left on a tie.


## Location of the propping arm, or -1 when no arm is left.
static func prop_arm(u: Unit) -> int:
	var la := not u.is_location_destroyed(Location.LA)
	var ra := not u.is_location_destroyed(Location.RA)
	if la and ra:
		return Location.LA if _arm_damage(u, Location.LA) <= _arm_damage(u, Location.RA) else Location.RA
	if la:
		return Location.LA
	return Location.RA if ra else -1


## Why a prone 'Mech can't fire w, or "" if it can.
static func blocked(u: Unit, w: MountedWeapon) -> String:
	if not u.prone:
		return ""
	var arm := prop_arm(u)
	if arm < 0:
		return "A prone 'Mech needs an arm to prop itself up before it can fire"
	if Location.is_leg(w.loc):
		return "Leg weapons can't fire while prone"
	if w.loc == arm:
		return "The %s is propping the 'Mech up" % Location.name_of(arm).to_lower()
	return ""


static func _arm_damage(u: Unit, loc: int) -> int:
	var n := 0
	for w in u.weapons:
		if w.loc == loc and not w.destroyed:
			n += w.def.damage * maxi(1, w.def.missiles)
	return n
