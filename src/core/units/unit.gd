class_name Unit
extends RefCounted
## A unit on the battlefield: its design plus everything that changes in play.

var id: int
var def: UnitDef
var side: int
var coord: Vector2i
var facing: int
var has_moved: bool = false
var move_mode: int = -1  ## MoveMode.Kind used this turn, -1 if not moved.
var hexes_moved: int = 0 ## For target movement modifiers later.


func _init(unit_id: int, unit_def: UnitDef, unit_side: int, at: Vector2i, face: int) -> void:
	id = unit_id
	def = unit_def
	side = unit_side
	coord = at
	facing = face


func reset_for_turn() -> void:
	has_moved = false
	move_mode = -1
	hexes_moved = 0
