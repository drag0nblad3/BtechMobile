class_name EcmTypes
extends RefCounted
## ECM suite types. Guardian (p. 200) jams 6 hexes. Angel ECM works the same
## and also degrades boosted C3 (C3Boosted). The Clan Watchdog CEWS is a
## Guardian-style suite with a built-in 5-hex active probe (ActiveProbe).
## TODO(rules): Angel and Watchdog come from MegaMek (weights, slots, BV),
## not the Core Rulebook; ECCM and Angel counting as two suites aren't modelled.

const KINDS := {
	"guardian_ecm": {"name": "Guardian ECM", "tons": 1.5, "slots": 2, "clan_tons": 1.0, "clan_slots": 1, "bv": 61},
	"angel_ecm": {"name": "Angel ECM", "tons": 2.0, "slots": 2, "clan_tons": 2.0, "clan_slots": 2, "bv": 100},
	"watchdog_ecm": {"name": "Watchdog CEWS", "tons": 1.5, "slots": 2, "clan_tons": 1.5, "clan_slots": 2, "bv": 68, "probe": 5},
}


static func kind(def: UnitDef) -> Dictionary:
	return KINDS.get(def.ecm_type, KINDS["guardian_ecm"])


static func tons(def: UnitDef) -> float:
	return float(kind(def)["clan_tons" if def.clan_part("ecm") else "tons"])


static func slots(def: UnitDef) -> int:
	return int(kind(def)["clan_slots" if def.clan_part("ecm") else "slots"])


static func name_of(def: UnitDef) -> String:
	return kind(def)["name"]


static func bv(def: UnitDef) -> float:
	return float(kind(def)["bv"]) if def.ecm_loc >= 0 else 0.0


## Range of the probe built into the suite (Watchdog), 0 if none.
static func probe_range(def: UnitDef) -> int:
	return int(kind(def).get("probe", 0)) if def.ecm_loc >= 0 else 0
