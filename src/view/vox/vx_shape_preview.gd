class_name VxShapePreview
extends Node3D
## Unsubdivided, polygon-surface proxy of the manually authored loft profiles.
## This is a shape approval tool only, not the game voxel renderer.
## The contours are EXACTLY those in data/voxels/*_shape.json.
## Erases are intentionally not shown: compare voxel renders for cutouts.

static func from_file(path: String) -> VxShapePreview:
	var d: Variant = JsonFile.read(path)
	var preview := VxShapePreview.new()
	preview._build(d if d is Dictionary else {})
	return preview


func _build(d: Dictionary) -> void:
	var unit_scale: float = float(d.get("voxel_size", 0.05))
	var shapes_by_name := {}
	var materials := {}
	for item: Dictionary in d.get("materials", []):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(item["color"])
		material.roughness = 0.88
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		materials[item["name"]] = material
	for p: Dictionary in d.get("parts", []):
		var shapes: Array = p.get("shapes", [])
		var mirror_part: bool = p.has("mirror")
		if mirror_part:
			shapes = shapes_by_name.get(p["mirror"], [])
		shapes_by_name[p["name"]] = shapes
		for s: Dictionary in shapes:
			_draw_shape(s, mirror_part, unit_scale, materials, p["name"])
		for s: Dictionary in p.get("add", []):
			_draw_shape(s, mirror_part, unit_scale, materials, p["name"])


func _draw_shape(s: Dictionary, mirrored: bool, unit_scale: float,
		materials: Dictionary, part_name: String) -> void:
	if s.has("loft"):
		var spec: Dictionary = s["loft"]
		var sections: Array = spec.get("sections", [])
		var axis: String = spec.get("axis", "y")
		if sections.size() < 2:
			return
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in range(sections.size() - 1):
			var one: Dictionary = sections[j]
			var two: Dictionary = sections[j + 1]
			var points_a: Array = one["polygon"]
			var points_b: Array = two["polygon"]
			if points_a.size() != points_b.size():
				continue
			for k in points_a.size():
				var k2 := (k + 1) % points_a.size()
				var a := _point(axis, int(one["at"]), points_a[k], mirrored) * unit_scale
				var b := _point(axis, int(one["at"]), points_a[k2], mirrored) * unit_scale
				var c := _point(axis, int(two["at"]), points_b[k2], mirrored) * unit_scale
				var d := _point(axis, int(two["at"]), points_b[k], mirrored) * unit_scale
				_triangle(st, a, b, c)
				_triangle(st, a, c, d)
		for cap in [sections.front(), sections.back()]:
			var at: int = int(cap["at"])
			var points: Array = cap["polygon"]
			var center := Vector3.ZERO
			for point: Array in points:
				center += _point(axis, at, point, mirrored)
			center /= float(points.size())
			for k in points.size():
				var a := _point(axis, at, points[k], mirrored) * unit_scale
				var b := _point(axis, at, points[(k + 1) % points.size()], mirrored) * unit_scale
				_triangle(st, center * unit_scale, a, b)
		st.generate_normals()
		var mesh := st.commit()
		if mesh:
			var inst := MeshInstance3D.new()
			inst.name = part_name + "_outline"
			inst.mesh = mesh
			inst.material_override = materials.get(s.get("mat", ""), materials.values()[0])
			add_child(inst)
	elif s.has("box"):
		var lo: Array = s["box"][0]
		var hi: Array = s["box"][1]
		var bounds := Vector3(float(hi[0]-lo[0]+1), float(hi[1]-lo[1]+1), float(hi[2]-lo[2]+1))
		var cx := (float(lo[0]) + float(hi[0]+1)) * 0.5
		var cy := (float(lo[1]) + float(hi[1]+1)) * 0.5
		var cz := (float(lo[2]) + float(hi[2]+1)) * 0.5
		if mirrored:
			cx = -cx
		var mesh := BoxMesh.new()
		mesh.size = bounds * unit_scale
		var inst := MeshInstance3D.new()
		inst.mesh = mesh
		inst.position = Vector3(cx, cy, cz) * unit_scale
		inst.material_override = materials.get(s.get("mat", ""), materials.values()[0])
		inst.name = part_name + "_box"
		add_child(inst)


static func _point(axis: String, layer: int, uv: Array, mirrored: bool) -> Vector3:
	var x := float(uv[0])
	if mirrored:
		x = -x
	return Vector3(x, float(layer), float(uv[1])) if axis == "y" else Vector3(x, float(uv[1]), float(layer))


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
