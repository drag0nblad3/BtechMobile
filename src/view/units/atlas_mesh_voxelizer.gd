class_name AtlasMeshVoxelizer
extends RefCounted
## Actual triangle-mesh -> damageable voxel scan converter.
##
## Each authored source component is a closed manifold triangle mesh.
## Rasterize XY scan columns against its triangle planes and fill Z between
## paired crossings (even/odd ray parity). Holes and inset eye sockets are
## authored as subtractive source meshes and applied in phase order.
##
## Geometry is baked once per part/scale and cached in memory so spawning
## 20 or 60 clones does not recompute triangle intersections.
##
## The live VoxelPart still owns individual physical voxel cells, receives
## irregular damage, uses the surface-net renderer, and keeps joint sockets.
const COARSE_CELL := VoxelPart.VOXEL_SIZE
const EPS := 0.00001
static var _cache: Dictionary = {}
static var bake_count := 0


static func put(part: VoxelPart, key: String) -> void:
	var factor := part.detail_scale
	var cache_id := key + ":" + str(factor)
	if not _cache.has(cache_id):
		_cache[cache_id] = voxelize_components(
				AtlasSourceMesh.part_meshes(key), factor)
		bake_count += 1
	# Dictionary.duplicate() ensures each spawned mech destroys ONLY its own
	# voxels while retaining shared precomputed source geometry.
	part.cells = (_cache[cache_id] as Dictionary).duplicate()
	# Cells are ALREADY physically authored at this detail scale. This
	# deliberately bypasses the legacy cube-splitting operation in seal().
	part.voxel_size = COARSE_CELL / float(factor)
	part.detail_style = "mesh_atlas"


static func voxelize_components(components: Array[Dictionary],
		factor: int) -> Dictionary:
	var cells: Dictionary = {}
	for phase in [0, 1, 2]:
		for component: Dictionary in components:
			if int(component.get("phase", 0)) != phase:
				continue
			var voxels := raster_triangle_shell(
					component["tris"] as PackedVector3Array, factor)
			var material: int = int(component["material"])
			if phase == 1:
				for cell: Vector3i in voxels:
					cells.erase(cell)
			else:
				for cell: Vector3i in voxels:
					cells[cell] = material
	return cells


static func raster_triangle_shell(vertices: PackedVector3Array,
		factor: int) -> Dictionary:
	# Sparse columns avoid scanning every cell against every face. A single
	# triangle contributes only to columns inside its projected XY bounds.
	var columns: Dictionary = {} # Vector2i(x,y) -> array of Z intersections
	for face in range(0, vertices.size(), 3):
		var a: Vector3 = vertices[face]
		var b: Vector3 = vertices[face + 1]
		var c: Vector3 = vertices[face + 2]
		var dx1 := b.x - a.x
		var dy1 := b.y - a.y
		var dx2 := c.x - a.x
		var dy2 := c.y - a.y
		var den := dx1 * dy2 - dx2 * dy1
		if absf(den) < EPS:
			continue  # projected vertical side, cannot intersect Z ray
		var min_ix := ceili(minf(a.x, minf(b.x, c.x)) * factor - 0.5)
		var max_ix := floori(maxf(a.x, maxf(b.x, c.x)) * factor - 0.5)
		var min_iy := ceili(minf(a.y, minf(b.y, c.y)) * factor - 0.5)
		var max_iy := floori(maxf(a.y, maxf(b.y, c.y)) * factor - 0.5)
		for ix in range(min_ix, max_ix + 1):
			var px := (float(ix) + 0.5) / float(factor)
			for iy in range(min_iy, max_iy + 1):
				var py := (float(iy) + 0.5) / float(factor)
				var vx := px - a.x
				var vy := py - a.y
				var u := (vx * dy2 - vy * dx2) / den
				var v := (dx1 * vy - dy1 * vx) / den
				if u < -EPS or v < -EPS or u + v > 1.0 + EPS:
					continue
				var z := a.z + u * (b.z - a.z) + v * (c.z - a.z)
				var k := Vector2i(ix, iy)
				if not columns.has(k):
					columns[k] = []
				var values: Array = columns[k]
				values.append(z)

	var result: Dictionary = {}
	for key: Vector2i in columns:
		var zvals: Array = columns[key]
		zvals.sort()
		var distinct: Array[float] = []
		for value: float in zvals:
			if distinct.is_empty() or absf(float(value) -
					distinct[distinct.size() - 1]) > 0.002:
				distinct.append(float(value))
		# A valid watertight mesh has an EVEN number of crossings. Ignore
		# the final crossing if numerical seam degeneracy produces odd.
		for i in range(0, distinct.size() - 1, 2):
			var lo := ceili(distinct[i] * factor - 0.5 + EPS)
			var hi := floori(distinct[i + 1] * factor - 0.5 - EPS)
			for iz in range(lo, hi + 1):
				result[Vector3i(key.x, key.y, iz)] = true
	return result
