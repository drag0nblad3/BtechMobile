class_name MotiveDamage
extends RefCounted
## Motive system damage: 2D6 + modifiers when a hit calls for it.
## 6-7 minor (+1 Driving), 8-9 moderate (-1 Cruising MP, +2), 10-11 heavy
## (half Cruising MP, +3), 12+ major (immobile). +1 hit from the rear, +2
## from a side; +2 wheeled, +3 hover.
## TODO(rules): Total Warfare's Motive System Damage Table from general
## knowledge; not in the Core Rulebook.


static func roll(dice: Dice, emit: Callable, u: Unit, arc_id: int) -> void:
	var v := u.vehicle
	var mod := 1 if arc_id == FiringArc.REAR else 2 if arc_id in [FiringArc.LEFT, FiringArc.RIGHT] else 0
	mod += {"w": 2, "h": 3}.get(v.spec.motive, 0)
	var r := dice.roll_2d6()
	var total := r + mod
	var effect := "none"
	if total >= 12:
		effect = "major"
		v.immobile = true
	elif total >= 10:
		effect = "heavy"
		v.half_cruise = true
		v.driving_mod += 3
	elif total >= 8:
		effect = "moderate"
		v.cruise_lost += 1
		v.driving_mod += 2
	elif total >= 6:
		effect = "minor"
		v.driving_mod += 1
	emit.call(GameEvent.VEHICLE, {"kind": "motive", "unit_id": u.id, "roll": r, "mod": mod,
			"effect": effect, "cruise": v.cruise_mp()})
