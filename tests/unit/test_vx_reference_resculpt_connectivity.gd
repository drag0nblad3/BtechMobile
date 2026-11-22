extends TestCase
## Reference-driven resculpt regression: every voxel belongs to exactly one part,
## every articulated part is internally connected, every child touches its parent.
## Run on both recipes at authored coarse resolution so 3x meshes are not allocated.
const IDS := ["raven", "shadow_cat", "flea", "jagermech", "king_crab", "rifleman", "hunchback_iic", "locust"]
const OFFSETS := [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]

func test_reference_resculpts_all_part_islands_and_parent_contacts() -> void:
	for id: String in IDS:
		for suffix: String in ["_shape", ""]:
			var data: Dictionary = JsonFile.read("res://data/voxels/%s%s.json" % [id, suffix])
			check_eq(data.get("reference_resculpt_cycles", 0), 3, "%s%s has three explicit macro cycles" % [id, suffix])
			data["subdivide"] = 1
			for raw: Dictionary in data.get("parts", []):
				raw.erase("detail")
			var model := VxModel.from_dict(data)
			check(model.errors.is_empty(), "%s%s invalid recipe: %s" % [id, suffix, model.errors])
			var occupied := {}
			var lookup := {}
			for part: Dictionary in model.parts:
				lookup[part["name"]] = part
				var cells: Dictionary = part["cells"]
				check(not cells.is_empty(), "%s%s %s empty" % [id, suffix, part["name"]])
				for cell: Vector3i in cells:
					check(not occupied.has(cell), "%s%s overlap: %s with %s" % [id, suffix, part["name"], occupied.get(cell, "")])
					occupied[cell] = part["name"]
				check_eq(_count_connected(cells), cells.size(), "%s%s %s contains disconnected islands" % [id, suffix, part["name"]])
			for part: Dictionary in model.parts:
				var parent: String = part["parent"]
				if parent == "":
					continue
				check(lookup.has(parent), "%s%s %s missing parent %s" % [id, suffix, part["name"], parent])
				if not lookup.has(parent):
					continue
				check(_touching(part["cells"], lookup[parent]["cells"]), "%s%s %s detached from %s" % [id, suffix, part["name"], parent])

func test_low_high_primary_contours_match() -> void:
	for id: String in IDS:
		var low: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		var high: Dictionary = JsonFile.read("res://data/voxels/%s.json" % id)
		check_eq(low["unit"], high["unit"], "%s unit mapping" % id)
		check_eq(low["parts"].size(), high["parts"].size(), "%s part count" % id)
		for i in low["parts"].size():
			var l: Dictionary = low["parts"][i]
			var h: Dictionary = high["parts"][i]
			check_eq(l["name"], h["name"], "%s part ordering" % id)
			if l.has("mirror"):
				continue
			check_eq(l.get("pivot", []), h.get("pivot", []), "%s %s pivot unchanged" % [id, l["name"]])
			var llofts: Array = []
			var hlofts: Array = []
			for s: Dictionary in l.get("shapes", []):
				if s.has("loft"):
					llofts.append(s["loft"])
			for s: Dictionary in h.get("shapes", []):
				if s.has("loft"):
					hlofts.append(s["loft"])
			check_eq(llofts, hlofts, "%s %s coarse/fine silhouette" % [id, l["name"]])

func _count_connected(cells: Dictionary) -> int:
	if cells.is_empty():
		return 0
	var visited := {}
	var queue: Array[Vector3i] = []
	for start: Vector3i in cells:
		queue.append(start)
		visited[start] = true
		break
	var head := 0
	while head < queue.size():
		var cell: Vector3i = queue[head]
		head += 1
		for offset: Vector3i in OFFSETS:
			var adjacent := cell + offset
			if cells.has(adjacent) and not visited.has(adjacent):
				visited[adjacent] = true
				queue.append(adjacent)
	return visited.size()

func _touching(a: Dictionary, b: Dictionary) -> bool:
	for cell: Vector3i in a:
		if b.has(cell):
			return true
		for offset: Vector3i in OFFSETS:
			if b.has(cell + offset):
				return true
	return false
