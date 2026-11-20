class_name VoxelSurfaceNets
extends RefCounted
## Lightweight boundary-only surface nets for a visibly less cubical mesh.
## The voxel dictionary is still the single source of truth for damage,
## picking and counts. No textures, extra physics bodies, or new rule state.
##
## One surface vertex per sign-changing 8-corner cube, centered on the
## occupied/empty edges. Connect four nearby vertices around each crossed
## lattice edge. Normals are derived from occupied->empty transitions so
## bevels and tapered panels actually shade as angled faceted surfaces.

const CORNERS := [
	Vector3i(0, 0, 0), Vector3i(1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(1, 1, 0),
	Vector3i(0, 0, 1), Vector3i(1, 0, 1),
	Vector3i(0, 1, 1), Vector3i(1, 1, 1)
]
const EDGES := [
	Vector2i(0, 1), Vector2i(2, 3), Vector2i(4, 5), Vector2i(6, 7),
	Vector2i(0, 2), Vector2i(1, 3), Vector2i(4, 6), Vector2i(5, 7),
	Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7)
]
const AXES := [Vector3i.RIGHT, Vector3i.UP, Vector3i.BACK]
const FACE_CORNERS := [
	[Vector3i.ZERO, Vector3i(0, -1, 0),
			Vector3i(0, -1, -1), Vector3i(0, 0, -1)],
	[Vector3i.ZERO, Vector3i(0, 0, -1),
			Vector3i(-1, 0, -1), Vector3i(-1, 0, 0)],
	[Vector3i.ZERO, Vector3i(-1, 0, 0),
			Vector3i(-1, -1, 0), Vector3i(0, -1, 0)]
]
const FORWARD_TRIANGLES := [0, 1, 2, 0, 2, 3]
const REVERSE_TRIANGLES := [0, 2, 1, 0, 3, 2]


static func append_surface(vertices: PackedVector3Array,
		normals: PackedVector3Array, colors: PackedColorArray,
		cells: Dictionary, cell_size: float, palette: Array) -> void:
	if cells.is_empty():
		return
	# A cube can contain an isosurface only if at least one occupied cell
	# around it has a cardinally exposed neighbor. This is much cheaper
	# than scanning the full bounding volume (especially sparse missile pods).
	var candidates: Dictionary = {}
	for cell: Vector3i in cells:
		var exposed := false
		for axis in AXES:
			if not cells.has(cell + axis) or not cells.has(cell - axis):
				exposed = true
				break
		if not exposed:
			continue
		for dx in [-1, 0]:
			for dy in [-1, 0]:
				for dz in [-1, 0]:
					candidates[cell + Vector3i(dx, dy, dz)] = true

	var surface: Dictionary = {}
	for origin: Vector3i in candidates:
		var signs: Array[int] = []
		var values: Dictionary = {}
		var inside := 0
		for offset in CORNERS:
			var sample: Vector3i = origin + offset
			var occupied := cells.has(sample)
			signs.append(1 if occupied else 0)
			if occupied:
				inside += 1
				var material_id: int = int(cells[sample])
				values[material_id] = int(values.get(material_id, 0)) + 1
		if inside == 0 or inside == 8:
			continue
		var sum := Vector3.ZERO
		var normal := Vector3.ZERO
		var crossings := 0
		for edge in EDGES:
			if signs[edge.x] == signs[edge.y]:
				continue
			var start := Vector3(CORNERS[edge.x])
			var finish := Vector3(CORNERS[edge.y])
			sum += (start + finish) * 0.5
			normal += (finish - start) * float(signs[edge.x] - signs[edge.y])
			crossings += 1
		if crossings == 0:
			continue
		var material := 0
		var best := -1
		for candidate in values:
			if int(values[candidate]) > best:
				best = int(values[candidate])
				material = int(candidate)
		surface[origin] = {
			"position": (Vector3(origin) + sum / float(crossings)
					+ Vector3.ONE * 0.5) * cell_size,
			"normal": normal.normalized(),
			"color": palette[material]
		}

	# Each occupied/empty grid edge is owned by exactly one cube origin.
	# Its four neighboring crossing cubes make a single consistently
	# oriented quad; triangulate it while using smooth vertex normals.
	for origin: Vector3i in surface:
		for axis_index in 3:
			var axis: Vector3i = AXES[axis_index]
			if cells.has(origin) == cells.has(origin + axis):
				continue
			var corners: Array = FACE_CORNERS[axis_index]
			var quad: Array[Dictionary] = []
			var valid := true
			for relative: Vector3i in corners:
				var key := origin + relative
				if not surface.has(key):
					valid = false
					break
				quad.append(surface[key])
			if not valid:
				continue
			var triangles: Array = FORWARD_TRIANGLES 					if cells.has(origin) else REVERSE_TRIANGLES
			for index: int in triangles:
				var data: Dictionary = quad[index]
				vertices.append(data["position"])
				normals.append(data["normal"])
				colors.append(data["color"])
