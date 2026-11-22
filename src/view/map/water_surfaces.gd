class_name WaterSurfaces
extends RefCounted
## One animated water MultiMesh; shoreline foam is generated only along
## water-to-land edges, never between adjacent water hexes.

const WATER_SHADER := preload("res://src/view/shaders/water.gdshader")


static func build(map: BattleMap) -> MultiMeshInstance3D:
	var tiles: Array[MapTile] = []
	for t: MapTile in map.tiles.values():
		if t.is_water():
			tiles.append(t)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = HexMesh.cap(HexLayout.HEX_SIZE * 0.98)
	mm.instance_count = tiles.size()
	for i in tiles.size():
		var t: MapTile = tiles[i]
		var p := HexLayout.to_world(t.coord, t.level)
		mm.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, -0.035, 0)))
		var deep := clampf(float(t.depth - 1) / 3.0, 0.0, 1.0)
		var brightness := lerpf(1.0, 0.65, deep)
		mm.set_instance_color(i, Color(brightness, brightness, brightness, 1.0))
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	var inst := MultiMeshInstance3D.new()
	inst.name = "Water"
	inst.multimesh = mm
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shoreline := _shoreline(map)
	if shoreline != null:
		inst.add_child(shoreline)
	return inst


static func _shoreline(map: BattleMap) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := HexMesh.corners(HexLayout.HEX_SIZE * 0.97)
	var count := 0
	for t: MapTile in map.tiles.values():
		if not t.is_water():
			continue
		for side in 6:
			var neighbor: MapTile = map.get_tile(Hex.neighbor(t.coord, side))
			if neighbor != null and neighbor.is_water():
				continue
			var a := corners[side]
			var b := corners[(side + 1) % 6]
			var toward_center := 0.09
			var c := a * (1.0 - toward_center)
			var d := b * (1.0 - toward_center)
			var origin := HexLayout.to_world(t.coord, t.level) + Vector3(0, -0.02, 0)
			for point in [a, d, b, a, c, d]:
				st.set_normal(Vector3.UP)
				st.add_vertex(origin + point)
			count += 1
	if count == 0:
		return null
	var mesh := st.commit()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.56, 0.78, 0.76, 0.30)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var node := MeshInstance3D.new()
	node.name = "RealShoreline"
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
