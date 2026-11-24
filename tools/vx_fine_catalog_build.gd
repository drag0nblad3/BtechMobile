extends SceneTree
## Build real occupied-cell data for every model, optionally in parallel shards.
## godot --headless -s tools/vx_fine_catalog_build.gd -- /tmp/fine 0 8

func _initialize() -> void:
	call_deferred("_build_catalog")


func _build_catalog() -> void:
	var args := OS.get_cmdline_user_args()
	var output: String = args[0] if not args.is_empty() else "/tmp/vx-fine"
	var shard := int(args[1]) if args.size() > 1 else 0
	var shards := int(args[2]) if args.size() > 2 else 1
	if shards < 1 or shard < 0 or shard >= shards:
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		printerr("FINE_ERROR|cannot create " + output)
		quit(1)
		return
	var paths := VxFineCatalog.paths()
	var records := {}
	var failed := 0
	var warnings := 0
	for i in paths.size():
		if i % shards != shard:
			continue
		var path: String = paths[i]
		var name_: String = path.get_file().get_basename()
		var model := VxFineCatalog.build(path)
		var info: Dictionary = model.quality_report.get("fine_catalog", {}).duplicate(true)
		info["errors"] = Array(model.errors)
		if not model.errors.is_empty() or model.cell_count() <= 0 or info.is_empty():
			failed += 1
			printerr("FINE_ERROR|%s|%s" % [name_, model.errors])
		else:
			var regressions := int(info["floating_islands"]) > int(info["source_floating_islands"]) or int(info["rig_islands"]) > int(info["source_rig_islands"])
			var over_budget := not bool(info["existing_above_target"]) and model.cell_count() > VxFineGrid.TARGET
			if regressions or over_budget:
				failed += 1
				printerr("FINE_ERROR|%s|topology regression or over budget" % name_)
			if bool(info["below_target"]) or bool(info["missing_detail"]) or int(info["floating_islands"]) > 0 or int(info["rig_islands"]) > 0:
				warnings += 1
				print("FINE_REVIEW|%s|below_target=%s|missing_detail=%s|islands=%d|rig=%d" % [
					name_, info["below_target"], info["missing_detail"], info["floating_islands"], info["rig_islands"]])
			var file := FileAccess.open_compressed(output.path_join(name_ + ".vx150"),
				FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
			if file == null:
				failed += 1
				printerr("FINE_ERROR|cannot write " + name_)
			else:
				file.store_var(_payload(model), false)
				file.close()
			print("FINE_MODEL|%s|%d|%d|%d|%d" % [name_, model.cell_count(),
				info["panel_count"], info["floating_islands"], info["rig_islands"]])
		records[name_] = info
	var report := FileAccess.open(output.path_join("report.json"), FileAccess.WRITE)
	if report == null:
		quit(1)
		return
	report.store_string(JSON.stringify({"catalog_size": paths.size(), "shard": shard,
		"shards": shards, "failed": failed, "warnings": warnings, "models": records}, "  "))
	report.close()
	print("FINE_CATALOG|%d/%d|models=%d|failed=%d|warnings=%d" % [shard, shards, records.size(), failed, warnings])
	quit(1 if failed > 0 or paths.is_empty() else 0)


## Native Variant payload, not a count-only manifest. Contains every occupied
## coordinate, material index, hierarchy, pivot, muzzle and actual voxel pitch.
func _payload(m: VxModel) -> Dictionary:
	return {"format": 1, "id": m.id, "name": m.name, "unit": m.unit_id,
		"voxel_size": m.voxel_size, "detail": m.detail, "colors": m.colors,
		"roles": m.roles, "materials": m._mat, "parts": m.parts,
		"muzzles": m.muzzles, "jets": m.jets, "weapons": m.weapons,
		"legs": m.legs, "punch": m.can_punch, "ready_arm": m.ready_arm,
		"ready_roll": m.ready_roll, "report": m.quality_report.get("fine_catalog", {})}
