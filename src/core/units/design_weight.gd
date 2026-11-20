class_name DesignWeight
extends RefCounted
## Adds up what a design weighs (structure, engine, gyro, cockpit, heat sinks,
## jump jets, armor, weapons, ammo) so a bad data file shows up in tests.
## TODO(rules): construction rules are not in the Core Rulebook; engine
## weights (data/construction.json) and the rest are general knowledge.

const COCKPIT_TONS := 3.0
const ARMOR_PER_TON := 16.0
## Ferro-fibrous gives 12% more points per ton; endo steel halves structure.
const FERRO_MULT := 1.12

static var _engine: Dictionary = {}


## Tons per part: {structure, engine, gyro, cockpit, heat_sinks, jump_jets,
## armor, weapons, ammo}. engine is -1 when the rating isn't in the table.
static func breakdown(def: UnitDef) -> Dictionary:
	var rating := def.tonnage * def.walk_mp
	var armor_pts := def.total_armor()
	var weapons := 0.0
	for m in def.weapon_mounts:
		weapons += (m["weapon"] as WeaponDef).tons + (1.0 if m.get("artemis", false) else 0.0)
	return {
		"structure": _half_up(def.tonnage / 10.0 * (0.5 if def.structure_type == "endo_steel" else 1.0)),
		"engine": XlEngine.tons(engine_tons(rating), def.is_xl()),
		"gyro": float(ceili(rating / 100.0)),
		"cockpit": COCKPIT_TONS,
		"heat_sinks": float(maxi(0, def.heat_sinks - UnitDef.ENGINE_HEAT_SINKS)),
		"jump_jets": def.jump_mp * jump_jet_tons(def.tonnage),
		"armor": _half_up(armor_pts / (ARMOR_PER_TON * (FERRO_MULT if def.armor_type == "ferro_fibrous" else 1.0))),
		"weapons": weapons,
		"ammo": float(def.ammo_mounts.size()),
		"case": def.case_locs.size() * 0.5,
		"melee": def.melee.reduce(func(t: float, m: Dictionary) -> float: return t + def.melee_tons(m["kind"]), 0.0),
	}


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
