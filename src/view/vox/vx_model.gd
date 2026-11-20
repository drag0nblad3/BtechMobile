class_name VxModel
extends RefCounted
## A voxel 'Mech written as text (data/voxels/*.json): named parts, each tied
## to a hit location, built from boxes in one shared grid. See
## docs/graphics/voxel-model-format.md. No outside editor needed.

const SWAP := {"LT": "RT", "RT": "LT", "LA": "RA", "RA": "LA", "LL": "RL", "RL": "LL"}

var id := ""
var name := ""
var voxel_size := 0.05
var colors := PackedColorArray()
var roles: Array[String] = []  ## Per material: "armor" or "structure".
var parts: Array[Dictionary] = []  ## {name, loc, parent, pivot, joint, cells}
var muzzles: Dictionary = {}  ## Location -> Vector3 (grid coords)
var errors: PackedStringArray = []
var _mat: Dictionary = {}  ## material name -> index


static func load_file(path: String) -> VxModel:
	var d: Variant = JsonFile.read(path)
	return from_dict(d if d is Dictionary else {})


static func from_dict(d: Dictionary) -> VxModel:
	var m := VxModel.new()
	m.id = d.get("id", "")
	m.name = d.get("name", m.id)
	m.voxel_size = float(d.get("voxel_size", 0.05))
	for mat: Dictionary in d.get("materials", []):
		m._mat[mat["name"]] = m.colors.size()
		m.colors.append(Color(mat["color"]))
		m.roles.append(mat.get("role", "armor"))
	for p: Dictionary in d.get("parts", []):
		m._add_part(p)
	for code: String in d.get("muzzles", {}):
		m.muzzles[Location.from_code(code)] = _vec(d["muzzles"][code])
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
	if p.has("mirror"):
		var src := part(p["mirror"])
		if src.is_empty():
			errors.append("%s mirrors unknown part %s" % [p["name"], p["mirror"]])
			return
		spec = _mirrored(src)
	else:
		spec = {"loc": Location.from_code(p.get("loc", "")), "pivot": _vec(p.get("pivot", [0, 0, 0])),
				"joint": p.get("joint", ""), "cells": {}}
		_paint(spec["cells"], p.get("shapes", []))
	spec["name"] = p["name"]
	spec["parent"] = p.get("parent", "")
	_paint(spec["cells"], p.get("add", []))
	parts.append(spec)


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


static func _vec(a: Variant) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2])) if a is Array and a.size() == 3 else Vector3.ZERO
