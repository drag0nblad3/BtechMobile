class_name Phase
extends RefCounted
## Turn sequence (Total Warfare): each turn runs these phases in order.

enum Kind { INITIATIVE, MOVEMENT, WEAPON_ATTACK, PHYSICAL_ATTACK, HEAT, END }

const NAMES := {
	Kind.INITIATIVE: "Initiative",
	Kind.MOVEMENT: "Movement",
	Kind.WEAPON_ATTACK: "Weapon Attack",
	Kind.PHYSICAL_ATTACK: "Physical Attack",
	Kind.HEAT: "Heat",
	Kind.END: "End",
}


static func name_of(k: int) -> String:
	return NAMES.get(k, "?")


static func next(k: int) -> int:
	return (k + 1) % Kind.size()
