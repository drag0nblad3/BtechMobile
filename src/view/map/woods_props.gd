class_name WoodsProps
extends RefCounted
## Low-poly conifers on woods hexes (more trees in heavy woods).
## Placement is seeded by hex coordinate so it never shuffles.

const TREES := {"light_woods": 3, "heavy_woods": 6}


static func build(map: BattleMap) -> MultiMeshInstance3D:
	var xforms: Array[Transform3D] = []
	for t: MapTile in map.tiles.values():
		var count: int = TREES.get(t.terrain.id, 0)
		if count == 0:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(t.coord)
		var top := HexLayout.tile_top(t)
		for i in count:
			var a := rng.randf() * TAU
			var r := sqrt(rng.randf()) * 0.62
			var s := rng.randf_range(0.75, 1.2)
			var pos := top + Vector3(cos(a) * r, 0.0, sin(a) * r)
			xforms.append(Transform3D(Basis.from_scale(Vector3(s, s, s)), pos))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _tree_mesh()
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = "Woods"
	inst.multimesh = mm
	return inst


static func _tree_mesh() -> Mesh:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.22
	cone.height = 0.75
	cone.radial_segments = 7
	cone.rings = 1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.33, 0.14)
	mat.roughness = 1.0
	cone.material = mat
	# Lift so the cone's base sits on the ground.
	var st := SurfaceTool.new()
	st.append_from(cone, 0, Transform3D(Basis(), Vector3(0, 0.375, 0)))
	var out := st.commit()
	out.surface_set_material(0, mat)
	return out
