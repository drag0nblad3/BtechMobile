class_name UnitView
extends Node3D
## 3D representation of one Unit. Snaps to state, or animates along a
## movement path step by step (turns, then walks hex to hex).

signal animation_finished

const STEP_TIME := 0.32
const TURN_TIME := 0.18

var unit: Unit
var map: BattleMap
var _yaw := 0.0  # Continuous yaw so turns never spin the long way round.
var _model: Node3D


func setup(u: Unit, battle_map: BattleMap) -> void:
	unit = u
	map = battle_map
	name = "Unit_%d" % u.id
	set_model(PlaceholderMech.build(u.def, u.side))
	snap_to_state()


func set_model(model: Node3D) -> void:
	if _model:
		_model.queue_free()
	_model = model
	add_child(model)


func snap_to_state() -> void:
	position = _hex_pos(unit.coord)
	_yaw = HexLayout.facing_yaw(unit.facing)
	rotation.y = _yaw


## Each step is a Vector3i(q, r, facing) from MoveOptions.path_to().
func play_path(path: Array, start_coord: Vector2i, start_facing: int) -> void:
	if path.is_empty():
		animation_finished.emit.call_deferred()
		return
	var tw := create_tween()
	var last_c := start_coord
	var last_f := start_facing
	for k: Vector3i in path:
		var c := Vector2i(k.x, k.y)
		if k.z != last_f:
			_yaw += _turn_delta(last_f, k.z)
			tw.tween_property(self, "rotation:y", _yaw, TURN_TIME)
			last_f = k.z
		if c != last_c:
			tw.tween_property(self, "position", _hex_pos(c), STEP_TIME) \
					.set_trans(Tween.TRANS_SINE)
			last_c = c
	tw.finished.connect(func(): animation_finished.emit())


func _turn_delta(from_f: int, to_f: int) -> float:
	var d := posmod(to_f - from_f, 6)
	if d > 3:
		d -= 6
	return -d * PI / 3.0


func _hex_pos(c: Vector2i) -> Vector3:
	return HexLayout.tile_top(map.get_tile(c))
