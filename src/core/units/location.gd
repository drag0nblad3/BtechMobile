class_name Location
extends RefCounted
## 'Mech hit locations, their record-sheet codes and damage transfer.

enum { HEAD, CT, LT, RT, LA, RA, LL, RL }

const COUNT := 8
const CODES := ["HD", "CT", "LT", "RT", "LA", "RA", "LL", "RL"]
const NAMES := ["Head", "Center Torso", "Left Torso", "Right Torso",
		"Left Arm", "Right Arm", "Left Leg", "Right Leg"]
## Four-legged 'Mechs (book p. 238): the arm locations are the front legs.
const QUAD_CODES := ["HD", "CT", "LT", "RT", "FLL", "FRL", "RLL", "RRL"]
const QUAD_NAMES := ["Head", "Center Torso", "Left Torso", "Right Torso",
		"Left Front Leg", "Right Front Leg", "Left Rear Leg", "Right Rear Leg"]
## Locations with separate rear armor.
const HAS_REAR := [CT, LT, RT]


## Accepts the quad codes too (FLL = LA ... RRL = RL).
static func from_code(code: String) -> int:
	return CODES.find(code) if CODES.has(code) else QUAD_CODES.find(code)


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


## Name on this design's record sheet ("Left Front Leg" for a quad's LA).
static func name_for(def: UnitDef, loc: int) -> String:
	return QUAD_NAMES[loc] if def != null and def.quad else NAMES[loc]


static func code_for(def: UnitDef, loc: int) -> String:
	return QUAD_CODES[loc] if def != null and def.quad else CODES[loc]


## Legs of this design: two, or four for a quad.
static func legs(def: UnitDef) -> Array[int]:
	var out: Array[int] = [LL, RL]
	if def != null and def.quad:
		out = [LA, RA, LL, RL]
	return out


static func is_leg_of(def: UnitDef, loc: int) -> bool:
	return is_leg(loc) or (def != null and def.quad and is_arm(loc))


## A real arm (quads have none).
static func is_arm_of(def: UnitDef, loc: int) -> bool:
	return is_arm(loc) and not (def != null and def.quad)
