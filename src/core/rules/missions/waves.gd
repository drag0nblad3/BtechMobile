class_name Waves
extends RefCounted
## Waves complication (book p. 233): half of each force (rounded down) is
## held back (`state.waiting`). From the start of turn 2 each side rolls 1D6
## for its wave: it arrives on 3+, the next turn on 2+, and surely the turn
## after. Arriving 'Mechs come in along their home edge and move as normal
## that turn.
## TODO(rules): players choose which half waits; we hold back the last ones listed.

const FIRST_TURN := 2


## Holds back half of each side's 'Mechs.
static func hold_back(state: GameState) -> void:
	for side in state.sides():
		var mine := state.units_of_side(side)
		@warning_ignore("integer_division")
		var n := mine.size() / 2
		for i in n:
			var u: Unit = mine[mine.size() - 1 - i]
			state.units.erase(u)
			state.waiting.append(u)
			u.coord = Hex.INVALID


## Turn start: each side with a wave out rolls for it.
static func start_turn(state: GameState, dice: Dice, emit: Callable) -> void:
	if state.waiting.is_empty() or state.turn < FIRST_TURN:
		return
	var need := 3 if state.turn == FIRST_TURN else (2 if state.turn == FIRST_TURN + 1 else 0)
	for side in state.sides():
		var wave: Array[Unit] = []
		for u in state.waiting:
			if u.side == side:
				wave.append(u)
		if wave.is_empty():
			continue
		var r := dice.d6() if need > 0 else 0
		var arrives := need == 0 or r >= need
		emit.call(GameEvent.WAVE, {"side": side, "roll": r, "need": need, "arrived": arrives})
		if arrives:
			for u in wave:
				state.waiting.erase(u)
				state.units.append(u)
			var edge := state.mission.def.home_edge(side) if state.mission.def else ("south" if side == 0 else "north")
			Deployment.place(state, wave, [{"edge": edge.split("|")[0], "depth": 1}])
