class_name VictoryPoints
extends RefCounted
## Victory Points (book pp. 227, 230). A destroyed (or, with Forced
## Withdrawal, crippled) enemy is worth its Battle Value / 100, rounded up,
## at least 1. A withdrawing 'Mech that escapes by its home edge also earns
## its own side half its value (rounded up); one that leaves by a mission's
## exit scores its full value for its side. Most VP at the end wins; ties go
## to Unit VP (when objectives scored), then to the side that spent less BV.


static func unit_value(u: Unit) -> int:
	var bv := BvSkill.adjusted(BattleValue.of(u.def), u.pilot.gunnery, u.pilot.piloting)
	return maxi(1, ceili(bv / 100.0))


## Unit VP earned by `side`, from enemy losses and its own escapes.
static func unit_vp(state: GameState, side: int) -> int:
	var ms := state.mission
	var n := 0
	for u in state.units:
		var gone: String = ms.exited.get(u.id, "")
		if u.side != side:
			if (u.destroyed and gone == "") or ms.crippled.has(u.id):
				n += unit_value(u)
		elif gone == "withdraw":
			n += ceili(unit_value(u) / 2.0)
		elif gone == "mission":
			n += unit_value(u)
	return n


## Final score for `side`.
static func total(state: GameState, side: int) -> int:
	var ms := state.mission
	var n := int(ms.vp.get(side, 0))
	if ms.def != null and ms.def.unit_vp:
		n += unit_vp(state, side)
	return n


static func force_bv(state: GameState, side: int) -> int:
	var n := 0
	for u in state.units_of_side(side):
		n += BvSkill.adjusted(BattleValue.of(u.def), u.pilot.gunnery, u.pilot.piloting)
	return n


## {winner: side or -1, scores: {side: vp}, why}
static func result(state: GameState) -> Dictionary:
	var scores := {}
	for side in state.sides():
		scores[side] = total(state, side)
	var ranked := state.sides()
	ranked.sort_custom(func(a: int, b: int) -> bool: return _beats(state, scores, a, b))
	var why := "most Victory Points"
	if ranked.size() >= 2 and scores[ranked[0]] == scores[ranked[1]]:
		var a := ranked[0]
		var b := ranked[1]
		var objective_vp := state.mission.def.scoring != "" and not state.mission.def.unit_vp
		if objective_vp and unit_vp(state, a) != unit_vp(state, b):
			why = "tied on Victory Points; more Unit VP"
		elif force_bv(state, a) != force_bv(state, b):
			why = "tied; the side that spent less Battle Value wins"
		else:
			return {"winner": -1, "scores": scores, "why": "a dead heat"}
	return {"winner": ranked[0] if not ranked.is_empty() else -1, "scores": scores, "why": why}


static func _beats(state: GameState, scores: Dictionary, a: int, b: int) -> bool:
	if scores[a] != scores[b]:
		return scores[a] > scores[b]
	var m := state.mission.def
	if m.scoring != "" and not m.unit_vp and unit_vp(state, a) != unit_vp(state, b):
		return unit_vp(state, a) > unit_vp(state, b)
	return force_bv(state, a) < force_bv(state, b)
