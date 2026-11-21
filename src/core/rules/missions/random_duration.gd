class_name RandomDuration
extends RefCounted
## Random Duration (book p. 233). From turn 7 a die is rolled at the start
## of each turn: the mission ends after that turn on a 1 (turn 7), 1-2
## (turns 8-9), or 1-4 (turn 10 on).


static func ends_on(turn: int) -> int:
	if turn >= 10:
		return 4
	if turn >= 8:
		return 2
	if turn == 7:
		return 1
	return 0


## Rolls at the start of a turn; true if this turn is the last.
static func roll(state: GameState, dice: Dice, emit: Callable) -> bool:
	var need := ends_on(state.turn)
	if need == 0:
		return false
	var r := dice.d6()
	var last := r <= need
	emit.call(GameEvent.MISSION, {"kind": "duration", "roll": r, "ends_on": need, "last": last})
	return last
