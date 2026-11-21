class_name Tsm
extends RefCounted
## Triple-strength myomer (book p. 205). It wakes up when the 'Mech ran hot:
## a turn that starts at heat 9 or more (the heat it ended last turn with)
## gives +2 walking MP before heat penalties, and doubles punch, kick and
## club damage, and hatchet and sword damage. Its six slots can't take
## critical hits. A supercharger's bonus comes after TSM's.
## TODO(rules): construction (Inner Sphere 6 slots, 0 tons) is general knowledge.

const HEAT := 9
const MP_BONUS := 2
const SLOTS := 6
const DOUBLED := ["punch", "kick", "club", "hatchet", "sword"]


static func has(def: UnitDef) -> bool:
	for loc: int in def.bulk_slots:
		if def.bulk_slots[loc].has("tsm"):
			return true
	return false


## Working now: hot enough, and the 'Mech carries it.
static func active(u: Unit) -> bool:
	return u.heat >= HEAT and has(u.def)


static func mp_bonus(u: Unit) -> int:
	return MP_BONUS if active(u) else 0


## Doubles the damage of the attacks TSM powers, in place.
static func boost(u: Unit, opts: Array[Dictionary]) -> void:
	if not active(u):
		return
	for o in opts:
		if DOUBLED.has(o["kind"]):
			o["damage"] = int(o["damage"]) * 2
			o["tsm"] = true
