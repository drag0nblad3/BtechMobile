class_name BotDriver
extends Node
## Lets the computer play its sides: when one of them is due to act and no
## animation is running, it takes one action after a short pause.

const PAUSE := 0.5

var controller: GameController
var units_layer: UnitsLayer
var bot_sides: Array = []
var lessons: LessonCard = null  ## Waits while a tutorial lesson is open.
var _wait := 0.0
var _checked := ""  ## Turn/phase whose hidden-unit reveals were already decided.


func is_bot_turn() -> bool:
	return bot_sides.has(controller.deciding_side()) and not controller.state.game_over


func _process(delta: float) -> void:
	var s := controller.state
	var when := "%d/%d" % [s.turn, s.phase]
	if not s.hidden.is_empty() and s.order_index == 0 and _checked != when and not units_layer.is_busy():
		_checked = when  # hidden units come out at the start of a phase
		for side: int in bot_sides:
			while BotHidden.reveal(controller, side):
				pass
	if not is_bot_turn() or units_layer.is_busy() or (lessons and lessons.is_open()):
		_wait = 0.0
		return
	_wait += delta
	if _wait >= PAUSE:
		_wait = 0.0
		Bot.act(controller, controller.deciding_side())
