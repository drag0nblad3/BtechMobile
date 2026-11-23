class_name VxJointBacking
extends RefCounted
## A narrow, physical 2x2 backed socket near each disconnected load path.
## Uses the sculpt's existing volumes and avoids erased ports and other parts.
## Applied only to opted-in 42-cohort recipes at their coarse authoring grid.


static func repair(m: VxModel, recipe: Dictionary) -> Dictionary:
	var owners := {}
	for part: Dictionary in m.parts:
		for c: Vector3i in part["cells"]:
			owners[c] = part["name"]
	var blocked := VxJointKeepout.mask(recipe, m)
	var fixed := 0
	var added := 0
	var remaining: Array[String] = []
	for part: Dictionary in m.parts:
		var parent_name: String = part.get("parent", "")
		if parent_name.is_empty():
			continue
		var parent: Dictionary = m.part(parent_name)
		if parent.is_empty():
			continue
		var child_cells: Dictionary = part["cells"]
		var parent_cells: Dictionary = parent["cells"]
		if VxConnectivity.solid_contact(child_cells, parent_cells):
			continue
		var proposed := VxJointPatch.choose(parent_cells, child_cells,
				owners, blocked, part["pivot"])
		if proposed.is_empty():
			remaining.append(String(part["name"]))
			continue
		var mat: int = int(m._mat.get("joint", m._mat.get("frame", 0)))
		for c: Vector3i in proposed:
			child_cells[c] = mat
			owners[c] = part["name"]
		if VxConnectivity.solid_contact(child_cells, parent_cells):
			fixed += 1
			added += proposed.size()
		else:
			for c: Vector3i in proposed:
				child_cells.erase(c)
				owners.erase(c)
			remaining.append(String(part["name"]))
	return {"fixed": fixed, "added": added, "remaining": remaining}
