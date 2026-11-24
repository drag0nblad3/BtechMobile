class_name VxFineDetail
extends RefCounted
## Recessed details on the actual armor of each chassis, without changing
## silhouettes, existing openings, moving joints or record-sheet damage roles.

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
	var guarded := _guards(model)
	var accents := {}
	var cuts := 0
	var panels := {}
	var panel_count := 0
	for p: Dictionary in model.parts:
		var name_: String = p["name"]
		var cells: Dictionary = p["cells"]
		var normal := _normal(name_)
		if normal == Vector3i.ZERO or cells.size() < 100:
			continue
		var is_vent := name_ in ["ct", "lt", "rt"]
		var limit := 3 if cells.size() > 15000 else (2 if cells.size() > 5000 else 1)
		var horizontal := Vector3i.RIGHT if normal.z != 0 else Vector3i.BACK
		var part_panels := []
		for i in limit:
			var patch := _find_patch(cells, owner, eligible, guarded, normal)
			if patch.is_empty():
				break
			var center: Vector3i = patch["center"]
			var removed := 0
			# Broad torso plates get twin backed slots. Limb and head
			# armor gets one short inspection seam rather than more vents.
			var rows: Array[int] = [-1, 1] if is_vent else [0]
			for v: int in rows:
				for u: int in range(-1, 2):
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
					removed += 1
			cuts += removed
			panel_count += 1
			part_panels.append({"center": center, "normal": normal,
				"kind": "twin_slot" if is_vent else "panel_seam", "cut_cells": removed})
		if not part_panels.is_empty():
			panels[name_] = part_panels
	return {"cut_cells": cuts, "panels": panels, "panel_count": panel_count}


static func _normal(name_: String) -> Vector3i:
	# Never place a detail on forward weapon/optic faces or foot soles.
	# Side panels on arms are considered only when made of ordinary armor.
	if name_ in ["ct", "hd"]:
		return Vector3i.BACK
	if name_ in ["lt", "la", "la_forearm", "ll", "ll_shin", "ll_tarsus"]:
		return Vector3i.LEFT
	if name_ in ["rt", "ra", "ra_forearm", "rl", "rl_shin", "rl_tarsus"]:
		return Vector3i.RIGHT
	return Vector3i.ZERO


static func _guards(model: VxModel) -> Dictionary:
	var result := {}
	# Protect the neighborhoods of all authored emitters, even rear weapons.
	var radius := maxi(4, model.detail)
	for table: Dictionary in [model.muzzles, model.jets]:
		for loc: int in table:
			for point: Vector3 in table[loc]:
				var c := Vector3i(point.floor())
				for x: int in range(-radius, radius + 1):
					for y: int in range(-radius, radius + 1):
						for z: int in range(-radius, radius + 1):
							result[c + Vector3i(x, y, z)] = true
	return result


static func _find_patch(cells: Dictionary, owner: Dictionary, eligible: Dictionary,
		guarded: Dictionary, normal: Vector3i) -> Dictionary:
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
		if not eligible.has(cells[c]) or owner.has(c + normal) or guarded.has(c):
			continue
		var offset := Vector3(c) - middle
		var score := offset.length_squared() - 2.0 * offset.dot(Vector3(normal))
		if score > best_score:
			continue
		if not _supported_patch(cells, owner, eligible, guarded, c, normal, horizontal):
			continue
		var tie := Vector3(c.y, c.z, absf(float(c.x) + 0.5))
		if score == best_score and not best.is_empty():
			var old: Vector3 = best["tie"]
			if tie.x > old.x or (tie.x == old.x and tie.y > old.y) or (tie.x == old.x and tie.y == old.y and tie.z >= old.z):
				continue
		best_score = score
		best = {"center": c, "tie": tie}
	return best


static func _supported_patch(cells: Dictionary, owner: Dictionary, eligible: Dictionary,
		guarded: Dictionary, center: Vector3i, normal: Vector3i, horizontal: Vector3i) -> bool:
	for v: int in range(-2, 3):
		for u: int in range(-2, 3):
			var c: Vector3i = center + horizontal * u + Vector3i.UP * v
			if not eligible.has(cells.get(c, -1)) or owner.has(c + normal) or guarded.has(c):
				return false
			if not eligible.has(cells.get(c - normal, -1)) or not cells.has(c - normal * 2):
				return false
	return true
