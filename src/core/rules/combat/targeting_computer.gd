class_name TargetingComputer
extends RefCounted
## Targeting computer (p. 200): -1 to hit for linked weapons, which are
## direct-fire energy and ballistic weapons (pulse lasers included) except
## flamers, machine guns and anything firing as a cluster (missiles, LB-X
## cluster rounds, Ultra double fire). It also allows aimed shots at moving
## 'Mechs (AimedShot): +3 instead of the -1, never at the head, not with
## pulse weapons. A critical hit destroys it.
## TODO(rules): size (1 slot and 1 t per 4 t of linked weapons, rounded up)
## is construction data, not in the Core Rulebook; no BV bonus yet.

const MOD := -1
const MOBILE_AIM_MOD := 3


static func linked(w: MountedWeapon) -> bool:
	var d := w.def
	if d.ams or d.heat_damage or d.id == "machine_gun" or d.is_cluster():
		return false
	if d.type != "energy" and d.type != "ballistic":
		return false
	return WeaponModes.ammo_kind(w) != WeaponModes.CLUSTER and WeaponModes.shots(w) == 1


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
		if not d.ams and not d.heat_damage and d.id != "machine_gun" and not d.is_cluster() \
				and (d.type == "energy" or d.type == "ballistic"):
			tons += d.tons
	return maxi(1, ceili(tons / 4.0))
