class_name VehicleLoc
extends RefCounted
## Combat vehicle locations and their record-sheet codes. They share the
## index space of `Location` (the same armor arrays), so a vehicle's armor[0]
## is its front. BODY holds ammo and gear and takes no hits.
## TODO(rules): Total Warfare vehicle rules aren't in the Core Rulebook;
## structure points follow the usual tonnage / 10, rounded up.

enum { FRONT, LEFT, RIGHT, REAR, TURRET, BODY }

const COUNT := 6
const CODES := ["FR", "LS", "RS", "RR", "TU", "BD"]
const NAMES := ["Front", "Left Side", "Right Side", "Rear", "Turret", "Body"]
const ARMORED := [FRONT, LEFT, RIGHT, REAR, TURRET]


static func from_code(code: String) -> int:
	return CODES.find(code)


static func name_of(loc: int) -> String:
	return NAMES[loc]


## Internal structure per location.
static func structure(tons: int) -> int:
	return ceili(tons / 10.0)
