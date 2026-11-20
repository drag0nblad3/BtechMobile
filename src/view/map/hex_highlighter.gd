class_name HexHighlighter
extends MultiMeshInstance3D
## Draws translucent colored hexes over the map (reachable area, path, etc).

const REACH_WALK := Color(0.25, 0.75, 1.0, 0.35)
const PATH := Color(1.0, 1.0, 1.0, 0.55)
const SELECTED := Color(1.0, 0.85, 0.2, 0.6)

var map: BattleMap


func setup(battle_map: BattleMap) -> void:
	map = battle_map
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = HexMesh.cap(HexLayout.HEX_SIZE * 0.9)
	multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = false
	material_override = mat


## hexes: Dictionary of Vector2i -> Color.
func show_hexes(hexes: Dictionary) -> void:
	multimesh.instance_count = hexes.size()
	var i := 0
	for c: Vector2i in hexes:
		var t := map.get_tile(c)
		var lvl := t.level if t else 0
		var p := HexLayout.to_world(c, lvl) + Vector3(0, 0.03, 0)
		multimesh.set_instance_transform(i, Transform3D(Basis(), p))
		multimesh.set_instance_color(i, hexes[c])
		i += 1


func clear() -> void:
	multimesh.instance_count = 0
