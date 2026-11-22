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
var _recoil_tween: Tween

## Local geometry-based approximation used when a model does not provide its
## own mount markers. Left/right follows BattleTech hit locations, not camera.
static func anchor_offset(loc: int, rear: bool = false, tons: int = 50) -> Vector3:
	var scale_ := 1.25 + float(tons) / 250.0
	var at := Vector3(0.0, 0.83, -0.26)
	match loc:
		Location.HEAD: at = Vector3(0.0, 1.05, -0.23)
		Location.CT: at = Vector3(0.0, 0.78, -0.30)
		Location.LT: at = Vector3(-0.30, 0.85, -0.28)
		Location.RT: at = Vector3(0.30, 0.85, -0.28)
		Location.LA: at = Vector3(-0.41, 0.56, -0.38)
		Location.RA: at = Vector3(0.41, 0.56, -0.38)
		Location.LL: at = Vector3(-0.17, 0.33, -0.20)
		Location.RL: at = Vector3(0.17, 0.33, -0.20)
	if rear:
		at.z = absf(at.z)
	return at * scale_


## On real 3-D models a named Muzzle_<location> marker is authoritative;
## fallback anchors preserve meaningful weapon location for sprites and props.
func mount_world(w: MountedWeapon) -> Vector3:
	if _model == null or w == null:
		return global_position + Vector3.UP * 0.6
	var code := Location.code(w.loc) if not w.on_vehicle else "CT"
	var marker := _model.get_node_or_null("Muzzle_" + code) as Marker3D
	if marker != null and not w.rear:
		return marker.global_position
	return _model.to_global(anchor_offset(w.loc if not w.on_vehicle else Location.CT,
			w.rear, unit.def.tonnage))


func impact_world(loc: int, rear := false) -> Vector3:
	if _model == null:
		return global_position + Vector3.UP * 0.7
	var point := anchor_offset(loc, rear, unit.def.tonnage)
	point.z *= 0.76  # armor face is behind a muzzle tip
	return _model.to_global(point)


## Small, non-stacking physical feedback only; rules and gait are unchanged.
func recoil(strength: float = 1.0) -> void:
	if _model == null or unit.def.is_support():
		return
	if _recoil_tween != null and _recoil_tween.is_running():
		_recoil_tween.kill()
	_model.position.z = 0.0
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(_model, "position:z", 0.065 * strength, 0.065)
	_recoil_tween.tween_property(_model, "position:z", 0.0, 0.16)



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
func play_path(path: Array, start_coord: Vector2i, start_facing: int,
		mode: int = MoveMode.Kind.WALK) -> void:
	if path.is_empty():
		animation_finished.emit.call_deferred()
		return
	var tw := create_tween()
	var last_c := start_coord
	var last_f := start_facing
	var jumped := mode == MoveMode.Kind.JUMP
	if jumped:
		_surface_effect(start_coord, "jet")
	for k: Vector3i in path:
		var c := Vector2i(k.x, k.y)
		if k.z != last_f:
			_yaw += _turn_delta(last_f, k.z)
			tw.tween_property(self, "rotation:y", _yaw, TURN_TIME)
			last_f = k.z
		if c != last_c:
			if jumped:
				var from_pos := _hex_pos(last_c)
				var to_pos := _hex_pos(c)
				tw.tween_method(Callable(self, "_jump_fraction").bind(from_pos, to_pos),
					0.0, 1.0, STEP_TIME).set_trans(Tween.TRANS_SINE)
			else:
				tw.tween_property(self, "position", _hex_pos(c), STEP_TIME) \
						.set_trans(Tween.TRANS_SINE)
			var contact := c
			tw.tween_callback(func() -> void: _surface_effect(contact,
					"landing" if jumped else "step"))
			last_c = c
	tw.finished.connect(func():
			show_condition()
			animation_finished.emit())


func _jump_fraction(progress: float, from_pos: Vector3, to_pos: Vector3) -> void:
	position = from_pos.lerp(to_pos, progress) + Vector3.UP * sin(progress * PI) * 0.85


## Footstep cues occur at actual movement tween contacts, not on a timer.
static func surface_kind(tile: MapTile, action: String) -> String:
	if tile == null:
		return ""
	if action == "jet":
		return "jumpjet"
	if tile.is_water():
		return "splash"
	if tile.surface == "snow":
		return "snow_dust"
	if action == "landing":
		return "landing"
	if tile.terrain.id in ["pavement", "rough", "rubble"]:
		return "hard_step"
	return "soft_step"


func _surface_effect(coord: Vector2i, action: String) -> void:
	if unit.def.is_support():
		return
	var tile := map.get_tile(coord)
	if tile == null or not is_inside_tree():
		return
	var kind := surface_kind(tile, action)
	if kind == "" or get_tree().get_nodes_in_group("surface_fx").size() >= 32:
		return
	var at := _hex_pos(coord)
	if tile.is_water():
		at.y = HexLayout.level_y(tile.level)
	var fx := VxBlast.spawn(get_parent(), at + Vector3.UP * 0.08, kind,
		unit.id * 193 + coord.x * 37 + coord.y * 71 + action.length())
	fx.add_to_group("surface_fx")
	fx.scale = Vector3.ONE * clampf(0.7 + float(unit.def.tonnage) / 190.0, 0.78, 1.28)


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
