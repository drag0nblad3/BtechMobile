class_name MoveUndo
extends RefCounted
## Training: take back your last move. Remembers a BattleSave capture made
## just before the move and offers it only while the same movement phase is
## running and no dice have been rolled since, so undoing can never reroll a
## piloting check or any other result. The computer's reply moves (dice-free)
## are taken back too.

var snapshot := {}
var _turn := -1


func remember(c: GameController, bots: Array, skill: int, training: int, frames: Array,
		tutorial_path: String = "") -> void:
	snapshot = BattleSave.capture(c, bots, skill, training, frames, tutorial_path)
	_turn = c.state.turn


func available(c: GameController) -> bool:
	return not snapshot.is_empty() and not c.state.game_over and c.state.turn == _turn \
			and c.state.phase == Phase.Kind.MOVEMENT and str(c.dice._rng.state) == String(snapshot["rng"])


func forget() -> void:
	snapshot = {}
	_turn = -1
