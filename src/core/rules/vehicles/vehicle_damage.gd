class_name VehicleDamage
extends RefCounted
## Damage to a combat vehicle: armor, then structure. Losing a location's
## structure destroys the vehicle, except the turret, which is blown off.
## Hit-table results call for motive system rolls and critical hit
## checks, as does structure damage: 8+ on 2D6 means one roll on the
## critical table.
## TODO(rules): Total Warfare vehicle damage from general knowledge.

const CRIT_CHECK := 8


## One packet of damage from an attack arriving from FiringArc `arc_id`.
static func take(dice: Dice, emit: Callable, u: Unit, arc_id: int, amount: int,
		source_id: int, source: String) -> void:
	var hl := VehicleHitTable.roll(dice, arc_id, u.def.vehicle.turret and not u.vehicle.turret_lost)
	var loc: int = hl["loc"]
	var to_armor := mini(amount, u.armor[loc])
	u.armor[loc] -= to_armor
	var to_structure := mini(amount - to_armor, u.structure[loc])
	u.structure[loc] -= to_structure
	emit.call(GameEvent.DAMAGE, {"unit_id": u.id, "source_id": source_id, "source": source,
			"amount": amount, "loc": loc, "vehicle": true, "hit_roll": hl["roll"],
			"armor_left": u.armor[loc], "structure_left": u.structure[loc], "steps": []})
	if u.structure[loc] == 0 and to_structure > 0:
		_lose_location(u, loc)
	Damage.announce(emit, u)
	if u.destroyed:
		return
	if hl["motive"]:
		MotiveDamage.roll(dice, emit, u, arc_id)
	if (hl["crit"] or to_structure > 0) and dice.roll_2d6() >= CRIT_CHECK:
		VehicleCrits.roll(dice, emit, u, loc)


static func _lose_location(u: Unit, loc: int) -> void:
	if loc == VehicleLoc.TURRET:
		VehicleCrits.apply(u, loc, "turret_off")
		return
	Damage.destroy_unit(u, "its %s was destroyed" % VehicleLoc.name_of(loc).to_lower())
