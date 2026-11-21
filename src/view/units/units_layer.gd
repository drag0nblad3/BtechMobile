class_name UnitsLayer
extends Node3D
## Owns all UnitViews and plays GameEvents that affect units.

signal busy_changed(busy: bool)

var views: Dictionary = {}  # unit id -> UnitView
var _playing := 0


## Hidden units only show for sides in `see_hidden` (the human players).
func build(state: GameState, see_hidden: Array = [0, 1]) -> void:
	for u in state.all_units():
		var v := UnitView.new()
		add_child(v)
		v.setup(u, state.map)
		v.visible = not state.hidden.has(u) or see_hidden.has(u.side)
		views[u.id] = v


func view_of(u: Unit) -> UnitView:
	return views.get(u.id)


func is_busy() -> bool:
	return _playing > 0


## path/start come from the controller's UNIT_MOVED event.
func play_move(unit_id: int, path: Array, from_coord: Vector2i, from_facing: int) -> void:
	var v: UnitView = views[unit_id]
	_playing += 1
	busy_changed.emit(true)
	v.animation_finished.connect(_on_done, CONNECT_ONE_SHOT)
	v.play_path(path, from_coord, from_facing)


## Re-reads a unit's condition (prone, destroyed, facing after a fall).
func refresh_unit(unit_id: int) -> void:
	var v: UnitView = views.get(unit_id)
	if v and not is_busy():
		v.snap_to_state()


func _on_done() -> void:
	_playing -= 1
	if _playing == 0:
		busy_changed.emit(false)
