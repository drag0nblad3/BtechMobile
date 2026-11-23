class_name VxMesher
extends RefCounted
## Greedy voxel mesher: visible faces of the same color on the same plane
## merge into larger rectangles, so finer voxels don't multiply triangles
## on flat panels. Faces touching another part are pulled in slightly.

const INSET := 0.04


## faces: Array of 6 Dictionaries (one per VxPart.DIRS entry), each
## {slice: int -> {Vector2i(u, v): Color}}; alpha encodes temporary
## face inset and paint eligibility; UV2.x keeps the paint mask.
static func build(faces: Array, pivot: Vector3, size: float) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var roles := PackedVector2Array()
	for f in 6:
		var dir: Vector3i = VxPart.DIRS[f]
		var axis := 0 if dir.x != 0 else (1 if dir.y != 0 else 2)
		var sgn := dir[axis]
		for slice: int in faces[f]:
			_merge_slice(faces[f][slice], axis, sgn, slice, f, pivot, size, verts, normals, cols, roles)
	if verts.is_empty():
		return null
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV2] = roles
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _merge_slice(grid: Dictionary, axis: int, sgn: int, slice: int, f: int, pivot: Vector3,
		size: float, verts: PackedVector3Array, normals: PackedVector3Array,
		cols: PackedColorArray, roles: PackedVector2Array) -> void:
	var keys := grid.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var used := {}
	for k: Vector2i in keys:
		if used.has(k):
			continue
		var color: Color = grid[k]
		var w := 1
		while grid.get(k + Vector2i(w, 0)) == color and not used.has(k + Vector2i(w, 0)):
			w += 1
		var h := 1
		while _row_matches(grid, used, k + Vector2i(0, h), w, color):
			h += 1
		for dv in h:
			for du in w:
				used[k + Vector2i(du, dv)] = true
		_quad(axis, sgn, slice, k, w, h, color, f, pivot, size, verts, normals, cols, roles)


static func _row_matches(grid: Dictionary, used: Dictionary, start: Vector2i, w: int, color: Color) -> bool:
	for du in w:
		var k := start + Vector2i(du, 0)
		if grid.get(k) != color or used.has(k):
			return false
	return true


static func _quad(axis: int, sgn: int, slice: int, k: Vector2i, w: int, h: int, color: Color, f: int,
		pivot: Vector3, size: float, verts: PackedVector3Array, normals: PackedVector3Array,
		cols: PackedColorArray, roles: PackedVector2Array) -> void:
	var ua := (axis + 1) % 3
	var va := (axis + 2) % 3
	# Alpha is temporary mesh metadata: 1/.5 for paintable armor,
	# .25/.125 for unpainted surfaces; the half value marks joint insets.
	var inset := is_equal_approx(color.a, 0.5) or is_equal_approx(color.a, 0.125)
	var role := 1.0 if color.a > 0.3 else 0.0
	var plane := float(slice + (1 if sgn > 0 else 0)) - (INSET * sgn if inset else 0.0)
	var corners: Array[Vector3] = []
	for uv in [Vector2(k.x, k.y), Vector2(k.x + w, k.y), Vector2(k.x + w, k.y + h), Vector2(k.x, k.y + h)]:
		var p := Vector3.ZERO
		p[axis] = plane
		p[ua] = uv.x
		p[va] = uv.y
		corners.append((p - pivot) * size)
	var order := [0, 2, 1, 0, 3, 2] if sgn > 0 else [0, 1, 2, 0, 2, 3]
	var n := Vector3(VxPart.DIRS[f])
	var c := Color(color, 1.0)
	for i in order:
		verts.append(corners[i])
		normals.append(n)
		cols.append(c)
		roles.append(Vector2(role, 0.0))
