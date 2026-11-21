class_name UnitView
extends Node3D
## 3D representation of one Unit. Snaps to state, or animates along a
## movement path step by step (turns, then walks hex to hex).

signal animation_finished

const STEP_TIME := 0.32
const TURN_TIME := 0.18
const GROUP := &"unit_views"  ## BuildingProps finds 'Mechs standing inside buildings.

var unit: Unit
var map: BattleMap
var _yaw := 0.0  # Continuous yaw so turns never spin the long way round.
var _model: Node3D


func setup(u: Unit, battle_map: BattleMap) -> void:
	unit = u
	map = battle_map
	name = "Unit_%d" % u.id
	add_to_group(GROUP)
	if u.def.asset != null:
		set_model(PlaceholderAsset.build(u.def, u.side))
	else:
		var sprite := SpriteMech.try_build(u.def)
		set_model(sprite if sprite else PlaceholderMech.build(u.def, u.side))
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
	show_condition()


## Prone 'Mechs lie on their side; wrecks also darken.
func show_condition() -> void:
	if _model == null:
		return
	visible = unit.asset == null or unit.asset.carried_by < 0  # riders ride inside
	var down := unit.prone or (unit.destroyed and unit.asset == null)
	_model.rotation.z = PI / 2.4 if down else 0.0
	_model.position.y = 0.25 if down else 0.0
	var tint := Color(0.3, 0.3, 0.3) if unit.destroyed else Color.WHITE
	_tint(_model, tint)


func _tint(n: Node, c: Color) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var m := mi.mesh.surface_get_material(0) if mi.mesh else null
		mi.material_override = _dark(m) if c != Color.WHITE and m is StandardMaterial3D else null
	elif n is Sprite3D:
		(n as Sprite3D).modulate = c
	for ch in n.get_children():
		_tint(ch, c)


func _dark(m: StandardMaterial3D) -> StandardMaterial3D:
	var d := m.duplicate() as StandardMaterial3D
	d.albedo_color = m.albedo_color.darkened(0.7)
	d.emission_enabled = false
	return d


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
	tw.finished.connect(func():
			show_condition()
			animation_finished.emit())


func _turn_delta(from_f: int, to_f: int) -> float:
	var d := posmod(to_f - from_f, 6)
	if d > 3:
		d -= 6
	return -d * PI / 3.0


func _hex_pos(c: Vector2i) -> Vector3:
	var t := map.get_tile(c)
	var p := HexLayout.tile_top(t)
	if unit.on_roof and Roofs.has_roof(t):
		p.y += t.building.height * HexLayout.LEVEL_HEIGHT
	return p
