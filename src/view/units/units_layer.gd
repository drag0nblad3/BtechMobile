class_name UnitsLayer
extends Node3D
## Owns all UnitViews and plays GameEvents that affect units.

signal busy_changed(busy: bool)

var views: Dictionary = {}  # unit id -> UnitView
var _playing := 0


func build(state: GameState) -> void:
	for u in state.units:
		var v := UnitView.new()
		add_child(v)
		v.setup(u, state.map)
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


func _on_done() -> void:
	_playing -= 1
	if _playing == 0:
		busy_changed.emit(false)
