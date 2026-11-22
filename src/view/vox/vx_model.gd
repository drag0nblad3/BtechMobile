class_name VxModel
extends RefCounted
## A voxel 'Mech written as text (data/voxels/*.json): named parts, each tied
## to a hit location, built from boxes in one shared grid. See
## docs/graphics/voxel-model-format.md. No outside editor needed.

const SWAP := {"LT": "RT", "RT": "LT", "LA": "RA", "RA": "LA", "LL": "RL", "RL": "LL"}

var id := ""
var name := ""
var voxel_size := 0.05
var detail := 1  ## Fine cells per authored cell edge ("subdivide")
var colors := PackedColorArray()
var roles: Array[String] = []  ## Per material: "armor" or "structure".
var parts: Array[Dictionary] = []  ## {name, loc, parent, pivot, joint, cells}
var unit_id := ""   ## data/units id this model shows in the test scene
var legs := "plantigrade"  ## or "digitigrade" (reverse-jointed)
var can_punch := true
var muzzles: Dictionary = {}  ## Location -> Array[Vector3] (grid coords)
var jets: Dictionary = {}     ## Location -> Array[Vector3], jump jet nozzles
var weapons: Array[Dictionary] = []  ## {label, locs: Array[int], kind: laser|cannon|missile}
var errors: PackedStringArray = []
var _mat: Dictionary = {}  ## material name -> index


static func load_file(path: String) -> VxModel:
	var d: Variant = JsonFile.read(path)
	# Keep source-only geometry manifests from the silhouette refinement stack.
	if d is Dictionary and d.has("source"):
		var base: Variant = JsonFile.read(str(d["source"]))
		if base is Dictionary:
			var resolved: Dictionary = base.duplicate(true)
			for key in d:
				if key != "source":
					resolved[key] = d[key]
			d = resolved
		else:
			push_error("Voxel source not found: %s" % d["source"])
			return from_dict({})
	return from_dict(d if d is Dictionary else {})


static func from_dict(d: Dictionary) -> VxModel:
	var recipe: Dictionary = VxArtQuality.apply(d)
	var m := VxModel.new()
	m.id = recipe.get("id", "")
	m.name = recipe.get("name", m.id)
	m.voxel_size = float(recipe.get("voxel_size", 0.05))
	for mat: Dictionary in recipe.get("materials", []):
		m._mat[mat["name"]] = m.colors.size()
		m.colors.append(Color(mat["color"]))
		m.roles.append(mat.get("role", "armor"))
	for p: Dictionary in recipe.get("parts", []):
		m._add_part(p)
	m.muzzles = _points(recipe.get("muzzles", {}))
	m.jets = _points(recipe.get("jets", {}))
	if bool(recipe.get("exclusive_parts", false)):
		m._claim_exclusive_cells() # settle coarse moving-part ownership before connecting joints
		m._repair_quality_contacts(String(recipe.get("id", "")).trim_suffix("_shape"))
	VxRefine.apply(m, int(recipe.get("subdivide", 1)), recipe)
	for p: Dictionary in recipe.get("parts", []):
		m._paint(m.part(p["name"]).get("cells", {}), p.get("detail", []))  # fine-grid touches
	if bool(recipe.get("exclusive_parts", false)):
		m._claim_exclusive_cells()
	m.unit_id = recipe.get("unit", "")
	m.legs = recipe.get("legs", "plantigrade")
	m.can_punch = recipe.get("punch", true)
	for w: Dictionary in recipe.get("weapons", []):
		var locs: Array[int] = []
		for code: String in w.get("locs", []):
			locs.append(Location.from_code(code))
		m.weapons.append({"label": w.get("label", "FIRE"), "locs": locs, "kind": w.get("kind", "laser")})
	m._validate()
	return m


func part(part_name: String) -> Dictionary:
	for p in parts:
		if p["name"] == part_name:
			return p
	return {}


func parts_at(loc: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in parts:
		if p["loc"] == loc:
			out.append(p)
	return out


func cell_count() -> int:
	var n := 0
	for p in parts:
		n += p["cells"].size()
	return n


func _add_part(p: Dictionary) -> void:
	var spec: Dictionary
	var inherited_parent := ""
	if p.has("mirror"):
		var src := part(p["mirror"])
		if src.is_empty():
			errors.append("%s mirrors unknown part %s" % [p["name"], p["mirror"]])
			return
		spec = _mirrored(src)
		# A mirror without an explicit parent follows the corresponding rig,
		# not the body root. This keeps mirrored knuckles, pod fairings and
		# cockpit details attached when their parent joint animates.
		inherited_parent = _mirrored_parent_name(String(src.get("parent", "")))
	else:
		spec = {"loc": Location.from_code(p.get("loc", "")), "pivot": _vec(p.get("pivot", [0, 0, 0])),
				"joint": p.get("joint", ""), "cells": {}}
		_paint(spec["cells"], p.get("shapes", []))
	spec["name"] = p["name"]
	spec["parent"] = p.get("parent", inherited_parent)
	_paint(spec["cells"], p.get("add", []))
	parts.append(spec)


## The smallest independently articulated part owns a shared cell; larger
## hulls lose duplicates to avoid interior coincident voxel faces. Explicitly
## opt in per sculpt, leaving existing intentional overlap studies unchanged.
func _claim_exclusive_cells() -> void:
	var ordered := parts.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["cells"].size() == b["cells"].size():
			return String(a["name"]) < String(b["name"])
		return a["cells"].size() < b["cells"].size())
	var occupied := {}
	for p: Dictionary in ordered:
		var cells: Dictionary = p["cells"]
		for c: Vector3i in cells.keys():
			if occupied.has(c):
				cells.erase(c)
			else:
				occupied[c] = p["name"]


## Contact audit and minimal bridge rods are authored on the coarse grid before
## 3x subdivision. This never fills entire hollows or swells armor volumes.
func _repair_quality_contacts(chassis: String) -> void:
	var joint_mat: int = int(_mat.get("joint", _mat.get("frame", 0)))
	if chassis == "raven":
		_bridge_small_islands(part("ra").get("cells", {}), joint_mat)
	elif chassis == "shadow_cat":
		_bridge_small_islands(part("ct").get("cells", {}), joint_mat)
	var occupied: Dictionary = {}
	for p: Dictionary in parts:
		for c: Vector3i in p["cells"]:
			occupied[c] = p["name"]
	for child: Dictionary in parts:
		var pname: String = child.get("parent", "")
		if pname.is_empty():
			continue
		var parent: Dictionary = part(pname)
		if parent.is_empty() or child["cells"].is_empty() or parent["cells"].is_empty():
			continue
		var child_cells: Dictionary = child["cells"]
		var parent_cells: Dictionary = parent["cells"]
		var touching := false
		for c: Vector3i in child_cells:
			for delta: Vector3i in VxPart.DIRS:
				if parent_cells.has(c + delta):
					touching = true
					break
			if touching:
				break
		if touching:
			continue
		# Pick the closest physically occupied ankle/shoulder surfaces.
		# Two nearest-neighbor scans avoid an O(N^2) product over voxel counts.
		var anchor := Vector3i(child["pivot"])
		var start := _nearest_cell(child_cells, anchor)
		var goal := _nearest_cell(parent_cells, start)
		start = _nearest_cell(child_cells, goal)
		var distance: int = absi(start.x-goal.x) + absi(start.y-goal.y) + absi(start.z-goal.z)
		if distance > 12:
			continue # suspicious rig: do not create a long artificial strut
		var pos: Vector3i = start
		var reached_parent := false
		for axis in [1, 0, 2]:
			while pos[axis] != goal[axis]:
				var next := pos
				next[axis] += 1 if goal[axis] > pos[axis] else -1
				if parent_cells.has(next):
					reached_parent = true
					break
				if occupied.has(next) and occupied[next] != child["name"]:
					break
				child_cells[next] = joint_mat
				occupied[next] = child["name"]
				pos = next
			if reached_parent:
				break


func _nearest_cell(cells: Dictionary, point: Vector3i) -> Vector3i:
	var closest: Vector3i = point
	var best := 2147483647
	for c: Vector3i in cells:
		var dist: int = absi(c.x-point.x)+absi(c.y-point.y)+absi(c.z-point.z)
		if dist < best:
			best = dist
			closest = c
	return closest


func _bridge_small_islands(cells: Dictionary, material: int) -> void:
	if cells.size() < 2:
		return
	var left := cells.duplicate()
	var groups: Array = []
	while not left.is_empty():
		var seed: Vector3i = left.keys()[0]
		var queue: Array[Vector3i] = [seed]
		left.erase(seed)
		var i := 0
		while i < queue.size():
			for delta: Vector3i in VxPart.DIRS:
				var q: Vector3i = queue[i] + delta
				if left.has(q):
					left.erase(q)
					queue.append(q)
			i += 1
		groups.append(queue)
	if groups.size() < 2:
		return
	groups.sort_custom(func(a: Array, b: Array) -> bool: return a.size() > b.size())
	var main: Dictionary = {}
	for c: Vector3i in groups[0]:
		main[c] = true
	for i in range(1, groups.size()):
		var best := 2147483647
		var a := Vector3i.ZERO
		var b := Vector3i.ZERO
		for candidate: Vector3i in groups[i]:
			for target: Vector3i in main:
				var dist: int = absi(candidate.x-target.x)+absi(candidate.y-target.y)+absi(candidate.z-target.z)
				if dist < best:
					best = dist
					a = candidate
					b = target
		if best > 8:
			continue
		var pos := a
		for axis in [1, 0, 2]:
			while pos[axis] != b[axis]:
				pos[axis] += 1 if b[axis] > pos[axis] else -1
				cells[pos] = material
				main[pos] = true
		for c: Vector3i in groups[i]:
			main[c] = true


## Map an implicit mirror's rig attachment to its reflected counterpart.
## Explicit "parent" values in JSON always win.
func _mirrored_parent_name(source_parent: String) -> String:
	if source_parent.is_empty():
		return ""
	var names := {"la": "ra", "ra": "la", "lt": "rt", "rt": "lt",
		"ll": "rl", "rl": "ll", "left": "right", "right": "left"}
	var tokens := source_parent.split("_")
	for i in tokens.size():
		if names.has(tokens[i]):
			tokens[i] = names[tokens[i]]
	return "_".join(tokens)


func _mirrored(src: Dictionary) -> Dictionary:
	var cells := {}
	for c: Vector3i in src["cells"]:
		cells[Vector3i(-c.x - 1, c.y, c.z)] = src["cells"][c]
	var code := Location.code(src["loc"])
	var pivot: Vector3 = src["pivot"]
	return {"loc": Location.from_code(SWAP.get(code, code)), "pivot": Vector3(-pivot.x, pivot.y, pivot.z),
			"joint": src["joint"], "cells": cells}


## Shapes: {"box": [lo, hi], "mat"}, {"shell": [lo, hi], "mat", "core"}
## (outer layer in mat, inside in core), {"erase": [lo, hi]}. Inclusive.
func _paint(cells: Dictionary, shapes: Array) -> void:
	for s: Dictionary in shapes:
		if s.has("loft"):
			_paint_loft(cells, s)
			continue
		var kind: String = "box" if s.has("box") else ("shell" if s.has("shell") else "erase")
		if not s.has(kind):
			errors.append("shape without box/shell/erase: %s" % s)
			continue
		var lo := Vector3i(_vec(s[kind][0]))
		var hi := Vector3i(_vec(s[kind][1]))
		var outer := _material(s.get("mat", ""), kind)
		var core := _material(s.get("core", s.get("mat", "")), kind)
		for x in range(lo.x, hi.x + 1):
			for y in range(lo.y, hi.y + 1):
				for z in range(lo.z, hi.z + 1):
					var c := Vector3i(x, y, z)
					if kind == "erase":
						cells.erase(c)
						continue
					var edge := x == lo.x or x == hi.x or y == lo.y or y == hi.y or z == lo.z or z == hi.z
					cells[c] = outer if kind == "box" or edge else core


## Editable, manually drawn polygonal cross-sections. This is a drawing
## primitive, not a shared chassis template. Each model defines every contour.
## {"loft":{"axis":"y"|"z","sections":[{"at":0,
##      "polygon":[[u,v], ...]}, ...]},"mat":"..."}
## "y" spans height with (x,z) outlines; "z" spans depth with (x,y).
## Adjacent outlines must have the same vertex count and correspondence.
func _paint_loft(cells: Dictionary, shape: Dictionary) -> void:
	var spec: Dictionary = shape["loft"]
	var axis: String = spec.get("axis", "y")
	if not axis in ["y", "z"]:
		errors.append("loft axis must be y or z")
		return
	var sections: Array = spec.get("sections", [])
	if sections.size() < 2:
		errors.append("loft requires at least two profile sections")
		return
	var mat := _material(shape.get("mat", ""), "box")
	var painted: Dictionary = {}
	for i in range(sections.size() - 1):
		var lower: Dictionary = sections[i]
		var upper: Dictionary = sections[i + 1]
		var a: Array = lower.get("polygon", [])
		var b: Array = upper.get("polygon", [])
		if a.size() < 3 or a.size() != b.size():
			errors.append("loft vertex counts mismatch at segment %d" % i)
			continue
		var start: int = int(lower.get("at", 0))
		var finish: int = int(upper.get("at", 0))
		if finish < start:
			errors.append("loft sections must be ascending")
			continue
		for layer in range(start, finish + 1):
			var t := 0.0 if finish == start else float(layer - start) / float(finish - start)
			var polygon := PackedVector2Array()
			var min_u := INF
			var max_u := -INF
			var min_v := INF
			var max_v := -INF
			for k in a.size():
				var p := Vector2(float(a[k][0]), float(a[k][1])).lerp(
						Vector2(float(b[k][0]), float(b[k][1])), t)
				polygon.append(p)
				min_u = minf(min_u, p.x)
				max_u = maxf(max_u, p.x)
				min_v = minf(min_v, p.y)
				max_v = maxf(max_v, p.y)
			for u in range(floori(min_u), ceili(max_u)):
				for v in range(floori(min_v), ceili(max_v)):
					if not Geometry2D.is_point_in_polygon(
							Vector2(float(u) + 0.5, float(v) + 0.5), polygon):
						continue
					var c := Vector3i(u, layer, v) if axis == "y" else Vector3i(u, v, layer)
					painted[c] = mat

	# Optional high-detail hollow skin: preserve exact silhouette without
	# multiplying unseen solid hull interiors by the subdivision factor.
	if int(shape.get("hollow", 0)) > 0:
		for c: Vector3i in painted:
			for direction: Vector3i in VxPart.DIRS:
				if not painted.has(c + direction):
					cells[c] = mat
					break
	else:
		cells.merge(painted, true)


func _material(mat_name: String, kind: String) -> int:
	if kind == "erase":
		return -1
	if not _mat.has(mat_name):
		errors.append("unknown material '%s'" % mat_name)
		return 0
	return _mat[mat_name]


func _validate() -> void:
	var names := {}
	for p in parts:
		if p["loc"] < 0:
			errors.append("%s has no valid loc" % p["name"])
		if p["parent"] != "" and not names.has(p["parent"]):
			errors.append("%s: parent %s must come first" % [p["name"], p["parent"]])
		names[p["name"]] = true
	for loc in Location.COUNT:
		if parts_at(loc).is_empty():
			errors.append("no part for %s" % Location.code(loc))
	for e in errors:
		push_warning("VxModel %s: %s" % [id, e])


## {"LA": [x, y, z]} or {"LA": [[x, y, z], ...]} -> {Location: [Vector3, ...]}
static func _points(d: Dictionary) -> Dictionary:
	var out := {}
	for code: String in d:
		var v: Array = d[code]
		var list: Array[Vector3] = []
		for p: Variant in (v if not v.is_empty() and v[0] is Array else [v]):
			list.append(_vec(p))
		out[Location.from_code(code)] = list
	return out


static func _vec(a: Variant) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2])) if a is Array and a.size() == 3 else Vector3.ZERO
