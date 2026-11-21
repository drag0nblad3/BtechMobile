class_name VxGrid
extends RefCounted
## Static voxel props (buildings, trees, rocks): a cell -> Color grid turned
## into one greedy-merged mesh with per-face shading baked into vertex
## colors, so every prop shares one opaque material.

static var _material: StandardMaterial3D


## cells: Vector3i -> Color. The mesh is centered on `pivot` (grid units)
## and scaled by `size` world units per voxel. Returns null when empty.
static func mesh(cells: Dictionary, size: float, pivot: Vector3) -> ArrayMesh:
	var faces: Array = [{}, {}, {}, {}, {}, {}]
	for c: Vector3i in cells:
		var color: Color = cells[c]
		for f in 6:
			var d: Vector3i = VxPart.DIRS[f]
			if cells.has(c + d):
				continue
			var axis := 0 if d.x != 0 else (1 if d.y != 0 else 2)
			var slices: Dictionary = faces[f]
			if not slices.has(c[axis]):
				slices[c[axis]] = {}
			slices[c[axis]][Vector2i(c[(axis + 1) % 3], c[(axis + 2) % 3])] = Color(color * VxPart.SHADE[f], 1.0)
	return VxMesher.build(faces, pivot, size)


## Fills an axis-aligned box of cells (inclusive corners).
static func box(cells: Dictionary, a: Vector3i, b: Vector3i, color: Color) -> void:
	for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
		for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
			for z in range(mini(a.z, b.z), maxi(a.z, b.z) + 1):
				cells[Vector3i(x, y, z)] = color


## Triangle count of a mesh (0 for null), for budgets in tests.
static func triangles(m: Mesh) -> int:
	if m == null:
		return 0
	@warning_ignore("integer_division")
	return m.get_faces().size() / 3


## One shared vertex-color material keeps draw state changes low on phones.
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true  # palettes are written as sRGB hex
		_material.roughness = 0.9
		_material.albedo_color = Color(0.7, 0.7, 0.7)  # the map is lit brightly; keeps light walls from washing out
	return _material
