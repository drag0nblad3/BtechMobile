class_name TacticalGenius
extends RefCounted
## Tactical Genius SPA (Campaign Operations p. 80): the force commander may
## reroll the side's Initiative, and the second roll stands. Here a side
## that lost Initiative rerolls once if any of its MechWarriors still on the
## field has it; a reroll that ties is rolled again.
## TODO(rules): there is no force commander yet, so any MechWarrior with the
## ability counts, and the reroll is taken whenever the side lost.


## Changes `r` from Initiative.roll in place; lists the sides that rerolled.
static func apply(state: GameState, dice: Dice, r: Dictionary) -> void:
	var rolls: Dictionary = r["rolls"]
	var order: Array = r["order"]
	if order.size() < 2:
		return
	var bonus: Dictionary = r.get("bonus", {})
	var rerolled: Array[int] = []
	for s: int in order.slice(0, order.size() - 1):
		if not _has_genius(state, s):
			continue
		var again := dice.roll_2d6() + int(bonus.get(s, 0))
		while _taken(rolls, s, again):
			again = dice.roll_2d6() + int(bonus.get(s, 0))
		rolls[s] = again
		rerolled.append(s)
	if rerolled.is_empty():
		return
	order.sort_custom(func(a, b): return rolls[a] < rolls[b])
	r["genius"] = rerolled


static func _has_genius(state: GameState, side: int) -> bool:
	for u in state.units_of_side(side):
		if not u.destroyed and Spa.has(u, Spa.TACTICAL_GENIUS):
			return true
	return false


static func _taken(rolls: Dictionary, side: int, total: int) -> bool:
	for s in rolls:
		if s != side and int(rolls[s]) == total:
			return true
	return false
