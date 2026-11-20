class_name VoxelPart
extends Node3D
## A sparse, individually destructible voxel part with culled-face mesh.

const VOXEL_SIZE := 0.075
const DIRECTIONS := [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP,
	Vector3i.DOWN, Vector3i.BACK, Vector3i.FORWARD]
const QUADS := [
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	[Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0), Vector3(0, 0, 0)],
	[Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(0, 1, 0)],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],
	[Vector3(1, 0, 1), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1)],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0)]
]
const PALETTE := [Color("4b6a83"), Color("293242"), Color("40ccfa"),
	Color("d99c42"), Color("718596"), Color("d85f41")]

var cells: Dictionary = {}  # Vector3i -> palette index
var joint_cells: Array[Vector3i] = []
var _mesh_instance: MeshInstance3D
var _original_count := 0


func fill_box(low: Vector3i, high: Vector3i, material_id: int) -> void:
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			for z in range(low.z, high.z + 1):
				cells[Vector3i(x, y, z)] = material_id


func armor_box(low: Vector3i, high: Vector3i, armor: int, core: int) -> void:
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			for z in range(low.z, high.z + 1):
				var shell := x == low.x or x == high.x or y == low.y or y == high.y \
						or z == low.z or z == high.z
				cells[Vector3i(x, y, z)] = armor if shell else core


## Remove cells while authoring geometry. Call before seal() so the mesh and
## original armor count are computed from the final sculpted shape.
func carve_box(low: Vector3i, high: Vector3i) -> int:
	var removed := 0
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			for z in range(low.z, high.z + 1):
				var cell := Vector3i(x, y, z)
				if cells.erase(cell):
					removed += 1
	return removed


func seal(joint_min_y: int = 1000) -> void:
	_original_count = cells.size()
	joint_cells.clear()
	for cell: Vector3i in cells:
		if cell.y >= joint_min_y:
			joint_cells.append(cell)
	rebuild()


func joint_fraction() -> float:
	if joint_cells.is_empty():
		return 1.0
	var intact := 0
	for cell in joint_cells:
		if cells.has(cell):
			intact += 1
	return float(intact) / float(joint_cells.size())


func erase_ball(world_center: Vector3, radius: float) -> int:
	return erase_local_ball(to_local(world_center), radius)


## Local-space entry point for deterministic sculpting and unit tests.
func erase_local_ball(center: Vector3, radius: float) -> int:
	var removed := 0
	for cell: Vector3i in cells.keys():
		var midpoint := (Vector3(cell) + Vector3.ONE * 0.5) * VOXEL_SIZE
		if midpoint.distance_to(center) <= radius:
			cells.erase(cell)
			removed += 1
	if removed > 0:
		rebuild()
	return removed


## Uses exact occupied cubes, not the overall component bounding box.
func pick_ray(origin_world: Vector3, direction_world: Vector3) -> Dictionary:
	var inverse := global_transform.affine_inverse()
	var origin := inverse * origin_world
	var direction := (inverse.basis * direction_world).normalized()
	var best := INF
	var result: Dictionary = {}
	for cell: Vector3i in cells:
		var cube := AABB(Vector3(cell) * VOXEL_SIZE, Vector3.ONE * VOXEL_SIZE)
		var intersection: Variant = cube.intersects_ray(origin, direction)
		if intersection == null:
			continue
		var hit: Vector3 = intersection
		var distance := (global_transform * hit).distance_to(origin_world)
		if (hit - origin).dot(direction) >= 0.0 and distance < best:
			best = distance
			result = {"point": global_transform * hit, "distance": distance, "cell": cell}
	return result


func rebuild() -> void:
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "Surface"
		add_child(_mesh_instance)
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 0.68
		material.metallic = 0.20
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mesh_instance.material_override = material
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for cell: Vector3i in cells:
		for face in 6:
			if not cells.has(cell + DIRECTIONS[face]):
				append_face(vertices, normals, colors, cell, face, int(cells[cell]))
	var mesh := ArrayMesh.new()
	if not vertices.is_empty():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh_instance.mesh = mesh


static func append_face(vertices: PackedVector3Array, normals: PackedVector3Array,
		colors: PackedColorArray, cell: Vector3i, face: int, material_id: int) -> void:
	var quad: Array = QUADS[face]
	var normal := Vector3(DIRECTIONS[face])
	var shade := 1.08 if face == 2 else (0.80 if face == 3 else 0.94)
	var color: Color = PALETTE[material_id] * shade
	for corner in [0, 1, 2, 0, 2, 3]:
		vertices.append((Vector3(cell) + quad[corner]) * VOXEL_SIZE)
		normals.append(normal)
		colors.append(color)
