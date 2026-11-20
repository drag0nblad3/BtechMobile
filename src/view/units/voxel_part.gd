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
var voxel_size := VOXEL_SIZE
var detail_scale := 1
var detail_style := ""
var mesh_enabled := true
var _local_bounds := AABB()


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


## Finalize authored voxel geometry. Detail is real geometry (smaller cubes),
## and the original armor count is measured AFTER fine-surface sculpting.
func seal(joint_min_y: int = 1000) -> void:
	if detail_scale > 1 and is_equal_approx(voxel_size, VOXEL_SIZE):
		_refine_grid(detail_scale)
		if detail_style == "jenner":
			VoxelFineDetail.decorate(self)
	_original_count = cells.size()
	joint_cells.clear()
	for cell: Vector3i in cells:
		if cell.y >= joint_min_y * detail_scale:
			joint_cells.append(cell)
	_update_bounds()
	if mesh_enabled:
		rebuild()


func _refine_grid(factor: int) -> void:
	var expanded: Dictionary = {}
	for cell: Vector3i in cells:
		var material_id: int = cells[cell]
		var base := cell * factor
		for x in factor:
			for y in factor:
				for z in factor:
					expanded[base + Vector3i(x, y, z)] = material_id
	cells = expanded
	voxel_size = VOXEL_SIZE / float(factor)


## Add sub-voxel surface colors without filling intentionally open channels.
func paint_box(low: Vector3i, high: Vector3i, material_id: int) -> void:
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			for z in range(low.z, high.z + 1):
				var c := Vector3i(x, y, z)
				if cells.has(c):
					cells[c] = material_id


func _update_bounds() -> void:
	if cells.is_empty():
		_local_bounds = AABB()
		return
	var min_v := Vector3i(999999, 999999, 999999)
	var max_v := Vector3i(-999999, -999999, -999999)
	for cell: Vector3i in cells:
		min_v = Vector3i(mini(min_v.x, cell.x), mini(min_v.y, cell.y),
				mini(min_v.z, cell.z))
		max_v = Vector3i(maxi(max_v.x, cell.x), maxi(max_v.y, cell.y),
				maxi(max_v.z, cell.z))
	_local_bounds = AABB(Vector3(min_v) * voxel_size,
			Vector3(max_v - min_v + Vector3i.ONE) * voxel_size)


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
		var midpoint := (Vector3(cell) + Vector3.ONE * 0.5) * voxel_size
		if midpoint.distance_to(center) <= radius:
			cells.erase(cell)
			removed += 1
	if removed > 0:
		rebuild()
	return removed


## Seeded jagged crater. A guaranteed core is surrounded by asymmetric
## variable-radius erosion and 1-3 smaller secondary pockmarks. Damage is
## bounded to a local box and only one mesh rebuild occurs per shot.
func erase_irregular_ball(world_center: Vector3, radius: float, seed: int) -> int:
	return erase_irregular_local_ball(to_local(world_center), radius, seed)


func erase_irregular_local_ball(center: Vector3, radius: float, seed: int) -> int:
	if radius <= 0.0 or cells.is_empty():
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var axes := Vector3(rng.randf_range(0.83, 1.28),
			rng.randf_range(0.83, 1.28), rng.randf_range(0.83, 1.28))
	var cluster_count := rng.randi_range(1, 3)
	var clusters: Array[Vector4] = []
	for i in cluster_count:
		clusters.append(Vector4(
				center.x + rng.randf_range(-0.55, 0.55) * radius,
				center.y + rng.randf_range(-0.55, 0.55) * radius,
				center.z + rng.randf_range(-0.55, 0.55) * radius,
				radius * rng.randf_range(0.32, 0.56)))
	var extent := radius * 1.75 + voxel_size
	var low := Vector3i(floori((center.x - extent) / voxel_size),
			floori((center.y - extent) / voxel_size),
			floori((center.z - extent) / voxel_size))
	var high := Vector3i(ceili((center.x + extent) / voxel_size),
			ceili((center.y + extent) / voxel_size),
			ceili((center.z + extent) / voxel_size))
	var removed := 0
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			for z in range(low.z, high.z + 1):
				var cell := Vector3i(x, y, z)
				if not cells.has(cell):
					continue
				var p := (Vector3(cell) + Vector3.ONE * 0.5) * voxel_size
				var offset := p - center
				var main := (offset / axes).length()
				var chip := main <= radius * rng.randf_range(0.77, 1.18)
				if not chip:
					for pit in clusters:
						if p.distance_to(Vector3(pit.x, pit.y, pit.z)) <= pit.w:
							chip = true
							break
				if main <= radius * 0.35 or chip:
					cells.erase(cell)
					removed += 1
	if removed > 0:
		rebuild()
	return removed


## 3D grid traversal: visits only cells along the ray, instead of testing
## every occupied voxel. Critical for higher-density mobile mech geometry.
func pick_ray(origin_world: Vector3, direction_world: Vector3) -> Dictionary:
	if cells.is_empty():
		return {}
	if _local_bounds.size == Vector3.ZERO:
		_update_bounds()
	# An unattached test part has only its local transform. In live scenes
	# always use global_transform so articulated limbs pick correctly.
	var world_transform := global_transform if is_inside_tree() else transform
	var inverse := world_transform.affine_inverse()
	var origin := inverse * origin_world
	var direction := (inverse.basis * direction_world).normalized()
	if direction.length_squared() <= 0.0:
		return {}
	var distance := 0.0
	if not _local_bounds.has_point(origin):
		var entry: Variant = _local_bounds.intersects_ray(origin, direction)
		if entry == null:
			return {}
		var entry_point: Vector3 = entry
		distance = maxf(0.0, (entry_point - origin).dot(direction))
	# Nudge just past grid boundaries for robust negative-axis traversal.
	var nudge := voxel_size * 0.0001
	var probe := origin + direction * (distance + nudge)
	for step in 1024:
		if not _local_bounds.has_point(probe):
			return {}
		var cell := Vector3i(floori(probe.x / voxel_size),
				floori(probe.y / voxel_size), floori(probe.z / voxel_size))
		if cells.has(cell):
			var point := origin + direction * distance
			var world_point := world_transform * point
			return {"point": world_point, "cell": cell,
					"distance": world_point.distance_to(origin_world)}
		var tx := INF
		var ty := INF
		var tz := INF
		if absf(direction.x) > 0.0000001:
			var border_x := (cell.x + (1 if direction.x > 0.0 else 0)) * voxel_size
			tx = maxf(0.0, (border_x - probe.x) / direction.x)
		if absf(direction.y) > 0.0000001:
			var border_y := (cell.y + (1 if direction.y > 0.0 else 0)) * voxel_size
			ty = maxf(0.0, (border_y - probe.y) / direction.y)
		if absf(direction.z) > 0.0000001:
			var border_z := (cell.z + (1 if direction.z > 0.0 else 0)) * voxel_size
			tz = maxf(0.0, (border_z - probe.z) / direction.z)
		var advance := minf(tx, minf(ty, tz))
		if advance == INF:
			return {}
		distance += advance + nudge
		probe = origin + direction * (distance + nudge)
	return {}


func rebuild() -> void:
	if not mesh_enabled:
		return
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
				append_face(vertices, normals, colors, cell, face, int(cells[cell]), voxel_size)
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
		colors: PackedColorArray, cell: Vector3i, face: int, material_id: int,
		cell_size: float = VOXEL_SIZE) -> void:
	var quad: Array = QUADS[face]
	var normal := Vector3(DIRECTIONS[face])
	var shade := 1.08 if face == 2 else (0.80 if face == 3 else 0.94)
	var color: Color = PALETTE[material_id] * shade
	for corner in [0, 1, 2, 0, 2, 3]:
		vertices.append((Vector3(cell) + quad[corner]) * cell_size)
		normals.append(normal)
		colors.append(color)
