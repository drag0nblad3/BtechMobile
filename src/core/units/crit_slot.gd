class_name CritSlot
extends RefCounted
## One critical slot on a record sheet. `ref` points at the equipment that
## fills it: an index into Unit.weapons or Unit.ammo, or -1.

enum Kind { EMPTY, ENGINE, GYRO, COCKPIT, SENSORS, LIFE_SUPPORT, ACTUATOR,
		WEAPON, AMMO, HEAT_SINK, JUMP_JET, CASE, ARTEMIS, MELEE, BULK, TARGETING }

var kind: int
var name: String
var ref: int = -1
var hit: bool = false
var hit_when: int = -1  ## turn * 10 + phase when it was hit (see CriticalHits).


func _init(k: int, n: String, r: int = -1) -> void:
	kind = k
	name = n
	ref = r


## Inapplicable slots (p. 94, errata): empty, already destroyed at any point,
## or slots that can't take critical damage (CASE, endo steel, ferro-fibrous).
func can_be_hit() -> bool:
	return kind != Kind.EMPTY and kind != Kind.CASE and kind != Kind.BULK and not hit
