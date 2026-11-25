class_name Commanders
extends RefCounted
## Force commanders (Campaign Operations p. 85): each side names a senior
## commander. Losing it (destroyed, MechWarrior killed, or gone from the
## field) costs that side -2 Initiative for the rest of the battle. Used in
## campaign battles (GameState.commander_rule). Tactical
## Genius works only for the commander (TacticalGenius).
## TODO(rules): the app picks the commander: a MechWarrior with Tactical
## Genius first, then the best Gunnery + Piloting, ties to the first listed;
## sub-commanders and Special Command Abilities aren't in.

const PENALTY := -2


## Names a commander for every side that has none (first Initiative roll).
static func ensure(state: GameState, emit: Callable) -> void:
	if not state.commander_rule:
		return
	for side: int in state.sides_alive():
		if state.commanders.has(side):
			continue
		var best: Unit = null
		for u in state.units_of_side(side):
			if u.destroyed or u.def.is_support():
				continue
			if best == null or _score(u) < _score(best):
				best = u
		if best != null:
			state.commanders[side] = best.id
			emit.call(GameEvent.COMMANDER, {"side": side, "unit_id": best.id, "lost": false})


## The side's commander unit, or null.
static func of(state: GameState, side: int) -> Unit:
	return state.unit_by_id(int(state.commanders[side])) if state.commanders.has(side) else null


static func lost(state: GameState, side: int) -> bool:
	var u := of(state, side)
	return u != null and (u.destroyed or u.pilot.is_dead() or state.mission.exited.has(u.id))


## Announces newly lost commanders once.
static func check(state: GameState, emit: Callable) -> void:
	for side: int in state.commanders:
		if lost(state, side) and not state.commanders_lost.has(side):
			state.commanders_lost[side] = true
			emit.call(GameEvent.COMMANDER, {"side": side, "unit_id": state.commanders[side], "lost": true})


## Initiative modifier for the side.
static func initiative(state: GameState, side: int) -> int:
	return PENALTY if state.commanders_lost.has(side) else 0


static func _score(u: Unit) -> int:
	var genius := -100 if Spa.has(u, Spa.TACTICAL_GENIUS) else 0
	return genius + u.pilot.gunnery + u.pilot.piloting
