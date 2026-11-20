class_name InitiativeDie
extends RefCounted
## Initiative Die (optional rule, book p. 39). The side that loses initiative
## takes a die worth +1 on its next initiative roll (tiebreakers too); each
## further loss raises it by 1, up to +6. Winning initiative removes it. With
## more than two sides, the side that lost by the most gains or raises its die.

const MAX_BONUS := 6


## Bonus per side for this turn's roll ({} when the rule is off).
static func bonuses(state: GameState) -> Dictionary:
	return state.initiative_die.duplicate() if state.initiative_die_rule else {}


## After a roll: the winner drops its die, the worst loser gains or raises one.
static func update(state: GameState, order: Array) -> void:
	if not state.initiative_die_rule or order.size() < 2:
		return
	state.initiative_die.erase(order[-1])
	var loser: int = order[0]
	state.initiative_die[loser] = mini(MAX_BONUS, int(state.initiative_die.get(loser, 0)) + 1)
