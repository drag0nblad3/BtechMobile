class_name VxConnectivity
extends RefCounted
## Geometry-only connectivity repair. Tests the actual occupied grid, not
## AABBs, pivot proximity, diagonal/corner contact, or metadata parent links.
## Work on the coarse sculpt before subdivision; keep welds local to joints.

const DIRS := [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP,
	Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]
const ISLAND_REACH := 5
const JOINT_REACH := 7


static func components(cells: Dictionary) -> Array[Dictionary]:
	var pending := {}
	for c: Vector3i in cells:
		pending[c] = true
	var groups: Array[Dictionary] = []
	while not pending.is_empty():
		var seed: Vector3i = pending.keys()[0]
		var group := {seed: true}
		var queue: Array[Vector3i] = [seed]
		pending.erase(seed)
		var head := 0
		while head < queue.size():
			var c: Vector3i = queue[head]
			head += 1
			for delta: Vector3i in DIRS:
				var next := c + delta
				if pending.erase(next):
					group[next] = true
					queue.append(next)
		groups.append(group)
	groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.size() > b.size())
	return groups


## A solid attachment has a 2x2 face patch, backed by occupied voxels
## on BOTH sides. Four scattered face touches or diagonal intersections fail.
static func solid_contact(child: Dictionary, parent: Dictionary) -> bool:
	if child.is_empty() or parent.is_empty():
		return false
	for c: Vector3i in child:
		for normal: Vector3i in DIRS:
			if not parent.has(c + normal):
				continue
			var axes: Array[Vector3i] = _cross_axes(normal)
			for a_sign in [-1, 1]:
				for b_sign in [-1, 1]:
					var a: Vector3i = axes[0] * a_sign
					var b: Vector3i = axes[1] * b_sign
					var ok := true
					for offset in [Vector3i.ZERO, a, b, a + b]:
						var pos := c + offset
						if not child.has(pos) or not child.has(pos - normal) \
								or not parent.has(pos + normal) \
								or not parent.has(pos + normal * 2):
							ok = false
							break
					if ok:
						return true
	return false


static func audit(model: VxModel) -> Dictionary:
	var faults: Array[Dictionary] = []
	for p: Dictionary in model.parts:
		var cells: Dictionary = p["cells"]
		var groups := components(cells)
		if groups.size() > 1:
			faults.append({"part": p["name"], "type": "island",
				"count": groups.size(), "largest": groups[0].size()})
		var parent_name: String = p.get("parent", "")
		if parent_name.is_empty():
			continue
		var parent: Dictionary = model.part(parent_name)
		if not parent.is_empty() and not solid_contact(cells, parent["cells"]):
			faults.append({"part": p["name"], "type": "weak_joint",
				"parent": parent_name})
	return {"pass": faults.is_empty(), "faults": faults}


## Never bridge arbitrarily far or through another articulated part. Unfixed
## components remain visible in audit(), rather than being silently deleted.
static func repair(model: VxModel) -> Dictionary:
	var occupied := {}
	for p: Dictionary in model.parts:
		for c: Vector3i in p["cells"]:
			occupied[c] = p["name"]
	var mat: int = int(model._mat.get("joint", model._mat.get("frame",
			model._mat.get("inside", 0))))
	var islands_fixed := 0
	var joints_fixed := 0
	for p: Dictionary in model.parts:
		var cells: Dictionary = p["cells"]
		var groups := components(cells)
		if groups.size() <= 1:
			continue
		var body: Dictionary = groups[0].duplicate()
		for i in range(1, groups.size()):
			var island: Dictionary = groups[i]
			var path := _route(island, body, occupied, ISLAND_REACH)
			if path.size() >= 2 and _weld(path, cells, cells, occupied,
					p["name"], p["name"], mat):
				islands_fixed += 1
				# An unresolved island is not allowed to anchor other bridges.
				for c: Vector3i in island:
					body[c] = true
				for c: Vector3i in path:
					body[c] = true

	for p: Dictionary in model.parts:
		var parent_name: String = p.get("parent", "")
		if parent_name.is_empty():
			continue
		var parent: Dictionary = model.part(parent_name)
		if parent.is_empty():
			continue
		var child_cells: Dictionary = p["cells"]
		var parent_cells: Dictionary = parent["cells"]
		if solid_contact(child_cells, parent_cells):
			continue
		var pivot := Vector3i(p["pivot"])
		var starts := _near_pivot(child_cells, pivot, JOINT_REACH)
		var goals := _near_pivot(parent_cells, pivot, JOINT_REACH)
		if starts.is_empty() or goals.is_empty():
			continue
		var path := _route(starts, goals, occupied, JOINT_REACH)
		if path.size() >= 2 and _weld(path, child_cells, parent_cells,
				occupied, p["name"], parent_name, mat) \
				and solid_contact(child_cells, parent_cells):
			joints_fixed += 1
	return {"islands_fixed": islands_fixed, "joints_fixed": joints_fixed}


static func _near_pivot(cells: Dictionary, pivot: Vector3i, reach: int) -> Dictionary:
	var selected := {}
	for c: Vector3i in cells:
		var distance: int = absi(c.x - pivot.x) + absi(c.y - pivot.y) + absi(c.z - pivot.z)
		if distance <= reach:
			selected[c] = true
	return selected


static func _route(starts: Dictionary, goals: Dictionary,
		occupied: Dictionary, maximum: int) -> Array[Vector3i]:
	if starts.is_empty() or goals.is_empty():
		return []
	var queue: Array[Vector3i] = []
	var depths := {}
	var previous := {}
	for c: Vector3i in starts:
		queue.append(c)
		depths[c] = 0
	var head := 0
	while head < queue.size():
		var c: Vector3i = queue[head]
		head += 1
		var depth: int = depths[c]
		if depth >= maximum:
			continue
		for delta: Vector3i in DIRS:
			var next := c + delta
			if goals.has(next):
				var path: Array[Vector3i] = [next, c]
				var cursor: Vector3i = c
				while previous.has(cursor):
					cursor = previous[cursor]
					path.push_back(cursor)
				path.reverse()
				return path
			if occupied.has(next) or depths.has(next):
				continue
			depths[next] = depth + 1
			previous[next] = c
			queue.append(next)
	return []


static func _cross_axes(normal: Vector3i) -> Array[Vector3i]:
	if normal.x != 0:
		return [Vector3i.UP, Vector3i.BACK]
	if normal.y != 0:
		return [Vector3i.RIGHT, Vector3i.BACK]
	return [Vector3i.RIGHT, Vector3i.UP]


## Stamp a two-voxel-thick socket and 2x2 bridge. Never borrow another
## part's voxels; no overlapping parts or one-cell tendrils are introduced.
static func _weld(path: Array[Vector3i], child: Dictionary, parent: Dictionary,
		occupied: Dictionary, child_name: String, parent_name: String,
		material: int) -> bool:
	if path.size() < 2:
		return false
	var seam: Vector3i = path[-1] - path[-2]
	var axes: Array[Vector3i] = _cross_axes(seam)
	for a_sign in [-1, 1]:
		for b_sign in [-1, 1]:
			var a: Vector3i = axes[0] * a_sign
			var b: Vector3i = axes[1] * b_sign
			var proposed := {}
			for i in path.size():
				var owner := parent_name if i == path.size() - 1 else child_name
				for offset in [Vector3i.ZERO, a, b, a + b]:
					proposed[path[i] + offset] = owner
			# The contact face must have supporting volume on either side.
			for offset in [Vector3i.ZERO, a, b, a + b]:
				proposed[path[-2] - seam + offset] = child_name
				proposed[path[-1] + seam + offset] = parent_name
			var legal := true
			for c: Vector3i in proposed:
				if occupied.has(c) and occupied[c] != proposed[c]:
					legal = false
					break
			if not legal:
				continue
			for c: Vector3i in proposed:
				var owner: String = proposed[c]
				if owner == parent_name:
					parent[c] = parent.get(c, material)
				else:
					child[c] = child.get(c, material)
				occupied[c] = owner
			return true
	return false
