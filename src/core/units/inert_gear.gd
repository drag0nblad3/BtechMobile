class_name InertGear
extends RefCounted
## Gear that official designs carry but that does nothing in this game yet:
## it takes its slots and weight, can be destroyed by a critical hit, and the
## record sheet says why it sits idle. TODO(rules): A-pods only hurt infantry
## (p. 189), which the game doesn't have; TAG (p. 200) only guides
## semi-guided missiles and artillery homing rounds, which it doesn't have
## either. Weights and slots are construction data.

const KINDS := {
	"a_pod": {"name": "A-Pod", "tons": 0.5, "slots": 1, "why": "anti-infantry pods: no infantry in this game"},
	"tag": {"name": "TAG", "tons": 1.0, "slots": 1, "why": "target designator: no TAG-guided munitions in this game"},
	"c_tag": {"name": "TAG", "tons": 1.0, "slots": 1, "why": "target designator: no TAG-guided munitions in this game"},
}


static func tons(def: UnitDef) -> float:
	return def.inert.reduce(func(t: float, g: Dictionary) -> float: return t + float(KINDS[g["kind"]]["tons"]), 0.0)


static func slots(def: UnitDef) -> int:
	return def.inert.reduce(func(t: int, g: Dictionary) -> int: return t + int(KINDS[g["kind"]]["slots"]), 0)
