class_name MechCondition
extends RefCounted
## A 'Mech's lasting damage between battles: armor, structure, critical
## slots, equipment and ammo, as a plain Dictionary that saves to JSON.
## Turn state (heat, prone, MASC, flooding) is left behind; a new battle
## starts cool and standing. Empty Dictionary = factory fresh.

const UNIT_FLAGS := ["engine_hits", "gyro_hits", "sensor_hits", "heat_sinks_lost"]
const UNIT_BOOLS := ["ecm_lost", "probe_lost", "tc_lost", "sc_lost"]
const WEAPON_BOOLS := ["destroyed", "exploded", "spent", "artemis_lost", "apollo_lost", "capacitor_lost"]
const ARRAYS := ["armor", "rear_armor", "structure", "armor_partial", "rear_partial", "structure_partial"]


## The lasting damage on `u` after a battle.
static func capture(u: Unit) -> Dictionary:
	var d := {}
	for k: String in ARRAYS:
		d[k] = Array(u.get(k))
	for k: String in UNIT_FLAGS + UNIT_BOOLS:
		d[k] = u.get(k)
	var lost: Array = []
	for i: int in u.melee_lost:
		lost.append(i)
	d["melee_lost"] = lost
	var hits: Array = []
	for loc in u.slots.size():
		var row: Array = []
		for i in u.slots[loc].size():
			if u.slots[loc][i].hit:
				row.append(i)
		hits.append(row)
	d["slot_hits"] = hits
	var weps: Array = []
	for w in u.weapons:
		var wd := {"crit_hits": w.crit_hits}
		for k: String in WEAPON_BOOLS:
			wd[k] = w.get(k)
		weps.append(wd)
	d["weapons"] = weps
	var bins: Array = []
	for a in u.ammo:
		bins.append({"shots": a.shots, "destroyed": a.destroyed})
	d["ammo"] = bins
	d["destroyed"] = u.destroyed
	d["destroyed_reason"] = u.destroyed_reason
	return d


## Like capture, but {} when `u` is as good as new (nothing to fix or reload).
static func lasting(u: Unit) -> Dictionary:
	var d := capture(u)
	var fresh := capture(Unit.new(0, u.def, u.side, Hex.INVALID, 0))
	return {} if d == fresh else d


## Puts saved damage back on a freshly built Unit of the same design.
static func apply(u: Unit, d: Dictionary) -> void:
	if d.is_empty():
		return
	for k: String in ARRAYS:
		var src: Array = d.get(k, [])
		var dst: Array[int] = u.get(k)
		for i in mini(src.size(), dst.size()):
			dst[i] = int(src[i])
	for k: String in UNIT_FLAGS:
		u.set(k, int(d.get(k, 0)))
	for k: String in UNIT_BOOLS:
		u.set(k, bool(d.get(k, false)))
	for i in d.get("melee_lost", []):
		u.melee_lost[int(i)] = true
	var hits: Array = d.get("slot_hits", [])
	for loc in mini(hits.size(), u.slots.size()):
		for i in hits[loc]:
			if int(i) < u.slots[loc].size():
				u.slots[loc][int(i)].hit = true
	var weps: Array = d.get("weapons", [])
	for i in mini(weps.size(), u.weapons.size()):
		u.weapons[i].crit_hits = int(weps[i].get("crit_hits", 0))
		for k: String in WEAPON_BOOLS:
			u.weapons[i].set(k, bool(weps[i].get(k, false)))
	var bins: Array = d.get("ammo", [])
	for i in mini(bins.size(), u.ammo.size()):
		u.ammo[i].shots = int(bins[i].get("shots", u.ammo[i].shots))
		u.ammo[i].destroyed = bool(bins[i].get("destroyed", false))
	u.destroyed = bool(d.get("destroyed", false))
	u.destroyed_reason = String(d.get("destroyed_reason", ""))


## Written off: the center torso is gone, so there is nothing left to
## rebuild around. Everything else can be repaired. TODO(rules): app rule.
static func written_off(d: Dictionary) -> bool:
	var s: Array = d.get("structure", [])
	return s.size() > Location.CT and int(s[Location.CT]) <= 0
