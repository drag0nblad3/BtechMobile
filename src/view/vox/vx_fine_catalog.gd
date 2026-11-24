class_name VxFineCatalog
extends RefCounted
## Opt-in 150k display/export tier derived from the latest actual recipes.
## Battle rendering continues to use the original VxModel loader/cache.

const ROOT := "res://data/voxels/"
const MAX_SOURCE_DEPTH := 8


static func paths() -> PackedStringArray:
	var result := PackedStringArray()
	for file: String in DirAccess.get_files_at(ROOT):
		if not file.ends_with(".json"):
			continue
		var path := ROOT + file
		if canonical(path) == path:
			result.append(path)
	result.sort()
	return result


## Shape studies have a corresponding detailed recipe in most cases.
## A lone shape is still eligible; variant recipes stay distinct.
static func canonical(path: String) -> String:
	if not path.ends_with("_shape.json"):
		return path
	var stem := path.trim_suffix("_shape.json")
	for candidate: String in [stem + ".json", stem + "_voxel.json"]:
		if FileAccess.file_exists(candidate):
			return candidate
	return path


static func recipe(path: String, depth: int = 0) -> Dictionary:
	if depth >= MAX_SOURCE_DEPTH:
		return {}
	var raw: Variant = JsonFile.read(path)
	if not raw is Dictionary:
		return {}
	var data: Dictionary = raw
	if not data.has("source"):
		return data
	var base := recipe(str(data["source"]), depth + 1)
	if base.is_empty():
		return {}
	return VxVariant.resolve(base, data)


static func build(path: String) -> VxModel:
	var actual := canonical(path)
	var raw := recipe(actual)
	if raw.is_empty():
		var failed := VxModel.new()
		failed.errors.append("Missing or cyclic fine source: " + actual)
		return failed
	var model := VxModel.from_dict(raw)
	if not model.errors.is_empty():
		return model
	# Distinct tier never shares mutable geometry with VxRenderCache.
	model._claim_exclusive_cells()
	var before := model.cell_count()
	var scale := VxFineGrid.target_scale(model)
	VxFineGrid.expand(model, scale)
	var high_count := model.cell_count()
	var detail := VxFineDetail.apply(model)
	model.quality_report["fine_catalog"] = {
		"source": actual, "source_voxels": before, "resampled_voxels": high_count,
		"target": VxFineGrid.TARGET, "scale": scale, "voxel_size": model.voxel_size,
		"existing_above_target": before > VxFineGrid.TARGET,
		"cut_cells": detail["cut_cells"], "panel_count": detail["panel_count"],
		"panels": _serializable_panels(detail["panels"]),
		"final_voxels": model.cell_count(),
	}
	# Recheck actual topology after the fine cuts rather than reuse the low
	# grid's report. Do not cosmetically repair or conceal pre-existing issues.
	var physical := VxIntegrity.physical_components(model)
	var rigid := VxIntegrity.rigid_components(model)
	model.quality_report["fine_catalog"]["floating_islands"] = physical["islands"]
	model.quality_report["fine_catalog"]["rig_islands"] = rigid["unanchored"]
	return model


static func _serializable_panels(panels: Dictionary) -> Dictionary:
	var result := {}
	for name_: String in panels:
		var p: Dictionary = panels[name_]
		var c: Vector3i = p["center"]
		var n: Vector3i = p["normal"]
		result[name_] = {"center": [c.x, c.y, c.z], "normal": [n.x, n.y, n.z],
			"cut_cells": p["cut_cells"]}
	return result
