class_name DesignWeight
extends RefCounted
## Adds up what a design weighs (structure, engine, gyro, cockpit, heat sinks,
## jump jets, armor, weapons, ammo) so a bad data file shows up in tests.
## TODO(rules): construction rules are not in the Core Rulebook; engine
## weights (data/construction.json) and the rest are general knowledge.

const ARMOR_PER_TON := 16.0
## Ferro-fibrous gives 12% more points per ton; endo steel halves structure.
const FERRO_MULT := 1.12
const LIGHT_FERRO_MULT := 1.06
const HEAVY_FERRO_MULT := 1.24

static var _engine: Dictionary = {}


## Tons per part: {structure, engine, gyro, cockpit, heat_sinks, jump_jets,
## armor, weapons, ammo}. engine is -1 when the rating isn't in the table.
static func breakdown(def: UnitDef) -> Dictionary:
	var rating := def.tonnage * def.walk_mp
	var armor_pts := def.total_armor()
	var weapons := 0.0
	for m in def.weapon_mounts:
		weapons += (m["weapon"] as WeaponDef).tons + (1.0 if m.get("artemis", false) else 0.0) \
				+ (Apollo.TONS if m.get("apollo", false) else 0.0) \
				+ (PpcCapacitor.TONS if m.get("capacitor", false) else 0.0)
	return {
		"structure": _half_up(def.tonnage / 10.0 * (0.5 if def.structure_type == "endo_steel" else 1.0)),
		"engine": XlEngine.tons(engine_tons(rating), def.engine_type),
		"gyro": Gyro.tons(def),
		"cockpit": Cockpit.tons(def),
		"heat_sinks": float(maxi(0, def.heat_sinks - UnitDef.ENGINE_HEAT_SINKS)),
		"jump_jets": JumpJets.tons(def, jump_jet_tons(def.tonnage)),
		"armor": _half_up(armor_pts / (ARMOR_PER_TON * armor_mult(def))),
		"weapons": weapons,
		"ammo": def.ammo_mounts.reduce(func(t: float, a: Dictionary) -> float: return t + (0.5 if a.get("half", false) else 1.0), 0.0),
		"case": def.case_locs.size() * 0.5 + def.case2_locs.size() * (0.5 if def.clan_part("case") else 1.0),
		"ecm": Ecm.tons(def) if def.ecm_loc >= 0 else 0.0,
		"c3": C3Boosted.tons(def),
		"masc": float(Masc.size(def)) if def.masc_loc >= 0 else 0.0,
		"inert": InertGear.tons(def),
		"probe": float(ActiveProbe.KINDS[def.probe]["tons"]) if def.probe != "" else 0.0,
		"supercharger": Supercharger.size_tons(def) if def.supercharger_loc >= 0 else 0.0,
		"targeting_computer": float(TargetingComputer.size(def)) if def.tc_loc >= 0 else 0.0,
		"melee": def.melee.reduce(func(t: float, m: Dictionary) -> float: return t + def.melee_tons(m["kind"]), 0.0),
	}


## Armor points per ton relative to standard. TODO(rules): construction data.
static func armor_mult(def: UnitDef) -> float:
	match def.armor_type:
		"ferro_fibrous":
			return ferro_mult(def)
		"light_ferro":
			return LIGHT_FERRO_MULT
		"heavy_ferro":
			return HEAVY_FERRO_MULT
	return 1.0


static func ferro_mult(def: UnitDef) -> float:
	return ClanTech.FERRO_MULT if def.clan_part("armor") else FERRO_MULT


## Heat sinks the engine can hold without using critical slots: rating / 25.
## The first 10 weigh nothing; a small engine lists some of those 10 as items.
## TODO(rules): construction data, not in the Core Rulebook.
static func engine_sink_capacity(def: UnitDef) -> int:
	return def.tonnage * def.walk_mp / 25


static func total(def: UnitDef) -> float:
	var t := 0.0
	for v: float in breakdown(def).values():
		t += v
	return t


static func _half_up(t: float) -> float:
	return ceilf(snappedf(t * 2.0, 0.0001)) / 2.0


static func jump_jet_tons(tonnage: int) -> float:
	if tonnage <= 55:
		return 0.5
	return 1.0 if tonnage <= 85 else 2.0


static func engine_tons(rating: int) -> float:
	if _engine.is_empty():
		var d: Dictionary = JsonFile.read("res://data/construction.json")
		_engine = d["engine_tons"]
	return float(_engine.get(str(rating), -1.0))
