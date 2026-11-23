class_name BattleAimOverlay
extends Node3D
## Phone-legible LOS beam, authoritative cover cells, and faded firing arcs.
## Visibility is always on while aiming, including Explain: Off.

const ARC_RADIUS := 5
const ARC_COLORS := [
	Color(0.15, 0.78, 0.45, 0.12),
	Color(0.93, 0.72, 0.24, 0.095),
	Color(0.88, 0.25, 0.30, 0.09),
	Color(0.93, 0.72, 0.24, 0.095)]
var _state: GameState
var _arc: HexHighlighter
var _mods: HexHighlighter
var _line: MeshInstance3D


func setup(state: GameState) -> void:
	_state = state
	_arc = HexHighlighter.new()
	add_child(_arc)
	_arc.setup(state.map)
	_mods = HexHighlighter.new()
	add_child(_mods)
	_mods.setup(state.map)
	_line = MeshInstance3D.new()
	_line.name = "LineOfSightBeam"
	_line.mesh = CylinderMesh.new()
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)
	_line.visible = false


func show_arcs(unit: Unit, at: Vector2i, facing: int) -> void:
	if unit == null:
		clear()
		return
	var colored := {}
	for tile: MapTile in _state.map.tiles.values():
		var c: Vector2i = tile.coord
		if c == at or Hex.distance(at, c) > ARC_RADIUS:
			continue
		var arc_id := FiringArc.fire_arc(at, facing, c)
		colored[c] = ARC_COLORS[arc_id]
	_arc.show_hexes(colored)


func show_attack(ai: AttackInput) -> void:
	if ai.attacker == null:
		clear()
		return
	show_arcs(ai.attacker, ai.attacker.coord, ai.attacker.torso_facing())
	if not ai.is_weapon_phase():
		_mods.clear()
		_line.visible = false
		return
	var destination := ai.target.coord if ai.target else ai.target_hex
	if destination == Hex.INVALID:
		_mods.clear()
		_line.visible = false
		return
	var state := ai.controller.state
	var options := AttackView.options(ai)
	var los := {}
	if ai.target:
		los = LineOfSight.check(state.map, ai.attacker, ai.target)
	else:
		var tile: MapTile = state.map.get_tile(destination)
		if tile == null:
			clear()
			return
		var level := tile.level + (tile.building.height if tile.building != null else 1)
		los = LineOfSight.check_hex(state.map, ai.attacker, destination, level)
	var kind := AimGuideData.status(los, options)
	_mods.show_hexes(AimGuideData.modifier_hexes(
			state.map, ai.attacker.coord, destination, los, options))
	_draw_line(ai.attacker.coord, destination, AimGuideData.color_for(kind))


func _draw_line(start: Vector2i, finish: Vector2i, color: Color) -> void:
	var from_tile: MapTile = _state.map.get_tile(start)
	var to_tile: MapTile = _state.map.get_tile(finish)
	var a := HexLayout.tile_top(from_tile) + Vector3(0, 1.3, 0)
	var b := HexLayout.tile_top(to_tile) + Vector3(0, 1.3, 0)
	var direction := b - a
	var mesh := _line.mesh as CylinderMesh
	mesh.top_radius = 0.028
	mesh.bottom_radius = 0.028
	mesh.radial_segments = 6
	mesh.height = direction.length()
	_line.position = (a + b) * 0.5
	_line.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	_line.material_override = mat
	_line.visible = true


func clear() -> void:
	if _arc != null:
		_arc.clear()
	if _mods != null:
		_mods.clear()
	if _line != null:
		_line.visible = false
