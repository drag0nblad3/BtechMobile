class_name VxRefine
extends RefCounted
## Raises a model's fidelity after it is read: splits every authored cell
## into n×n×n finer cells, rounds the outer edges of thick blocks, and
## draws dark panel seams on large armor faces. Models stay easy to write
## at coarse scale; "detail" shapes can add fine-grid touches on top.

const SEAM_EVERY := 12  ## Fine cells between panel seams
const SEAM_DARK := 0.86


static func apply(m: VxModel, n: int) -> void:
	if n <= 1:
		return
	m.detail = n
	_subdivide(m, n)
	var owner := _owner_map(m)
	for p in m.parts:
		_bevel(p["cells"], owner, 3 * n - 1)
	_seams(m, owner)


static func _subdivide(m: VxModel, n: int) -> void:
	m.voxel_size /= n
	for p in m.parts:
		var fine := {}
		for c: Vector3i in p["cells"]:
			var base := c * n
			for x in n:
				for y in n:
					for z in n:
						fine[base + Vector3i(x, y, z)] = p["cells"][c]
		p["cells"] = fine
		p["pivot"] = p["pivot"] * n
	for table: Dictionary in [m.muzzles, m.jets]:
		for loc: int in table:
			var scaled: Array[Vector3] = []
			for v: Vector3 in table[loc]:
				scaled.append(v * n)
			table[loc] = scaled


static func _owner_map(m: VxModel) -> Dictionary:
	var owner := {}
	for p in m.parts:
		for c: Vector3i in p["cells"]:
			owner[c] = p["name"]
	return owner


## Removes cells on the convex edges of blocks thicker than `depth`, so
## boxes read as machined plates instead of sharp cubes.
static func _bevel(cells: Dictionary, owner: Dictionary, depth: int) -> void:
	var cut: Array[Vector3i] = []
	for c: Vector3i in cells:
		var open_axes := 0
		for axis in 3:
			for sgn in [-1, 1]:
				var d := Vector3i.ZERO
				d[axis] = sgn
				if not owner.has(c + d) and cells.has(c - d) and cells.has(c - d * depth):
					open_axes += 1
					break
		if open_axes >= 2:
			cut.append(c)
	for c in cut:
		cells.erase(c)
		owner.erase(c)


## Darkens exposed armor cells on a regular grid so big faces show panels.
static func _seams(m: VxModel, owner: Dictionary) -> void:
	var dark := {}  ## material index -> darker copy index
	for i in m.colors.size():
		if m.roles[i] == "armor":
			dark[i] = m.colors.size() + dark.size()
	for i: int in dark:
		m.colors.append(m.colors[i] * SEAM_DARK)
		m.roles.append("armor")
	for p in m.parts:
		var cells: Dictionary = p["cells"]
		for c: Vector3i in cells:
			var mat: int = cells[c]
			if not dark.has(mat):
				continue
			var on_line := posmod(c.x, SEAM_EVERY) == 0 or posmod(c.y, SEAM_EVERY) == 0 \
					or posmod(c.z, SEAM_EVERY) == 0
			if on_line and _exposed(c, owner):
				cells[c] = dark[mat]


static func _exposed(c: Vector3i, owner: Dictionary) -> bool:
	for d in VxPart.DIRS:
		if not owner.has(c + d):
			return true
	return false
