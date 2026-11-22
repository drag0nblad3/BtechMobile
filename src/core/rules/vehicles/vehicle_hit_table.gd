class_name VehicleHitTable
extends RefCounted
## Where a shot strikes a combat vehicle: 2D6 by the side it comes from.
## Some results also call for a motive system roll ("motive") or a
## critical hit check ("crit"). Without a turret, turret results strike
## the side facing the attacker.
## TODO(rules): Total Warfare's Ground Combat Vehicle Hit Location Table
## from general knowledge; not in the Core Rulebook.


## {loc, motive, crit, roll} for an attack from FiringArc `arc_id`.
static func roll(dice: Dice, arc_id: int, has_turret: bool) -> Dictionary:
	var r := dice.roll_2d6()
	var facing := _facing_loc(arc_id)
	var out := {"loc": facing, "motive": false, "crit": false, "roll": r}
	match r:
		2:
			out["crit"] = true
		3, 4:
			out["motive"] = true
		5:
			out["loc"] = _left_of(arc_id)
			out["motive"] = true
		9:
			out["loc"] = _right_of(arc_id)
			out["motive"] = true
		10, 11:
			out["loc"] = VehicleLoc.TURRET
		12:
			out["loc"] = VehicleLoc.TURRET
			out["crit"] = true
	if out["loc"] == VehicleLoc.TURRET and not has_turret:
		out["loc"] = facing
	return out


static func _facing_loc(arc_id: int) -> int:
	match arc_id:
		FiringArc.FRONT:
			return VehicleLoc.FRONT
		FiringArc.REAR:
			return VehicleLoc.REAR
		FiringArc.LEFT:
			return VehicleLoc.LEFT
	return VehicleLoc.RIGHT


## The neighbouring location a 5 strikes: from the front the right side,
## from the rear the left, from a side the front.
static func _left_of(arc_id: int) -> int:
	match arc_id:
		FiringArc.FRONT:
			return VehicleLoc.RIGHT
		FiringArc.REAR:
			return VehicleLoc.LEFT
	return VehicleLoc.FRONT


## A 9: from the front the left side, from the rear the right, from a side the rear.
static func _right_of(arc_id: int) -> int:
	match arc_id:
		FiringArc.FRONT:
			return VehicleLoc.LEFT
		FiringArc.REAR:
			return VehicleLoc.RIGHT
	return VehicleLoc.REAR
