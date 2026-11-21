class_name ArmFlip
extends RefCounted
## Reversing (flipping) arms (book p. 62). A design whose arms both lack
## lower arm and hand actuators may flip them once a turn instead of
## twisting its torso: its arm weapons then fire into the rear arc only, and
## it can't punch or swing an arm weapon. Not while prone; actuators lost to
## damage don't count. The arms swing back in the End Phase.
## (No design here splits a weapon between torso and arm, the other bar.)


static func design_can(def: UnitDef) -> bool:
	if def.quad:
		return false
	for arm in [Location.LA, Location.RA]:
		if def.has_actuator(arm, "lower_arm") or def.has_actuator(arm, "hand"):
			return false
	return true


## Why `u` can't flip its arms now ("" if it can).
static func problem(u: Unit) -> String:
	if not design_can(u.def):
		return "only arms built without lower arm and hand actuators can flip"
	if u.prone:
		return "a prone 'Mech can't flip its arms"
	if u.torso_twist != 0:
		return "it can twist its torso or flip its arms, not both"
	return ""


## Is this weapon pointing backwards (a rear mount, or an arm flipped back)?
static func rear(u: Unit, w: MountedWeapon) -> bool:
	return w.rear or (u.arms_flipped and Location.is_arm_of(u.def, w.loc))
