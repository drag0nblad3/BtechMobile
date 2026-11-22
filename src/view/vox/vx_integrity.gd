class_name VxIntegrity
extends RefCounted
## Conservative topology repair after the FINAL raster/ownership pass.
## Never weld independent moving parts or seal authored ports and voids.

const GAP := 3
const SEARCH_LIMIT := 4500
const DIRS: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP,
		Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]


static func components(cells: Dictionary) -> Array[Dictionary]:
	var remaining := {}
	for c: Vector3i in cells:
		remaining[c] = true
	var groups: Array[Dictionary] = []
	while not remaining.is_empty():
		var seed: Vector3i = remaining.keys()[0]
		remaining.erase(seed)
		var group: Dictionary = {}
		group[seed] = true
		var queue: Array[Vector3i] = [seed]
		var index := 0
		while index < queue.size():
			var c: Vector3i = queue[index]
			index += 1
			for delta: Vector3i in DIRS:
				var neighbor := c + delta
				if remaining.has(neighbor):
					remaining.erase(neighbor)
					group[neighbor] = true
					queue.append(neighbor)
		groups.append(group)
	groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.size() > b.size())
	return groups


static func repair(m: VxModel, recipe: Dictionary = {}) -> Dictionary:
	var report := {"before": 0, "after": 0, "rejoined": 0,
			"joint_contacts": 0, "added": 0, "empty_parts": 0}
	var owned := {}
	for p: Dictionary in m.parts:
		for c: Vector3i in p["cells"]:
			owned[c] = p["name"]
	var n := maxi(1, m.detail)
	var voids := _authored_voids(recipe, n)
	var muzzle_guard := _muzzle_guard(m, n)
	for p: Dictionary in m.parts:
		var cells: Dictionary = p["cells"]
		var groups := components(cells)
		if groups.is_empty():
			report["empty_parts"] += 1
			continue
		report["before"] += groups.size() - 1
		var main: Dictionary = groups[0]
		# Never join a full barrel, independent plate or another large module.
		var cap := mini(18 * n * n * n, maxi(2 * n * n * n, floori(main.size() * 0.06)))
		for i in range(1, groups.size()):
			var island: Dictionary = groups[i]
			if island.size() > cap:
				continue
			var route := _path(island.keys(), main, owned, voids, muzzle_guard, GAP * n)
			if route.is_empty():
				continue
			for c: Vector3i in route:
				cells[c] = _structure(m)
				owned[c] = p["name"]
				main[c] = true
			for c: Vector3i in island:
				main[c] = true
			report["added"] += route.size()
			report["rejoined"] += 1

	# Only explicit joints get a parent-contact bridge, not decorative panels.
	for p: Dictionary in m.parts:
		if String(p.get("joint", "")).is_empty() or String(p.get("parent", "")).is_empty():
			continue
		var parent: Dictionary = m.part(String(p["parent"]))
		if parent.is_empty() or p["cells"].is_empty() or parent["cells"].is_empty():
			continue
		if _touch(p["cells"], parent["cells"]):
			continue
		var parent_cell := _nearest(parent["cells"], Vector3i(p["pivot"]))
		var child_cell := _nearest(p["cells"], parent_cell)
		var route := _path([child_cell], parent["cells"], owned, voids, muzzle_guard, 2 * n)
		if route.is_empty():
			continue
		for c: Vector3i in route:
			p["cells"][c] = _structure(m)
			owned[c] = p["name"]
		report["added"] += route.size()
		report["joint_contacts"] += 1

	var residual := {}
	for p: Dictionary in m.parts:
		var groups := components(p["cells"])
		var count := maxi(0, groups.size() - 1)
		report["after"] += count
		if count > 0:
			var sizes := []
			for i in range(1, groups.size()):
				sizes.append(groups[i].size())
			residual[p["name"]] = {"count": count, "sizes": sizes,
					"main": groups[0].size(), "parent": p.get("parent", ""),
					"joint": p.get("joint", ""), "loc": p.get("loc", -1)}
	report["residual_parts"] = residual
	return report


static func _structure(m: VxModel) -> int:
	for key in ["joint", "frame", "inside", "structure"]:
		if m._mat.has(key):
			return int(m._mat[key])
	for i in m.roles.size():
		if m.roles[i] == "structure":
			return i
	return 0


static func _touch(a: Dictionary, b: Dictionary) -> bool:
	for c: Vector3i in a:
		for d: Vector3i in DIRS:
			if b.has(c + d):
				return true
	return false


static func _nearest(cells: Dictionary, point: Vector3i) -> Vector3i:
	var closest := point
	var best := 2147483647
	for c: Vector3i in cells:
		var dist := absi(c.x-point.x) + absi(c.y-point.y) + absi(c.z-point.z)
		if dist < best:
			best = dist
			closest = c
	return closest


static func _path(seeds: Array, target: Dictionary, owned: Dictionary,
		voids: Array[Dictionary], guard: Dictionary, max_gap: int) -> Array[Vector3i]:
	var queue: Array[Vector3i] = []
	var dist: Dictionary = {}
	var prev: Dictionary = {}
	for c: Vector3i in seeds:
		queue.append(c)
		dist[c] = 0
	var head := 0
	while head < queue.size() and head < SEARCH_LIMIT:
		var c: Vector3i = queue[head]
		head += 1
		if int(dist[c]) >= max_gap:
			continue
		for d: Vector3i in DIRS:
			var step := c + d
			if target.has(step):
				var route: Array[Vector3i] = []
				var at := c
				while prev.has(at):
					route.append(at)
					at = prev[at]
				route.reverse()
				return route
			if dist.has(step) or owned.has(step) or guard.has(step):
				continue
			if _in_void(step, voids):
				continue
			dist[step] = int(dist[c]) + 1
			prev[step] = c
			queue.append(step)
	return []


static func _in_void(c: Vector3i, voids: Array[Dictionary]) -> bool:
	for item: Dictionary in voids:
		var lo: Vector3i = item["lo"]
		var hi: Vector3i = item["hi"]
		if c.x >= lo.x and c.x <= hi.x and c.y >= lo.y and c.y <= hi.y \
				and c.z >= lo.z and c.z <= hi.z:
			return true
	return false


static func _authored_voids(recipe: Dictionary, n: int) -> Array[Dictionary]:
	var voids: Array[Dictionary] = []
	var by_name := {}
	for p: Dictionary in recipe.get("parts", []):
		by_name[p.get("name", "")] = p
	for p: Dictionary in recipe.get("parts", []):
		var mirrored := p.has("mirror")
		var source: Dictionary = by_name.get(p["mirror"], {}) if mirrored else p
		for s: Dictionary in source.get("shapes", []) + p.get("add", []):
			if not s.has("erase"):
				continue
			var lo := Vector3i(s["erase"][0][0], s["erase"][0][1], s["erase"][0][2])
			var hi := Vector3i(s["erase"][1][0], s["erase"][1][1], s["erase"][1][2])
			if mirrored:
				var low_x := lo.x
				lo.x = -hi.x - 1
				hi.x = -low_x - 1
			voids.append({"lo": lo * n, "hi": (hi + Vector3i.ONE) * n - Vector3i.ONE})
	return voids


static func _muzzle_guard(m: VxModel, n: int) -> Dictionary:
	var guard := {}
	for points: Array in m.muzzles.values():
		for point: Vector3 in points:
			var c := Vector3i(floori(point.x), floori(point.y), floori(point.z))
			for x in range(c.x - n, c.x + n + 1):
				for y in range(c.y - n, c.y + n + 1):
					for z in range(c.z - 2 * n, c.z + n + 1):
						guard[Vector3i(x, y, z)] = true
	return guard
