class_name WaterSurfaces
extends RefCounted
## Translucent water caps at the surface level of every water hex.


static func build(map: BattleMap) -> MultiMeshInstance3D:
	var tiles: Array[MapTile] = []
	for t: MapTile in map.tiles.values():
		if t.is_water():
			tiles.append(t)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = HexMesh.cap(HexLayout.HEX_SIZE)
	mm.instance_count = tiles.size()
	for i in tiles.size():
		var p := HexLayout.to_world(tiles[i].coord, tiles[i].level)
		mm.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, -0.04, 0)))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.42, 0.62, 0.62)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.08
	mat.metallic_specular = 0.9
	var inst := MultiMeshInstance3D.new()
	inst.name = "Water"
	inst.multimesh = mm
	inst.material_override = mat
	return inst
