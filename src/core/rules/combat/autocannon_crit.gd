class_name AutocannonCrit
extends RefCounted
## Sturdy autocannons (book p. 183): the first critical hit on an autocannon
## of any kind (AC, Ultra, LB-X, rotary) marks its slot but the gun keeps
## firing. A second critical hit on another of its slots disables it. A
## one-slot autocannon needs its single slot hit twice.

static var _pattern: RegEx


static func is_autocannon(d: WeaponDef) -> bool:
	if _pattern == null:
		_pattern = RegEx.create_from_string("(^|_)ac\\d*$")
	return d.type == "ballistic" and _pattern.search(d.id) != null


## Applies one critical hit to the weapon. True when the gun still works.
static func absorb(w: MountedWeapon) -> bool:
	if not is_autocannon(w.def) or w.destroyed:
		return false
	w.crit_hits += 1
	return w.crit_hits < 2


## A one-slot autocannon's slot can be hit again while the gun still works.
static func rehittable(u: Unit, s: CritSlot) -> bool:
	if s.kind != CritSlot.Kind.WEAPON or not s.hit or s.ref < 0:
		return false
	var w: MountedWeapon = u.weapons[s.ref]
	return is_autocannon(w.def) and w.def.slots == 1 and not w.destroyed
