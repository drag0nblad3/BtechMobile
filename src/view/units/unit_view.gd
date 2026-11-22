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
		refresh_look()
	snap_to_state()


## Choose the strongest supported representation without touching the Unit.
func refresh_look() -> void:
	if unit.def.is_support():
		return
	var voxel := UnitVoxels.choose(unit.def, unit.side)
	var sprite := SpriteMech.try_build(unit.def) if voxel == null else null
	set_model(voxel if voxel else sprite if sprite else PlaceholderMech.build(unit.def, unit.side))


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
	if UnitVoxels.sync(_model, unit):
		return
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
func play_path(path: Array, start_coord: Vector2i, start_facing: int,
		mode: int = -1) -> void:
	if path.is_empty():
		animation_finished.emit.call_deferred()
		return
	if mode == MoveMode.Kind.JUMP and unit.def.jump_mp > 0 and not unit.def.is_support():
		_jump_path(path, start_coord, start_facing)
		return
	if _model is VxMech:
		(_model as VxMech).anim.walk(true, mode == MoveMode.Kind.RUN)
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
			if _model is VxMech:
				(_model as VxMech).anim.walk(false)
			show_condition()
			animation_finished.emit())


## Jump moves are one continuous three-dimensional arc rather than walking
## one tile at a time. This path is presentation only; the resolved position
## and heat remain entirely in the movement rules.
func _jump_path(path: Array, start_coord: Vector2i, start_facing: int) -> void:
	var last: Vector3i = path[-1]
	var destination := Vector2i(last.x, last.y)
	var start := position  # exact visual start, even from a rooftop or bridge
	var finish := _hex_pos(destination)
	var distance := Hex.distance(start_coord, destination)
	if distance <= 0:
		_yaw = HexLayout.facing_yaw(last.z)
		var turn := create_tween()
		turn.tween_property(self, "rotation:y", _yaw, TURN_TIME)
		turn.finished.connect(func(): animation_finished.emit())
		return
	var duration := clampf(0.35 + float(distance) * 0.105, 0.50, 1.35)
	var apex := clampf(0.75 + float(distance) * 0.22, 0.95, 2.25)
	var from_yaw := rotation.y
	var final_yaw := HexLayout.facing_yaw(last.z)
	var plume := JumpJetFx.spawn(self)
	if _model is VxMech:
		# World trajectory belongs to UnitView; local anim only tucks limbs and
		# lights jets (height zero avoids a second jump arc).
		(_model as VxMech).anim.jump(Vector3.ZERO, 0.0)
	_ground_burst(start_coord, true, start)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		position = JumpJetFx.arc(start, finish, t, apex)
		rotation.y = lerp_angle(from_yaw, final_yaw, t)
		JumpJetFx.animate(plume, t), 0.0, 1.0, duration)
	tween.finished.connect(func() -> void:
		position = finish
		_yaw = final_yaw
		rotation.y = final_yaw
		if is_instance_valid(plume):
			plume.queue_free()
		_ground_burst(destination, false)
		show_condition()
		animation_finished.emit())


func _ground_burst(coord: Vector2i, launching: bool, at: Vector3 = Vector3.INF) -> void:
	var tile: MapTile = map.get_tile(coord)
	if tile == null:
		return
	var pos := (at if at != Vector3.INF else _hex_pos(coord)) + Vector3(0, 0.06, 0)
	var kind := "jet_splash" if tile.is_water() else ("jet_launch" if launching else "jet_land")
	VxBlast.spawn(self, pos, kind, unit.id * 283 + (1 if launching else 2))


## Resolve authored weapon sockets first; fall back to the actual model bounds.
## This avoids center-to-center fire and follows a turning chassis.
func weapon_origin(weapon_name: String, weapon_index: int = -1) -> Vector3:
	if _model is VxMech and unit != null and weapon_index >= 0 and weapon_index < unit.def.weapon_mounts.size():
		var vox := _model as VxMech
		var loc := int(unit.def.weapon_mounts[weapon_index]["loc"])
		if not vox.model.parts_at(loc).is_empty() and vox.is_attached(vox.part_at(loc)):
			var ports := vox.muzzles(loc)
			if not ports.is_empty():
				return ports[0]
	var socket_names := ["muzzle_%d" % weapon_index, "weapon_%d" % weapon_index,
		"muzzle", "Muzzle", "WeaponMuzzle"]
	for candidate in socket_names:
		var marker := _find_socket(_model, candidate)
		if marker != null:
			return marker.global_position
	var bounds := _model_bounds(_model, Transform3D.IDENTITY)
	var location := -1
	var rear := false
	if unit != null and weapon_index >= 0 and weapon_index < unit.def.weapon_mounts.size():
		var mount: Dictionary = unit.def.weapon_mounts[weapon_index]
		location = int(mount.get("loc", -1))
		rear = bool(mount.get("rear", false))
	return global_transform * fallback_muzzle(bounds, location, rear,
		unit.def.quad if unit != null else false)


## When no per-chassis socket exists, use record-sheet location and actual
## rendered model bounds rather than alternating left/right by weapon index.
static func fallback_muzzle(bounds: AABB, location: int, rear: bool,
		quad: bool = false) -> Vector3:
	var side := 0.5
	var height := 0.70
	match location:
		Location.LA:
			side = 0.10
			height = 0.26 if quad else 0.57
		Location.RA:
			side = 0.90
			height = 0.26 if quad else 0.57
		Location.LT:
			side = 0.28
			height = 0.78
		Location.RT:
			side = 0.72
			height = 0.78
		Location.HEAD:
			height = 0.91
		Location.LL:
			side = 0.31
			height = 0.23
		Location.RL:
			side = 0.69
			height = 0.23
	return bounds.position + bounds.size * Vector3(side, height, 0.94 if rear else 0.04)


func impact_point(from: Vector3) -> Vector3:
	var bounds := _model_bounds(_model, Transform3D.IDENTITY)
	var center := bounds.get_center()
	var direction := (to_local(from) - center).normalized()
	var extent := bounds.size * 0.45
	return global_transform * (center + Vector3(direction.x * extent.x,
		direction.y * extent.y, direction.z * extent.z))


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
