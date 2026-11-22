class_name Plasma
extends RefCounted
## Plasma weapons: a hit on a 'Mech also adds heat, rolled on d6s (plasma
## rifle 1d6 on top of its 10 damage, plasma cannon 2d6 and no damage).
## The heat counts as outside heat, so the Heat Phase cap still applies.
## Book p. 189. TODO(rules): plasma starting fires is not modelled.


static func add_heat(dice: Dice, d: WeaponDef, target: Unit, data: Dictionary) -> void:
	var h := 0
	for i in d.heat_dice:
		h += dice.d6()
	target.outside_heat += h
	data["heat_added"] = h
