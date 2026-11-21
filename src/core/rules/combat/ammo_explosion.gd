class_name AmmoExplosion
extends RefCounted
## An ammo bin explodes (book pp. 95-96): its remaining shots' damage, capped
## at 20, goes straight into internal structure and transfers inward
## structure-to-structure. If the uncapped damage was over 20 and the last
## location hit survives, it loses its armor (rear armor for a torso).
## CASE in a location (p. 96) caps it at 10 structure there plus up to 10 to
## armor (rear for a torso), and nothing transfers out of it. CASE II
## (p. 96) caps structure damage at 1, then up to 10 to armor the same way.
## Critical checks there get -1 with CASE II (p. 91).
## The MechWarrior takes 1 hit from the feedback either way.

const CAP := 20
const CASE_CAP := 10
const CASE_II_CAP := 1


static func explode(state: GameState, dice: Dice, emit: Callable, u: Unit, bin: AmmoBin) -> void:
	var base := bin.explosion_damage()
	bin.shots = 0
	bin.destroyed = true
	if base <= 0:
		return
	var steps := internal(u, bin.loc, base)
	var dmg := 0
	for s in steps:
		dmg += int(s["structure"]) + int(s["armor"])
	emit.call(GameEvent.AMMO_EXPLOSION, {"unit_id": u.id, "loc": bin.loc,
			"ammo": bin.weapon.name, "damage": dmg, "base": base, "steps": steps,
			"case": steps.any(func(s: Dictionary) -> bool: return s.get("case", false))})
	PilotDamage.wound(dice, emit, u, 1, "ammo explosion")
	Damage.announce(emit, u)
	CriticalHits.after_damage(state, dice, emit, u, steps, false)


## Internal explosion damage from `loc` with the caps above. Also used for
## exploding components.
static func internal(u: Unit, loc: int, base: int) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	if u.def.case2_locs.has(loc):
		steps.append(_case(u, loc, base, CASE_II_CAP))
		return steps
	if u.def.has_case(loc):
		steps.append(_case(u, loc, base))
		return steps
	var left := mini(base, CAP)
	while left > 0 and loc >= 0 and not u.destroyed:
		if (u.def.has_case(loc) or u.def.case2_locs.has(loc)) and not u.is_location_destroyed(loc):
			steps.append(_case(u, loc, left, CASE_II_CAP if u.def.case2_locs.has(loc) else CASE_CAP))  # transferred in
			return steps
		var part := Damage.apply_internal_one(u, loc, left)
		left -= int(part["structure"])
		steps.append(part)
		loc = Location.transfer(loc)
	if base > CAP and not steps.is_empty() and not u.destroyed:
		var last: int = steps[-1]["loc"]
		if not u.is_location_destroyed(last):
			if Location.HAS_REAR.has(last):
				u.rear_armor[last] = 0
			else:
				u.armor[last] = 0
	return steps


static func _case(u: Unit, loc: int, amount: int, cap: int = CASE_CAP) -> Dictionary:
	var step := Damage.apply_internal_one(u, loc, mini(amount, cap))
	step["case"] = true
	if cap == CASE_II_CAP:
		step["case2"] = true
	if amount > cap and not u.is_location_destroyed(loc) and not u.destroyed:
		var rear := Location.HAS_REAR.has(loc)
		var arm := u.rear_armor if rear else u.armor
		var a := mini(arm[loc], mini(amount - cap, CASE_CAP))
		arm[loc] -= a
		u.damage_this_phase += a
		step["armor"] = a
		step["rear"] = rear
	return step
