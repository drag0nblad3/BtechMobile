class_name VxPreparedGeometry
extends RefCounted
## Worker-owned recipe and mesh arrays; no scene nodes or render resources.


static func prepare(path: String) -> Dictionary:
	var model := VxModel.load_file(path)
	var result := {"model": model, "parts": {}}
	if not model.errors.is_empty():
		return result
	var owner_of := {}
	for spec in model.parts:
		for c: Vector3i in spec["cells"]:
			owner_of[c] = spec["name"]
	var mask := VxPart.paint_mask(model)
	for spec in model.parts:
		var cells: Dictionary = spec["cells"]
		var touching := {}
		var part_name: String = spec["name"]
		for c: Vector3i in cells:
			for d: Vector3i in VxPart.DIRS:
				if owner_of.get(c + d, part_name) != part_name:
					touching[c + d] = true
		var data := surface(cells, cells, touching, model.colors, mask,
				spec["pivot"], model.voxel_size)
		data["touching"] = touching
		result["parts"][part_name] = data
	return result


## Used both by the worker and by damage rebuilds.
static func surface(cells: Dictionary, original: Dictionary, touching: Dictionary,
		colors: PackedColorArray, paintable: Array[bool], pivot: Vector3, size: float) -> Dictionary:
	var faces: Array = [{}, {}, {}, {}, {}, {}]  ## per direction: slice -> {Vector2i: Color}
	var count := 0
	for c: Vector3i in cells:
		var material_index: int = cells[c]
		var color: Color = colors[material_index]
		var role_alpha := 1.0 if paintable[material_index] else 0.25
		if _near_hole(c, cells, original):
			color = color.lerp(VxPart.SCORCH, 0.3)
		for f in 6:
			var d: Vector3i = VxPart.DIRS[f]
			if cells.has(c + d):
				continue
			var axis := 0 if d.x != 0 else (1 if d.y != 0 else 2)
			var shaded := Color(color * VxPart.SHADE[f], role_alpha * (0.5 if touching.has(c + d) else 1.0))
			var slices: Dictionary = faces[f]
			if not slices.has(c[axis]):
				slices[c[axis]] = {}
			slices[c[axis]][Vector2i(c[(axis + 1) % 3], c[(axis + 2) % 3])] = shaded
			count += 1
	return {"arrays": VxMesher.surface_arrays(faces, pivot, size), "faces": count}


static func _near_hole(c: Vector3i, cells: Dictionary, original: Dictionary) -> bool:
	if cells.size() == original.size():
		return false
	for d in VxPart.DIRS:
		if original.has(c + d) and not cells.has(c + d):
			return true
	return false


