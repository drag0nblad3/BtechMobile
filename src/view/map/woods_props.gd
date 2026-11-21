class_name WoodsProps
extends RefCounted
## Voxel trees (VxTrees) on woods hexes: light woods mostly broadleaf,
## heavy woods denser and mostly conifers. One MultiMesh per tree variant;
## placement is seeded by hex coordinate so it never shuffles.

const SHADER := preload("res://src/view/shaders/vx_foliage.gdshader")
const TREES := {"light_woods": 3, "heavy_woods": 6}
const CONIFER_SHARE := {"light_woods": 0.3, "heavy_woods": 0.65}

static var _material: ShaderMaterial


static func build(map: BattleMap) -> Node3D:
	var root := Node3D.new()
	root.name = "Woods"
	var by_mesh := {}  # [kind, variant] -> Array[Transform3D]
	for t: MapTile in map.tiles.values():
		var count: int = TREES.get(t.terrain.id, 0)
		if count == 0:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(t.coord)
		var top := HexLayout.tile_top(t)
		for i in count:
			var a := (i + rng.randf() * 0.8) * TAU / count
			var r := 0.18 + rng.randf() * 0.45 if count > 1 else 0.0
			var s := rng.randf_range(0.8, 1.2)
			var conifer: bool = rng.randf() < float(CONIFER_SHARE[t.terrain.id])
			var key := ["conifer", rng.randi() % VxTrees.CONIFERS] if conifer \
					else ["broadleaf", rng.randi() % VxTrees.BROADLEAF]
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
			by_mesh.get_or_add(key, []).append(Transform3D(basis, top + Vector3(cos(a) * r, 0.0, sin(a) * r)))
	for key: Array in by_mesh:
		root.add_child(_layer(VxTrees.mesh(key[0], key[1]), by_mesh[key]))
	return root


## Every voxel plant shares this swaying vertex-colour material.
static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
	return _material


static func _layer(mesh: Mesh, xforms: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = material()
	return inst
