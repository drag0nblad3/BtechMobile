class_name BattleLaunch
extends RefCounted
## Hands a prepared GameState from the force builder to the battle scene.
## Empty means the battle scene loads its default scenario.

const MENU_SCENE := "res://scenes/menu.tscn"
const BATTLE_SCENE := "res://scenes/main.tscn"

static var pending: GameState = null


static func take() -> GameState:
	var s := pending
	pending = null
	return s
