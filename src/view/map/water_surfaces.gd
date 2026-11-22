class_name WaterSurfaces
extends RefCounted
## Animated low-cost wave highlights and pale edges give water tiles depth
## and clearer shorelines. One MultiMesh and one shared shader material.

const WATER_SHADER := preload("res://src/view/shaders/water.gdshader")


static func build(map: BattleMap) -> MultiMeshInstance3D:
	var tiles: Array[MapTile] = []
	for t: MapTile in map.tiles.values():
		if t.is_water():
			tiles.append(t)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = HexMesh.cap(HexLayout.HEX_SIZE * 0.98)
	mm.instance_count = tiles.size()
	for i in tiles.size():
		var t: MapTile = tiles[i]
		var p := HexLayout.to_world(t.coord, t.level)
		mm.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, -0.035, 0)))
		var deep := clampf(float(t.depth - 1) / 3.0, 0.0, 1.0)
		var brightness := lerpf(1.0, 0.65, deep)
		mm.set_instance_color(i, Color(brightness, brightness, brightness, 1.0))
		mm.set_instance_custom_data(i, Color(float(TerrainEdges.shore_mask(map, t)) / 63.0, 0, 0, 0))
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	var inst := MultiMeshInstance3D.new()
	inst.name = "Water"
	inst.multimesh = mm
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst
