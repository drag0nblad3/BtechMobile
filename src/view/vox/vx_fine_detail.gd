class_name VxFineDetail
extends RefCounted
## Local, backed micro-recesses on each existing chassis's armor surfaces.
## No new silhouettes, arbitrary weapon ports, floating bits or joint changes.
## Only cut flat armor with two solid backing layers and an intact perimeter.

const PLATING := ["armor", "plate", "form", "edge", "trim"]


static func apply(model: VxModel) -> Dictionary:
	var eligible := {}
	for key: String in PLATING:
		if model._mat.has(key):
			var material: int = model._mat[key]
			if model.roles[material] == "armor":
				eligible[material] = true
	var owner := {}
	for p: Dictionary in model.parts:
		for c: Vector3i in p["cells"]:
			owner[c] = p["name"]
	var accents := {}
	var cuts := 0
	var panels := {}
	for p: Dictionary in model.parts:
		var name_: String = p["name"]
		var cells: Dictionary = p["cells"]
		var normal := _normal(name_)
		if normal == Vector3i.ZERO or cells.size() < 200:
			continue
		var patch := _find_patch(cells, owner, eligible, normal, name_)
		if patch.is_empty():
			continue
		var center: Vector3i = patch["center"]
		var horizontal := Vector3i.RIGHT if normal.z != 0 else Vector3i.BACK
		# Two narrow horizontal slots with a solid central rib.
		for v: int in [-1, 1]:
			for u in range(-1, 2):
				var c: Vector3i = center + horizontal * u + Vector3i.UP * v
				var backing: Vector3i = c - normal
				var material: int = cells[backing]
				if not accents.has(material):
					accents[material] = model.colors.size()
					model.colors.append(model.colors[material].darkened(0.25))
					model.roles.append(model.roles[material])
				cells[backing] = accents[material]
				cells.erase(c)
				owner.erase(c)
				cuts += 1
		panels[name_] = {"center": center, "normal": normal, "cut_cells": 6}
	return {"cut_cells": cuts, "panels": panels, "panel_count": panels.size()}


static func _normal(name_: String) -> Vector3i:
	# Avoid cockpit glazing, hands, weapons, joint caps, forward launch faces,
	# feet and muzzle corridors. Only use main armor bodies and greaves.
	if name_ == "ct":
		return Vector3i.BACK
	if name_ in ["lt", "ll_shin", "ll_tarsus"]:
		return Vector3i.LEFT
	if name_ in ["rt", "rl_shin", "rl_tarsus"]:
		return Vector3i.RIGHT
	return Vector3i.ZERO


static func _find_patch(cells: Dictionary, owner: Dictionary, eligible: Dictionary,
		normal: Vector3i, part_name: String) -> Dictionary:
	var low := Vector3i(100000, 100000, 100000)
	var high := -low
	for c: Vector3i in cells:
		low = Vector3i(mini(low.x, c.x), mini(low.y, c.y), mini(low.z, c.z))
		high = Vector3i(maxi(high.x, c.x), maxi(high.y, c.y), maxi(high.z, c.z))
	var middle := (Vector3(low) + Vector3(high)) * 0.5
	var horizontal := Vector3i.RIGHT if normal.z != 0 else Vector3i.BACK
	var best := {}
	var best_score := INF
	for c: Vector3i in cells:
		if not eligible.has(cells[c]) or owner.has(c + normal):
			continue
		var offset := Vector3(c) - middle
		# Prefer the center of a broad plate, away from its articulation ends.
		var score := offset.length_squared() - 2.0 * offset.dot(Vector3(normal))
		if score > best_score:
			continue
		if not _supported_patch(cells, owner, eligible, c, normal, horizontal):
			continue
		# Stable mirrored tie-break: compare y,z then absolute x from symmetry plane.
		var tie := Vector3(c.y, c.z, absf(float(c.x) + 0.5))
		if score == best_score and not best.is_empty():
			var old: Vector3 = best["tie"]
			if tie.x > old.x or (tie.x == old.x and tie.y > old.y) or (tie.x == old.x and tie.y == old.y and tie.z >= old.z):
				continue
		best_score = score
		best = {"center": c, "tie": tie, "part": part_name}
	return best


static func _supported_patch(cells: Dictionary, owner: Dictionary, eligible: Dictionary,
		center: Vector3i, normal: Vector3i, horizontal: Vector3i) -> bool:
	for v in range(-2, 3):
		for u in range(-2, 3):
			var c := center + horizontal * u + Vector3i.UP * v
			if not eligible.has(cells.get(c, -1)) or owner.has(c + normal):
				return false
			if not cells.has(c - normal) or not cells.has(c - normal * 2):
				return false
	return true
