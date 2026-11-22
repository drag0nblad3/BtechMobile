class_name WaterSurfaces
extends RefCounted
## Animated reflective water, still batched as a single MultiMesh.

const SHADER := preload("res://src/view/shaders/water.gdshader")

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
	var inst := MultiMeshInstance3D.new()
	inst.name = "Water"
	inst.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst
