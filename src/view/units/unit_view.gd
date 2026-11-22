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
	elif u.def.vehicle != null:
		set_model(PlaceholderAsset.build_vehicle(u.def, u.side))
	elif u.def.battle_armor != null:
		set_model(PlaceholderAsset.build_squad(u.def, u.side))
	else:
		var sprite := SpriteMech.try_build(u.def)
		set_model(sprite if sprite else PlaceholderMech.build(u.def, u.side))
	snap_to_state()


func set_model(model: Node3D) -> void:
	if _model:
		_model.queue_free()
	_model = model
	add_child(model)
	if unit != null and model.name == "Placeholder":
		WeaponSockets.attach(model, unit.def)


func snap_to_state() -> void:
	position = _hex_pos(unit.coord)
	_yaw = HexLayout.facing_yaw(unit.facing)
	rotation.y = _yaw
	show_condition()


## Prone 'Mechs lie on their side; wrecks also darken.
func show_condition() -> void:
	if _model == null:
		return
	visible = unit.carrier_id() < 0  # riders ride inside or on top
	var down := unit.prone or (unit.destroyed and not unit.def.is_support())
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
	var foot_side := 0
	for k: Vector3i in path:
		var c := Vector2i(k.x, k.y)
		if k.z != last_f:
			_yaw += _turn_delta(last_f, k.z)
			tw.tween_property(self, "rotation:y", _yaw, TURN_TIME)
			last_f = k.z
		if c != last_c:
			tw.tween_property(self, "position", _hex_pos(c), STEP_TIME) \
					.set_trans(Tween.TRANS_SINE)
			var foot_at := c
			var side := foot_side
			tw.tween_callback(func(): _footfall(foot_at, side))
			foot_side += 1
			last_c = c
	tw.finished.connect(func():
			show_condition()
			animation_finished.emit())


## Resolve authored weapon sockets first; fall back to the actual model bounds.
## This avoids center-to-center fire and follows a turning chassis.
func weapon_origin(weapon_name: String, weapon_index: int = -1) -> Vector3:
	var socket_names := ["muzzle_%d" % weapon_index, "weapon_%d" % weapon_index,
		"muzzle", "Muzzle", "WeaponMuzzle"]
	for candidate in socket_names:
		var marker := _find_socket(_model, candidate)
		if marker != null:
			return marker.global_position
	var bounds := _model_bounds(_model, Transform3D.IDENTITY)
	var size: Vector3 = bounds.size
	var side := -1.0 if weapon_index >= 0 and weapon_index % 2 == 0 else 1.0
	var height := bounds.position.y + size.y * 0.67
	var local := Vector3(side * size.x * 0.32, height, bounds.position.z - size.z * 0.43)
	return global_transform * (_model.transform * local)


func impact_point(from: Vector3) -> Vector3:
	var bounds := _model_bounds(_model, Transform3D.IDENTITY)
	var center := bounds.get_center()
	var direction := (to_local(from) - center).normalized()
	var extent := bounds.size * 0.45
	return global_transform * (_model.transform * (center + Vector3(direction.x * extent.x,
		direction.y * extent.y, direction.z * extent.z)))


func _find_socket(root: Node, wanted: String) -> Node3D:
	if root == null:
		return null
	if root is Node3D and root.name.to_lower() == wanted.to_lower():
		return root as Node3D
	for child in root.get_children():
		var found := _find_socket(child, wanted)
		if found != null:
			return found
	return null


func _model_bounds(root: Node3D, transform_: Transform3D) -> AABB:
	var box := AABB(Vector3(-0.45, 0.15, -0.45), Vector3(0.9, 1.1, 0.9))
	if root == null:
		return box
	var found := false
	var stack: Array = [{"node": root, "transform": transform_}]
	while not stack.is_empty():
		var entry: Dictionary = stack.pop_back()
		var node: Node3D = entry["node"]
		var tr: Transform3D = entry["transform"] * node.transform
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var b: AABB = (node as MeshInstance3D).get_aabb()
			var transformed := tr * b
			box = box.merge(transformed) if found else transformed
			found = true
		for child in node.get_children():
			if child is Node3D:
				stack.append({"node": child, "transform": tr})
	return box


## A small puff at the end of each actual translation, not a timer-driven
## fake gait. Water splashes and ground dust use different profiles.
func _footfall(coord: Vector2i, side: int) -> void:
	if not visible or unit.def.is_support():
		return
	var tile: MapTile = map.get_tile(coord)
	if tile == null:
		return
	var offset := global_transform.basis.x * (0.22 if side % 2 == 0 else -0.22)
	var point := _hex_pos(coord) + offset + Vector3(0, 0.04, 0)
	var kind := "splash" if tile.is_water() else "step"
	VxBlast.spawn(self, point, kind, unit.id * 103 + side)


func _turn_delta(from_f: int, to_f: int) -> float:
	var d := posmod(to_f - from_f, 6)
	if d > 3:
		d -= 6
	return -d * PI / 3.0


func _hex_pos(c: Vector2i) -> Vector3:
	var t := map.get_tile(c)
	if t == null:  # off the field (waiting to combat drop)
		return Vector3(0, -100, 0)
	var p := HexLayout.tile_top(t)
	if VtolFlight.is_vtol(unit):  # flies over the hex's woods or buildings
		p.y = HexLayout.level_y(VtolFlight.min_level(t) - 1)
	elif unit.on_bridge and t.bridge != null:
		p.y = HexLayout.level_y(t.bridge.level) + VxBuildingGen.PITCH  # on the deck slab
	elif unit.on_roof and Roofs.has_roof(t):
		p.y += t.building.height * HexLayout.LEVEL_HEIGHT
	return p
