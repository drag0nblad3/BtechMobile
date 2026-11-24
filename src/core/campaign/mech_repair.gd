class_name MechRepair
extends RefCounted
## Support Point repairs on a company 'Mech (Campaign Operations p. 163):
## armor (tonnage SP), internal structure (tonnage x 2 SP) and a full
## rearm (5 SP Introductory, 10 SP Standard). Clan 'Mechs cost double.
## Each job restores its whole share of the record sheet at once.
## TODO(rules): structure repair also fixes critical hits, equipment and
## a knocked-out 'Mech; the table has no line of its own for them.

const ARMOR := "armor"
const STRUCTURE := "structure"
const AMMO := "ammo"
const JOBS := [ARMOR, STRUCTURE, AMMO]
const ARMOR_KEYS := ["armor", "rear_armor", "armor_partial", "rear_partial"]
const STRUCTURE_KEYS := ["structure", "structure_partial", "engine_hits", "gyro_hits", "sensor_hits",
		"heat_sinks_lost", "ecm_lost", "probe_lost", "tc_lost", "sc_lost", "melee_lost", "slot_hits", "weapons"]


## Does `m` need `job`? A written-off 'Mech can't be repaired.
static func needs(m: CampaignMech, def: UnitDef, job: String) -> bool:
	if m.written_off or m.condition.is_empty():
		return false
	var fresh := _fresh(def)
	var cond := _full(m, def, fresh)
	match job:
		ARMOR:
			return _differs(cond, fresh, ARMOR_KEYS)
		STRUCTURE:
			return _differs(cond, fresh, STRUCTURE_KEYS) or _bins_lost(cond) or bool(cond.get("destroyed", false))
		AMMO:
			for i in cond["ammo"].size():
				if int(cond["ammo"][i]["shots"]) != int(fresh["ammo"][i]["shots"]):
					return true
	return false


## Support Points `job` costs on `def`.
static func cost(def: UnitDef, job: String, rules: ChaosRules) -> int:
	var n := 0
	match job:
		ARMOR:
			n = def.tonnage * rules.sp("repair_armor_per_ton")
		STRUCTURE:
			n = def.tonnage * rules.sp("repair_structure_per_ton")
		AMMO:
			n = rules.sp("rearm_intro" if IntroTech.is_intro(def, rules) else "rearm_standard")
	return n * (rules.sp("clan_multiplier") if def.is_clan() else 1)


## Does `job` on `m` (no payment; SupportShop pays).
static func apply(m: CampaignMech, def: UnitDef, job: String) -> void:
	var fresh := _fresh(def)
	var cond := _full(m, def, fresh)
	match job:
		ARMOR:
			_copy(cond, fresh, ARMOR_KEYS)
		STRUCTURE:
			_copy(cond, fresh, STRUCTURE_KEYS)
			for b: Dictionary in cond["ammo"]:
				b["destroyed"] = false
			cond["destroyed"] = false
			cond["destroyed_reason"] = ""
		AMMO:
			for i in cond["ammo"].size():
				cond["ammo"][i]["shots"] = fresh["ammo"][i]["shots"]
	m.condition = {} if cond == fresh else cond


## A 'Mech whose MechWarrior died with nothing broken is ready again once
## someone else climbs in: clears "destroyed" when the structure is whole.
static func tidy(m: CampaignMech, def: UnitDef) -> void:
	if m.condition.is_empty() or not bool(m.condition.get("destroyed", false)):
		return
	var fresh := _fresh(def)
	var cond := _full(m, def, fresh)
	if not _differs(cond, fresh, STRUCTURE_KEYS) and not _bins_lost(cond):
		cond["destroyed"] = false
		cond["destroyed_reason"] = ""
		m.condition = {} if cond == fresh else cond


static func _fresh(def: UnitDef) -> Dictionary:
	return MechCondition.capture(Unit.new(0, def, 0, Hex.INVALID, 0))


## The saved condition with every key filled in.
static func _full(m: CampaignMech, def: UnitDef, fresh: Dictionary) -> Dictionary:
	var u := Unit.new(0, def, 0, Hex.INVALID, 0)
	MechCondition.apply(u, m.condition)
	var d := MechCondition.capture(u)
	return d if not m.condition.is_empty() else fresh.duplicate(true)


static func _differs(a: Dictionary, b: Dictionary, keys: Array) -> bool:
	for k: String in keys:
		if a.get(k) != b.get(k):
			return true
	return false


static func _copy(dst: Dictionary, src: Dictionary, keys: Array) -> void:
	for k: String in keys:
		dst[k] = src[k].duplicate(true) if src[k] is Array else src[k]


static func _bins_lost(cond: Dictionary) -> bool:
	for b: Dictionary in cond.get("ammo", []):
		if bool(b.get("destroyed", false)):
			return true
	return false
