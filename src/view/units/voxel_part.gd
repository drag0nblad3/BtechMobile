class_name VoxelPart
extends Node3D
## Sparse destructible voxel volume. Individual parts can use twice the
## linear resolution without changing their real-world size or joint pivots.

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

## detail_scale=2 turns a 75 mm voxel into eight 37.5 mm microvoxels.
## Exposed three-face corners are trimmed to produce actual finer bevels.
var detail_scale := 1
var generate_mesh := true
var voxel_size := VOXEL_SIZE
var cells: Dictionary = {}  # Vector3i -> palette index
var joint_cells: Array[Vector3i] = []
var _mesh_instance: MeshInstance3D
var _original_count := 0
var _min_cell := Vector3i.ZERO
var _max_cell := Vector3i.ZERO
var _bounds := AABB()


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


## Subtract material before sealing. The final sculpted volume is the baseline
## for damage and joint-break thresholds.
func carve_box(low: Vector3i, high: Vector3i) -> int:
	var removed := 0
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			for z in range(low.z, high.z + 1):
				if cells.erase(Vector3i(x, y, z)):
					removed += 1
	return removed


func seal(joint_min_y: int = 1000) -> void:
	assert(detail_scale == 1 or detail_scale == 2)
	if detail_scale == 2:
		_subdivide()
		voxel_size = VOXEL_SIZE * 0.5
	_original_count = cells.size()
	joint_cells.clear()
	for cell: Vector3i in cells:
		if cell.y >= joint_min_y * detail_scale:
			joint_cells.append(cell)
	if generate_mesh:
		_update_bounds()
		rebuild()


func _subdivide() -> void:
	var coarse: Dictionary = cells
	var refined: Dictionary = {}
	for cell: Vector3i in coarse:
		var material_id: int = coarse[cell]
		var neighbors := 0
		for direction: Vector3i in DIRECTIONS:
			if coarse.has(cell + direction):
				neighbors += 1
		var xp := not coarse.has(cell + Vector3i.RIGHT)
		var xm := not coarse.has(cell + Vector3i.LEFT)
		var yp := not coarse.has(cell + Vector3i.UP)
		var ym := not coarse.has(cell + Vector3i.DOWN)
		var zp := not coarse.has(cell + Vector3i.BACK)
		var zm := not coarse.has(cell + Vector3i.FORWARD)
		for x in 2:
			for y in 2:
				for z in 2:
					var exposed := int(xp if x == 1 else xm) \
							+ int(yp if y == 1 else ym) \
							+ int(zp if z == 1 else zm)
					# Remove only exterior armor corners, never internal frame
					# voxels or glowing windows. This produces finer edges.
					if (material_id == 0 or material_id == 4) and exposed == 3 \
							and neighbors >= 2:
						continue
					refined[cell * 2 + Vector3i(x, y, z)] = material_id
	cells = refined


func _update_bounds() -> void:
	if cells.is_empty():
		_bounds = AABB()
		return
	var first: Vector3i = cells.keys()[0]
	_min_cell = first
	_max_cell = first
	for cell: Vector3i in cells:
		_min_cell = Vector3i(mini(_min_cell.x, cell.x),
				mini(_min_cell.y, cell.y), mini(_min_cell.z, cell.z))
		_max_cell = Vector3i(maxi(_max_cell.x, cell.x),
				maxi(_max_cell.y, cell.y), maxi(_max_cell.z, cell.z))
	_bounds = AABB(Vector3(_min_cell) * voxel_size,
			Vector3(_max_cell - _min_cell + Vector3i.ONE) * voxel_size)


## Inspect artist-authored coarse coordinates even when high-detail cells are
## subdivided. Used by chassis tests and editor tooling.
func has_sculpt_cell(coarse: Vector3i) -> bool:
	for x in detail_scale:
		for y in detail_scale:
			for z in detail_scale:
				if cells.has(coarse * detail_scale + Vector3i(x, y, z)):
					return true
	return false


func sculpt_material(coarse: Vector3i) -> int:
	for x in detail_scale:
		for y in detail_scale:
			for z in detail_scale:
				var cell := coarse * detail_scale + Vector3i(x, y, z)
				if cells.has(cell):
					return int(cells[cell])
	return -1


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


## Retained for geometric tests and predictable scripted edits.
func erase_local_ball(center: Vector3, radius: float) -> int:
	var removed := 0
	var radius_sq := radius * radius
	for cell: Vector3i in cells.keys():
		var midpoint := (Vector3(cell) + Vector3.ONE * 0.5) * voxel_size
		if midpoint.distance_squared_to(center) <= radius_sq:
			cells.erase(cell)
			removed += 1
	if removed > 0 and generate_mesh:
		rebuild()
	return removed


## One impact uses multiple irregular overlapping lobes rather than an ideal
## sphere. The seed can be recorded or supplied by tests to replay exact damage.
func erase_crater(world_center: Vector3, radius: float, seed: int) -> int:
	return erase_local_crater(to_local(world_center), radius, seed)


func erase_local_crater(center: Vector3, radius: float, seed: int) -> int:
	if radius <= 0.0 or cells.is_empty():
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var lobes: Array[Vector4] = []
	lobes.append(Vector4(center.x, center.y, center.z,
			radius * rng.randf_range(0.78, 0.98)))
	for i in 5:
		var offset := Vector3(rng.randf_range(-1.0, 1.0),
				rng.randf_range(-1.0, 1.0),
				rng.randf_range(-1.0, 1.0)).normalized()
		offset *= radius * rng.randf_range(0.20, 0.65)
		var c := center + offset
		lobes.append(Vector4(c.x, c.y, c.z,
				radius * rng.randf_range(0.30, 0.61)))
	var removed := 0
	for cell: Vector3i in cells.keys():
		var midpoint := (Vector3(cell) + Vector3.ONE * 0.5) * voxel_size
		for lobe: Vector4 in lobes:
			var delta := midpoint - Vector3(lobe.x, lobe.y, lobe.z)
			if delta.length_squared() <= lobe.w * lobe.w:
				cells.erase(cell)
				removed += 1
				break
	if removed > 0 and generate_mesh:
		rebuild()
	return removed


## Ray traversal is proportional to crossed grid cells, not all voxels.
## This matters when a detail=2 Jenner has tens of thousands of small cells.
func pick_ray(origin_world: Vector3, direction_world: Vector3) -> Dictionary:
	if cells.is_empty():
		return {}
	var inverse := global_transform.affine_inverse()
	var origin := inverse * origin_world
	var direction := (inverse.basis * direction_world).normalized()
	var entry: Variant = _bounds.intersects_ray(origin, direction)
	if entry == null and not _bounds.has_point(origin):
		return {}
	var start: Vector3 = origin if _bounds.has_point(origin) else entry
	# Move an epsilon into the first cube, retaining the unmodified world hit.
	var probe := start + direction * (voxel_size * 0.0001)
	var cell := Vector3i(floori(probe.x / voxel_size),
			floori(probe.y / voxel_size), floori(probe.z / voxel_size))
	var step := Vector3i(1 if direction.x >= 0.0 else -1,
			1 if direction.y >= 0.0 else -1,
			1 if direction.z >= 0.0 else -1)
	var next := Vector3(INF, INF, INF)
	var delta := Vector3(INF, INF, INF)
	if not is_zero_approx(direction.x):
		next.x = ((cell.x + (1 if direction.x > 0.0 else 0)) * voxel_size
				- probe.x) / direction.x
		delta.x = voxel_size / absf(direction.x)
	if not is_zero_approx(direction.y):
		next.y = ((cell.y + (1 if direction.y > 0.0 else 0)) * voxel_size
				- probe.y) / direction.y
		delta.y = voxel_size / absf(direction.y)
	if not is_zero_approx(direction.z):
		next.z = ((cell.z + (1 if direction.z > 0.0 else 0)) * voxel_size
				- probe.z) / direction.z
		delta.z = voxel_size / absf(direction.z)
	var distance := 0.0
	# Maximum possible grid cells through the part's occupied bounding box.
	var size := _max_cell - _min_cell + Vector3i.ONE
	for i in (size.x + size.y + size.z + 3):
		if cell.x < _min_cell.x or cell.x > _max_cell.x \
				or cell.y < _min_cell.y or cell.y > _max_cell.y \
				or cell.z < _min_cell.z or cell.z > _max_cell.z:
			break
		if cells.has(cell):
			var world_point := global_transform * (start + direction * distance)
			return {"point": world_point,
					"distance": world_point.distance_to(origin_world), "cell": cell}
		if next.x <= next.y and next.x <= next.z:
			distance = next.x
			next.x += delta.x
			cell.x += step.x
		elif next.y <= next.z:
			distance = next.y
			next.y += delta.y
			cell.y += step.y
		else:
			distance = next.z
			next.z += delta.z
			cell.z += step.z
	return {}


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
				append_face(vertices, normals, colors, cell, face,
						int(cells[cell]), voxel_size)
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
		size: float = VOXEL_SIZE) -> void:
	var quad: Array = QUADS[face]
	var normal := Vector3(DIRECTIONS[face])
	var shade := 1.08 if face == 2 else (0.80 if face == 3 else 0.94)
	var color: Color = PALETTE[material_id] * shade
	for corner in [0, 1, 2, 0, 2, 3]:
		vertices.append((Vector3(cell) + quad[corner]) * size)
		normals.append(normal)
		colors.append(color)
