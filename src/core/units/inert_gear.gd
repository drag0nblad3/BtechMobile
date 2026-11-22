class_name InertGear
extends RefCounted
## Gear with no battle rules of its own here: it takes its slots and weight,
## can be destroyed by a critical hit, and the record sheet says what it does.
## TAG's designation attack lives in Tag. TODO(rules): A-pods only hurt
## infantry (p. 189), which the game doesn't have. Weights and slots are
## construction data.

const KINDS := {
	"a_pod": {"name": "A-Pod", "tons": 0.5, "slots": 1, "why": "anti-infantry pods: no infantry in this game"},
	"tag": {"name": "TAG", "tons": 1.0, "slots": 1, "why": "target designator: spots for indirect fire"},
	"c_tag": {"name": "TAG", "tons": 1.0, "slots": 1, "why": "target designator: spots for indirect fire"},
	"c_light_tag": {"name": "Light TAG", "tons": 0.5, "slots": 1, "why": "short-range target designator: spots for indirect fire"},
}


static func tons(def: UnitDef) -> float:
	return def.inert.reduce(func(t: float, g: Dictionary) -> float: return t + float(KINDS[g["kind"]]["tons"]), 0.0)


static func slots(def: UnitDef) -> int:
	return def.inert.reduce(func(t: int, g: Dictionary) -> int: return t + int(KINDS[g["kind"]]["slots"]), 0)
