class_name BattleLaunch
extends RefCounted
## Hands a prepared GameState from the force builder to the battle scene.
## Empty means the battle scene loads its default scenario.

const MENU_SCENE := "res://scenes/menu.tscn"
const BATTLE_SCENE := "res://scenes/main.tscn"

static var pending: GameState = null
## Sides the computer plays in the next battle.
static var bot_sides: Array = []
## Scenario file whose lessons to show in the next battle, "" for none.
static var tutorial_path := ""
## Training campaign mission index of the next battle, -1 for none.
static var training_mission := -1
## Open the training campaign screen when the menu loads (after a lesson).
static var open_training := false


static func take() -> GameState:
	var s := pending
	pending = null
	return s


static func take_bots() -> Array:
	var b := bot_sides.duplicate()
	bot_sides = []
	return b
