class_name Location
extends RefCounted
## 'Mech hit locations, their record-sheet codes and damage transfer.

enum { HEAD, CT, LT, RT, LA, RA, LL, RL }

const COUNT := 8
const CODES := ["HD", "CT", "LT", "RT", "LA", "RA", "LL", "RL"]
const NAMES := ["Head", "Center Torso", "Left Torso", "Right Torso",
		"Left Arm", "Right Arm", "Left Leg", "Right Leg"]
## Locations with separate rear armor.
const HAS_REAR := [CT, LT, RT]


static func from_code(code: String) -> int:
	return CODES.find(code)


static func code(loc: int) -> String:
	return CODES[loc]


static func name_of(loc: int) -> String:
	return NAMES[loc]


## Where excess damage goes once a location is destroyed (-1 = nowhere:
## destroying the head or center torso destroys the 'Mech).
static func transfer(loc: int) -> int:
	match loc:
		LA, LL:
			return LT
		RA, RL:
			return RT
		LT, RT:
			return CT
	return -1


static func is_arm(loc: int) -> bool:
	return loc == LA or loc == RA


static func is_leg(loc: int) -> bool:
	return loc == LL or loc == RL


static func is_torso(loc: int) -> bool:
	return loc == CT or loc == LT or loc == RT


## The arm that is lost with a side torso.
static func arm_of_torso(loc: int) -> int:
	return LA if loc == LT else (RA if loc == RT else -1)
