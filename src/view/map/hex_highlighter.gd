class_name HexHighlighter
extends MultiMeshInstance3D
## Tactical overlays: soft transparent area fills plus thin bright outlines
## leave hex terrain, elevation and voxel models legible when planning moves.

const REACH_WALK := Color(0.25, 0.75, 1.0, 0.25)
const PATH := Color(0.65, 0.88, 1.0, 0.36)
const DESTINATION := Color(0.99, 0.92, 0.36, 0.60)
const THREAT := Color(0.96, 0.30, 0.28, 0.48)
const SELECTED := Color(1.0, 0.85, 0.2, 0.5)

var map: BattleMap
var _borders: MultiMeshInstance3D


func setup(battle_map: BattleMap) -> void:
	map = battle_map
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = HexMesh.cap(HexLayout.HEX_SIZE * 0.88)
	multimesh = mm
	material_override = _overlay_material()
	_borders = MultiMeshInstance3D.new()
	_borders.name = "TacticalOutlines"
	_borders.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring_mm := MultiMesh.new()
	ring_mm.transform_format = MultiMesh.TRANSFORM_3D
	ring_mm.use_colors = true
	ring_mm.mesh = HexMesh.ring(HexLayout.HEX_SIZE * 0.92, 0.055)
	_borders.multimesh = ring_mm
	_borders.material_override = _overlay_material()
	add_child(_borders)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _overlay_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = false
	return mat


## hexes: Dictionary of Vector2i -> Color.
func show_hexes(hexes: Dictionary) -> void:
	multimesh.instance_count = hexes.size()
	_borders.multimesh.instance_count = hexes.size()
	var i := 0
	for c: Vector2i in hexes:
		var t := map.get_tile(c)
		var p := HexLayout.tile_top(t) if t else HexLayout.to_world(c)
		var color: Color = hexes[c]
		multimesh.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, 0.034, 0)))
		multimesh.set_instance_color(i, color)
		var outline := color
		outline.a = minf(0.95, color.a * 1.9)
		_borders.multimesh.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, 0.045, 0)))
		_borders.multimesh.set_instance_color(i, outline)
		i += 1


func clear() -> void:
	multimesh.instance_count = 0
	if _borders != null:
		_borders.multimesh.instance_count = 0
