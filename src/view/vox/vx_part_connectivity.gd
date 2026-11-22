class_name VxPartConnectivity
extends RefCounted
## Structural audit of each actual voxel component, not just whole-model bounds.
## Six-neighbour connectivity deliberately treats corner-only touch as a gap.
const DELTAS := [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1)
]


static func audit(model: VxModel) -> Dictionary:
	var by_name := {}
	for part: Dictionary in model.parts:
		by_name[String(part["name"])] = part
	var records: Array[Dictionary] = []
	var gaps := 0
	var islands := 0
	var empty_parts := 0
	for part: Dictionary in model.parts:
		var name: String = part["name"]
		var cells: Dictionary = part["cells"]
		var sizes := _islands(cells)
		var parent_name: String = part.get("parent", "")
		var parent_contacts := -1
		if parent_name != "":
			if not by_name.has(parent_name):
				parent_contacts = 0
			else:
				parent_contacts = _contacts(cells, by_name[parent_name]["cells"])
			if parent_contacts == 0:
				gaps += 1
		if sizes.size() > 1:
			islands += sizes.size() - 1
		if cells.is_empty():
			empty_parts += 1
		var pivot: Vector3 = part.get("pivot", Vector3.ZERO)
		var item := {
			"name": name,
			"parent": parent_name,
			"voxels": cells.size(),
			"islands": sizes.size(),
			"island_sizes": sizes,
			"parent_contacts": parent_contacts,
			"pivot": [pivot.x, pivot.y, pivot.z]
		}
		records.append(item)
	return {
		"model": model.id,
		"part_count": records.size(),
		"parts": records,
		"loose_islands": islands,
		"parent_gaps": gaps,
		"empty_parts": empty_parts,
		"model_errors": Array(model.errors)
	}


static func _contacts(child: Dictionary, parent: Dictionary) -> int:
	var count := 0
	for c: Vector3i in child:
		if parent.has(c):
			count += 1
			continue
		for d: Vector3i in DELTAS:
			if parent.has(c + d):
				count += 1
				break
	return count


static func _islands(cells: Dictionary) -> Array[int]:
	var unseen := cells.duplicate()
	var groups: Array[int] = []
	while not unseen.is_empty():
		var origin: Vector3i = unseen.keys()[0]
		var queue: Array[Vector3i] = [origin]
		unseen.erase(origin)
		var next := 0
		while next < queue.size():
			var c: Vector3i = queue[next]
			next += 1
			for d: Vector3i in DELTAS:
				var n: Vector3i = c + d
				if unseen.has(n):
					unseen.erase(n)
					queue.append(n)
		groups.append(queue.size())
	groups.sort()
	groups.reverse()
	return groups
