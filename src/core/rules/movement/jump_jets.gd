class_name JumpJets
extends RefCounted
## Jump jet types. Improved jump jets (p. 51, heat p. 102) build 1 heat per
## 2 hexes jumped (rounded up), still at least 3. Each improved jet takes 2
## slots and twice a standard jet's weight; one critical hit on either slot
## costs that jet's 1 MP.
## TODO(rules): improved jet slots and weight are construction data, not in
## the Core Rulebook.

const IMPROVED := "improved"


static func improved(def: UnitDef) -> bool:
	return def.jump_jet_type == IMPROVED


static func slots(def: UnitDef) -> int:
	return 2 if improved(def) else 1


static func tons(def: UnitDef, per_jet: float) -> float:
	return def.jump_mp * per_jet * (2.0 if improved(def) else 1.0)


static func heat(hexes: int, is_improved: bool) -> int:
	return maxi(3, ceili(hexes / 2.0) if is_improved else hexes)
