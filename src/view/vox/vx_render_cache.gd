class_name VxRenderCache
extends RefCounted
## Shares immutable recipe data and undamaged meshes across battle units.
## Each VxPart owns its mutable damage cells; a hit never mutates cached meshes.

# Initial mobile limits: count bounds tiny entries; cells proxy memory.
# Live rigs retain their own resources independently of this cache.
const MAX_MODELS := 24
const MAX_CELLS := 400000
static var _models: Dictionary = {}
static var _recent: Array[String] = []
static var _weights: Dictionary = {}
static var _cells := 0
static var _geometry: Dictionary = {}
static var _team_materials: Dictionary = {}


static func model_at(path: String, prepared: VxModel = null) -> VxModel:
	if _models.has(path):
		_touch(path)
		return _models[path]
	var model := prepared if prepared != null else VxModel.load_file(path)
	_remember_model(path, model)
	return model


static func _remember_model(path: String, model: VxModel) -> void:
	if _models.has(path):
		_evict(path)
	var weight := model.cell_count()
	if weight > MAX_CELLS or not model.errors.is_empty():
		return
	while not _recent.is_empty() and (_models.size() >= MAX_MODELS or _cells + weight > MAX_CELLS):
		_evict(_recent[0])
	_models[path] = model
	_weights[path] = weight
	_cells += weight
	_touch(path)


static func _touch(path: String) -> void:
	_recent.erase(path)
	_recent.append(path)


static func _evict(path: String) -> void:
	_cells -= int(_weights.get(path, 0))
	_weights.erase(path)
	_models.erase(path)
	_geometry.erase(path)
	_recent.erase(path)


static func clear() -> void:
	_models.clear()
	_geometry.clear()
	_weights.clear()
	_recent.clear()
	_cells = 0


static func stats() -> Dictionary:
	return {"models": _models.size(), "cells": _cells, "meshes": _geometry.size()}


static func ready(path: String) -> bool:
	return _models.has(path) and _geometry.has(path)


static func geometry_at(path: String) -> Dictionary:
	if _models.has(path):
		_touch(path)
	return _geometry.get(path, {})


static func remember(path: String, parts: Dictionary) -> void:
	if not _models.has(path):
		return
	_touch(path)
	var geometry := {}
	for name: String in parts:
		var p: VxPart = parts[name]
		geometry[name] = {"mesh": p.mesh, "triangles": p.triangles,
				"faces": p.faces_before_merge, "touching": p.touching, "paint_bounds": p.paint_bounds}
	_geometry[path] = geometry


static func side_material(side: int) -> StandardMaterial3D:
	var index := posmod(side, PlaceholderMech.SIDE_COLORS.size())
	if not _team_materials.has(index):
		var mat := VxPart.shared_material().duplicate() as StandardMaterial3D
		# Vertex colors still define each chassis; the team wash is subdued.
		var tint: Color = PlaceholderMech.SIDE_COLORS[index]
		mat.albedo_color = Color.WHITE.lerp(tint, 0.24)
		_team_materials[index] = mat
	return _team_materials[index]
