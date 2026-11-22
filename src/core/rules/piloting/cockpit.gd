class_name Cockpit
extends RefCounted
## Cockpit types. A small cockpit weighs 2 t instead of 3, frees two head
## slots (life support, sensors, cockpit, sensors, then two free) and its
## cramped MechWarrior takes +1 on every piloting roll.
## TODO(rules): from MegaMek, not in the Core Rulebook.

const SMALL_HEAD := ["Life Support", "Sensors", "Cockpit", "Sensors", "", ""]
const STANDARD_TONS := 3.0
const SMALL_TONS := 2.0
const SMALL_PSR := 1


static func small(def: UnitDef) -> bool:
	return def.cockpit_type == "small"


static func head(def: UnitDef) -> Array:
	return SMALL_HEAD if small(def) else CritLayout.HEAD


static func tons(def: UnitDef) -> float:
	return SMALL_TONS if small(def) else STANDARD_TONS


static func add_psr(th: ToHit, u: Unit) -> void:
	if small(u.def):
		th.add("small cockpit", SMALL_PSR, "A cramped small cockpit: +1 to piloting rolls.")
