class_name VxPart
extends MeshInstance3D
## One part of a voxel 'Mech: culled-face mesh of its cells, centered on its
## pivot. Cells next to shot-away voxels are drawn scorched.

const DIRS: Array[Vector3i] = [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP,
	Vector3i.DOWN, Vector3i.BACK, Vector3i.FORWARD]
const QUADS := [
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	[Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0), Vector3(0, 0, 0)],
	[Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(0, 1, 0)],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],
	[Vector3(1, 1, 1), Vector3(0, 1, 1), Vector3(0, 0, 1), Vector3(1, 0, 1)],
	[Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 0)]]
const SHADE := [0.9, 0.9, 1.0, 0.7, 0.84, 0.97]
const SCORCH := Color(0.16, 0.12, 0.1)

static var _material: StandardMaterial3D
static var _wreck_material: StandardMaterial3D

var part_name := ""
var loc := -1
var original: Dictionary = {}  ## Vector3i -> material index, as built
var cells: Dictionary = {}     ## What is still there
var touching: Dictionary = {}  ## Cells of other parts; shared faces are inset so they don't flicker
var triangles := 0
var _pivot := Vector3.ZERO
var _size := 0.05
var _colors := PackedColorArray()


func setup(spec: Dictionary, model: VxModel) -> void:
	part_name = spec["name"]
	name = part_name + "_mesh"
	loc = spec["loc"]
	original = spec["cells"]
	cells = original.duplicate()
	_pivot = spec["pivot"]
	_size = model.voxel_size
	_colors = model.colors
	material_override = shared_material()


## Keeps every original cell except those in `removed`.
func set_removed(removed: Dictionary) -> void:
	var next := {}
	for c: Vector3i in original:
		if not removed.has(c):
			next[c] = original[c]
	if not removed.is_empty():
		for c: Vector3i in next.keys():  # Shot-loose voxels don't float.
			if DIRS.all(func(d: Vector3i) -> bool: return not next.has(c + d)):
				next.erase(c)
	if next.size() != cells.size():
		cells = next
		rebuild()


func set_wrecked(on: bool) -> void:
	if _wreck_material == null:
		_wreck_material = shared_material().duplicate()
		_wreck_material.albedo_color = Color(0.32, 0.3, 0.28)
	material_override = _wreck_material if on else shared_material()


## Point in this part's local space for a grid coordinate.
func local_of(grid: Vector3) -> Vector3:
	return (grid - _pivot) * _size


func rebuild() -> void:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	for c: Vector3i in cells:
		var color: Color = _colors[cells[c]]
		if _near_hole(c):
			color = color.lerp(SCORCH, 0.3)
		for f in 6:
			if cells.has(c + DIRS[f]):
				continue
			var quad: Array = QUADS[f]
			var shaded := Color(color * SHADE[f], 1.0)
			var inset := Vector3(DIRS[f]) * -0.04 if touching.has(c + DIRS[f]) else Vector3.ZERO
			for k in [0, 2, 1, 0, 3, 2]:
				verts.append((Vector3(c) + quad[k] + inset - _pivot) * _size)
				normals.append(Vector3(DIRS[f]))
				cols.append(shaded)
	@warning_ignore("integer_division")
	triangles = verts.size() / 3
	if verts.is_empty():
		mesh = null
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = cols
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = m


func _near_hole(c: Vector3i) -> bool:
	if cells.size() == original.size():
		return false
	for d in DIRS:
		if original.has(c + d) and not cells.has(c + d):
			return true
	return false


## One material for every voxel part keeps draw state changes low on phones.
static func shared_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.75
		_material.metallic = 0.15
	return _material
