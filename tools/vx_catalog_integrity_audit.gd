extends SceneTree
## Headless full-catalog mesh-source topology audit.
##   godot --headless -s tools/vx_catalog_integrity_audit.gd -- /tmp/audit.json
##   godot --headless -s tools/vx_catalog_integrity_audit.gd -- /tmp/fine.json --high
## Coarse mode audits all 151 editable silhouettes + 16 archetypal assets.
## Fine mode audits every game-resolution recipe + all full-detail assets.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if not args.is_empty() else "/tmp/vx_catalog_integrity.json"
	var high := args.has("--high")
	var mode := "fine" if high else "shape"
	var report := {"mode": mode, "mechs": {}, "assets": {}, "warnings": [],
			"totals": {"mechs": 0, "assets": 0, "skipped": 0,
				"before": 0, "after": 0, "rejoined": 0,
				"joint_contacts": 0, "added": 0, "empty_parts": 0, "rig_islands": 0, "floating_islands": 0,
				"weak_joint_contacts": 0, "mass_reinforced": 0}}
	for file: String in VxRecipeStore.files("res://data/voxels"):
		if not file.ends_with(".json"):
			continue
		if high == file.ends_with("_shape.json"):
			continue
		var path := "res://data/voxels/" + file
		var raw: Dictionary = VxRecipeStore.read(path)
		if not high and raw.get("parts", []).is_empty():
			continue
		var model: VxModel
		if high:
			model = VxModel.load_file(path)
		else:
			raw["subdivide"] = 1
			raw["voxelize_lofts"] = false
			model = VxModel.from_dict(raw)
		var info: Dictionary = model.quality_report.duplicate()
		info["voxels"] = model.cell_count()
		info["errors"] = Array(model.errors)
		if info.is_empty() or not info.has("before"):
			report["totals"]["skipped"] += 1
		else:
			_sum(report["totals"], info)
		report["mechs"][file.get_basename()] = info
		report["totals"]["mechs"] += 1
		if not model.errors.is_empty():
			report["warnings"].append("%s: %s" % [file, ", ".join(model.errors)])
	for file: String in VxRecipeStore.files("res://data/voxels/assets"):
		if not file.ends_with(".json"):
			continue
		var raw: Dictionary = VxRecipeStore.read("res://data/voxels/assets/" + file)
		if not high:
			raw["subdivide"] = 1
		var model := VoxelAsset.model_from_dict(raw)
		var info: Dictionary = model.quality_report.duplicate()
		info["voxels"] = model.cell_count()
		info["errors"] = Array(model.errors)
		if not info.has("before"):
			report["totals"]["skipped"] += 1
		else:
			_sum(report["totals"], info)
		report["assets"][file.get_basename()] = info
		report["totals"]["assets"] += 1
		if not model.errors.is_empty():
			report["warnings"].append("%s: %s" % [file, ", ".join(model.errors)])
	var data := JSON.stringify(report, "  ")
	var target := FileAccess.open(output, FileAccess.WRITE)
	if target == null:
		printerr("VOXEL_AUDIT_ERROR: Cannot write " + output)
		quit(1)
		return
	target.store_string(data + "\n")
	target.close()
	print("VOXEL_INTEGRITY|%s|mechs=%d|assets=%d|before=%d|after=%d|rejoined=%d|joint_contacts=%d|added=%d|rig_islands=%d|floating_islands=%d|weak_joint_contacts=%d|mass_reinforced=%d|skipped=%d|warnings=%d" % [
			mode, report["totals"]["mechs"], report["totals"]["assets"],
			report["totals"]["before"], report["totals"]["after"],
			report["totals"]["rejoined"], report["totals"]["joint_contacts"],
			report["totals"]["added"], report["totals"]["rig_islands"], report["totals"]["floating_islands"], report["totals"]["weak_joint_contacts"], report["totals"]["mass_reinforced"], report["totals"]["skipped"],
			report["warnings"].size()])
	quit(1 if not report["warnings"].is_empty() else 0)


func _sum(totals: Dictionary, info: Dictionary) -> void:
	for key in ["before", "after", "rejoined", "joint_contacts", "added", "empty_parts", "rig_islands", "floating_islands", "weak_joint_contacts", "mass_reinforced"]:
		totals[key] = int(totals.get(key, 0)) + int(info.get(key, 0))
