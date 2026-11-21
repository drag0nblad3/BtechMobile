class_name VxShapePreview
extends Node3D
## Unsubdivided, polygon-surface proxy of the manually authored loft profiles.
## This is a shape approval tool only, not the game voxel renderer.
## The contours are EXACTLY those in data/voxels/*_shape.json.
## Erases are intentionally not shown: compare voxel renders for cutouts.

var _mesh_by_part: Dictionary = {}
var _joints: Dictionary = {}


## Show isolated independently authored components without destroying rig parenting.
## Empty selection restores the whole low-poly sculpture.
func isolate_parts(names: Array[String]) -> void:
	for component: String in _mesh_by_part:
		for inst: MeshInstance3D in _mesh_by_part[component]:
			inst.visible = names.is_empty() or names.has(component)


static func from_file(path: String) -> VxShapePreview:
	var d: Variant = JsonFile.read(path)
	var preview := VxShapePreview.new()
	preview._build(d if d is Dictionary else {})
	return preview


func _build(d: Dictionary) -> void:
	var unit_scale: float = float(d.get("voxel_size", 0.05))
	var shapes_by_name := {}
	var rig := VxModel.from_dict(d)
	var materials := {}
	for item: Dictionary in d.get("materials", []):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(item["color"])
		material.roughness = 0.88
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		materials[item["name"]] = material
	for p: Dictionary in d.get("parts", []):
		var name: String = p["name"]
		var spec: Dictionary = rig.part(name)
		var ancestor_name: String = p.get("parent", "")
		var ancestor: Node3D = _joints.get(ancestor_name, self)
		var origin: Vector3 = rig.part(ancestor_name).get("pivot", Vector3.ZERO)
		var joint := Node3D.new()
		joint.name = name + "_review_joint"
		joint.position = (spec["pivot"] - origin) * unit_scale
		ancestor.add_child(joint)
		_joints[name] = joint
		_mesh_by_part[name] = []
		var shapes: Array = p.get("shapes", [])
		var mirror_part: bool = p.has("mirror")
		if mirror_part:
			shapes = shapes_by_name.get(p["mirror"], [])
		shapes_by_name[p["name"]] = shapes
		for s: Dictionary in shapes:
			_draw_shape(s, mirror_part, unit_scale, materials, name, joint, spec["pivot"])
		for s: Dictionary in p.get("add", []):
			_draw_shape(s, mirror_part, unit_scale, materials, name, joint, spec["pivot"])

	# The Jenner's bent leg shapes are authored in its sections already.
	# Apply only a small asymmetric stance, not a second exaggerated knee bend.
	# These review angles do not alter the animation rig or voxel geometry.
	if d.get("legs", "") == "digitigrade":
		for side in ["ll", "rl"]:
			if _joints.has(side + "_tarsus"):
				var left: bool = side == "ll"
				_joints[side].rotation.x = deg_to_rad(-10.0 if left else 5.0)
				_joints[side + "_shin"].rotation.x = deg_to_rad(15.0 if left else 12.0)
				_joints[side + "_tarsus"].rotation.x = deg_to_rad(-6.0 if left else -8.0)




func _draw_shape(s: Dictionary, mirrored: bool, unit_scale: float,
		materials: Dictionary, part_name: String, joint: Node3D, pivot: Vector3) -> void:
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
			if points_a.size() != points_b.size() or points_a.size() < 3:
				continue
			# Determine outward normals from the interpolated centerline.
			# Wrong cap/side winding made solid armor shields look like open cups.
			var centerline := Vector3.ZERO
			for k in points_a.size():
				centerline += (
						_point(axis, int(one["at"]), points_a[k], mirrored)
						+ _point(axis, int(two["at"]), points_b[k], mirrored)
						) * (unit_scale * 0.5)
			centerline /= float(points_a.size())
			for k in points_a.size():
				var k2 := (k + 1) % points_a.size()
				var a := _point(axis, int(one["at"]), points_a[k], mirrored) * unit_scale
				var b := _point(axis, int(one["at"]), points_a[k2], mirrored) * unit_scale
				var c := _point(axis, int(two["at"]), points_b[k2], mirrored) * unit_scale
				var d := _point(axis, int(two["at"]), points_b[k], mirrored) * unit_scale
				var outward := ((a + b + c + d) * 0.25) - centerline
				var face_normal := (b - a).cross(c - a)
				if face_normal.dot(outward) < 0.0:
					_triangle(st, a, c, b)
					_triangle(st, a, d, c)
				else:
					_triangle(st, a, b, c)
					_triangle(st, a, c, d)
		for cap_index in range(2):
			var cap: Dictionary = sections[0] if cap_index == 0 else sections.back()
			var at: int = int(cap["at"])
			var points: Array = cap["polygon"]
			var center := Vector3.ZERO
			for point: Array in points:
				center += _point(axis, at, point, mirrored)
			center /= float(points.size())
			var expected := Vector3.UP if axis == "y" else Vector3.BACK
			if cap_index == 0:
				expected = -expected
			for k in points.size():
				var a := _point(axis, at, points[k], mirrored) * unit_scale
				var b := _point(axis, at, points[(k + 1) % points.size()], mirrored) * unit_scale
				var pivot_center: Vector3 = center * unit_scale
				var normal := (a - pivot_center).cross(b - pivot_center)
				if normal.dot(expected) < 0.0:
					_triangle(st, pivot_center, b, a)
				else:
					_triangle(st, pivot_center, a, b)
		st.generate_normals()
		var mesh := st.commit()
		if mesh:
			var inst := MeshInstance3D.new()
			inst.name = part_name + "_outline"
			inst.mesh = mesh
			inst.material_override = materials.get(s.get("mat", ""), materials.values()[0])
			inst.position = -pivot * unit_scale
			joint.add_child(inst)
			_mesh_by_part[part_name].append(inst)
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
		inst.position = (Vector3(cx, cy, cz) - pivot) * unit_scale
		inst.material_override = materials.get(s.get("mat", ""), materials.values()[0])
		inst.name = part_name + "_box"
		joint.add_child(inst)
		_mesh_by_part[part_name].append(inst)


static func _point(axis: String, layer: int, uv: Array, mirrored: bool) -> Vector3:
	var x := float(uv[0])
	if mirrored:
		x = -x
	return Vector3(x, float(layer), float(uv[1])) if axis == "y" else Vector3(x, float(uv[1]), float(layer))


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
