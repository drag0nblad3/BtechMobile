class_name VxShapeRaster
extends RefCounted
## Convert approved polygon lofts directly to a finer occupied-cell grid.
## This is NOT the 2x2x2 expansion used for primitive box recipes.
## A voxel is retained when its center lies inside an interpolated contour.
## Original geometry files remain readable and untouched.

static func rebuild(m: VxModel, source: Dictionary, n: int) -> void:
	m.voxel_size /= float(n)
	for part: Dictionary in m.parts:
		part["pivot"] = part["pivot"] * n
	for table: Dictionary in [m.muzzles, m.jets]:
		for loc: int in table:
			var scaled: Array[Vector3] = []
			for point: Vector3 in table[loc]:
				scaled.append(point * n)
			table[loc] = scaled

	var completed := {}
	for spec: Dictionary in source.get("parts", []):
		var cells := {}
		if spec.has("mirror"):
			var original: Dictionary = completed.get(spec["mirror"], {})
			for c: Vector3i in original:
				cells[Vector3i(-c.x - 1, c.y, c.z)] = original[c]
		else:
			_paint(cells, spec.get("shapes", []), m, n)
		_paint(cells, spec.get("add", []), m, n)
		var part: Dictionary = m.part(spec["name"])
		part["cells"] = cells
		completed[spec["name"]] = cells


static func _paint(cells: Dictionary, shapes: Array, m: VxModel, n: int) -> void:
	for shape: Dictionary in shapes:
		if shape.has("loft"):
			_loft(cells, shape, m, n)
			continue
		var kind := "box" if shape.has("box") else ("shell" if shape.has("shell") else "erase")
		if not shape.has(kind):
			continue  # The coarse VxModel pass already reports invalid operations.
		var bounds: Array = shape[kind]
		var lo := Vector3i(int(bounds[0][0]), int(bounds[0][1]), int(bounds[0][2])) * n
		var hi := (Vector3i(int(bounds[1][0]), int(bounds[1][1]), int(bounds[1][2])) + Vector3i.ONE) * n - Vector3i.ONE
		var outer: int = m._mat.get(str(shape.get("mat", "")), 0)
		var core: int = m._mat.get(str(shape.get("core", shape.get("mat", ""))), outer)
		for x in range(lo.x, hi.x + 1):
			for y in range(lo.y, hi.y + 1):
				for z in range(lo.z, hi.z + 1):
					var c := Vector3i(x, y, z)
					if kind == "erase":
						cells.erase(c)
					else:
						var edge := x == lo.x or x == hi.x or y == lo.y or y == hi.y or z == lo.z or z == hi.z
						cells[c] = outer if kind == "box" or edge else core


static func _loft(cells: Dictionary, shape: Dictionary, m: VxModel, n: int) -> void:
	var loft: Dictionary = shape["loft"]
	var axis: String = loft.get("axis", "y")
	var sections: Array = loft.get("sections", [])
	var material: int = m._mat.get(str(shape.get("mat", "")), 0)
	if sections.size() < 2:
		return
	for i in range(sections.size() - 1):
		var a: Dictionary = sections[i]
		var b: Dictionary = sections[i + 1]
		var poly_a: Array = a["polygon"]
		var poly_b: Array = b["polygon"]
		if poly_a.size() < 3 or poly_a.size() != poly_b.size():
			continue
		var start := int(a["at"])
		var finish := int(b["at"])
		if finish < start:
			continue
		# Adjacent spans never paint each other's layer. Only the last span
		# includes the source contour's final full cell-thickness slice.
		var end_fine := (finish + 1) * n if i == sections.size() - 2 else finish * n
		for layer in range(start * n, end_fine):
			var position := (float(layer) + 0.5) / float(n)
			var t := clampf((position - float(start)) / float(maxi(1, finish - start)), 0.0, 1.0)
			var polygon := PackedVector2Array()
			var min_u := INF
			var max_u := -INF
			var min_v := INF
			var max_v := -INF
			for k in poly_a.size():
				var point := Vector2(float(poly_a[k][0]), float(poly_a[k][1])).lerp(
						Vector2(float(poly_b[k][0]), float(poly_b[k][1])), t)
				polygon.append(point)
				min_u = minf(min_u, point.x)
				max_u = maxf(max_u, point.x)
				min_v = minf(min_v, point.y)
				max_v = maxf(max_v, point.y)
			for u in range(floori(min_u * n), ceili(max_u * n)):
				for v in range(floori(min_v * n), ceili(max_v * n)):
					if not Geometry2D.is_point_in_polygon(
							Vector2((float(u) + 0.5) / n, (float(v) + 0.5) / n), polygon):
						continue
					var cell := Vector3i(u, layer, v) if axis == "y" else Vector3i(u, v, layer)
					cells[cell] = material
