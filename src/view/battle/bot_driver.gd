class_name BotDriver
extends Node
## Lets the computer play its sides: when one of them is due to act and no
## animation is running, it takes one action after a short pause.

const PAUSE := 0.5

var controller: GameController
var units_layer: UnitsLayer
var bot_sides: Array = []
var skill: int = BotSkill.Level.VETERAN  ## BotSkill.Level the computer plays at.
var lessons: LessonCard = null  ## Waits while a tutorial lesson is open.
var _wait := 0.0


func is_bot_turn() -> bool:
	return bot_sides.has(controller.state.active_side()) and not controller.state.game_over


func _process(delta: float) -> void:
	if not is_bot_turn() or units_layer.is_busy() or (lessons and lessons.is_open()):
		_wait = 0.0
		return
	_wait += delta
	if _wait >= PAUSE:
		_wait = 0.0
		Bot.act(controller, controller.state.active_side(), skill)
