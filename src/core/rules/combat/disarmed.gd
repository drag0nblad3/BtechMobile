class_name Disarmed
extends RefCounted
## A 'Mech whose ranged weapons are all destroyed (or that never had any) and
## that is immobile counts as destroyed (book p. 99). Anti-missile systems
## aren't attacks, so they don't count; a weapon merely out of ammo or
## jammed still counts as working. Checked in the End Phase.


static func no_ranged_weapons(u: Unit) -> bool:
	for w in u.weapons:
		if not w.def.ams and not w.destroyed and not u.is_location_out(w.loc):
			return false
	return true


## Destroys the unit if it is both disarmed and immobile. True if it did.
static func check(u: Unit) -> bool:
	if u.destroyed or not ToHitCalc.is_immobile(u) or not no_ranged_weapons(u):
		return false
	Damage.destroy_unit(u, "no working weapons and can't move")
	return true
