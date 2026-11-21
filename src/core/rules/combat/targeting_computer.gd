class_name TargetingComputer
extends RefCounted
## Targeting computer (p. 200): -1 to hit for linked weapons, which are
## direct-fire energy and ballistic weapons (pulse lasers included) except
## flamers, machine guns (Clan light and heavy too) and cluster weapons or
## attacks (missiles, LB-X cluster rounds). Rapid-firing Ultra and rotary
## ACs keep the -1 (p. 200). It also allows aimed shots at moving
## 'Mechs (AimedShot): +3 instead of the -1, never at the head, not with
## pulse weapons. A critical hit destroys it.
## TODO(rules): size (1 slot and 1 t per 4 t of linked weapons, 5 t if Clan, rounded up)
## is construction data, not in the Core Rulebook; no BV bonus yet.

const MOD := -1
const MOBILE_AIM_MOD := 3


static func linked(w: MountedWeapon) -> bool:
	var d := w.def
	if not eligible(d):
		return false
	return WeaponModes.ammo_kind(w) != WeaponModes.CLUSTER


## Weapon types a targeting computer links to (and is sized by).
static func eligible(d: WeaponDef) -> bool:
	return not d.ams and not d.heat_damage and not d.name.ends_with("Machine Gun") \
			and not d.is_cluster() and (d.type == "energy" or d.type == "ballistic")


## Has a working targeting computer.
static func working(u: Unit) -> bool:
	return u.def.tc_loc >= 0 and not u.tc_lost and not u.is_location_destroyed(u.def.tc_loc)


static func applies(u: Unit, w: MountedWeapon) -> bool:
	return working(u) and linked(w)


static func add(th: ToHit, u: Unit, w: MountedWeapon) -> void:
	if applies(u, w):
		th.add("targeting computer", MOD, "The targeting computer steadies direct-fire weapons: -1.")


## Slots (and tons) for a design's targeting computer.
static func size(def: UnitDef) -> int:
	var tons := 0.0
	for m in def.weapon_mounts:
		var d: WeaponDef = m["weapon"]
		if eligible(d):
			tons += d.tons
	return maxi(1, ceili(tons / ClanTech.tc_tons_per_slot(def)))
