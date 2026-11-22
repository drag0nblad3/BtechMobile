extends SceneTree
## Run: godot --headless --path . --script res://tools/audit_voxel_parts.gd
## Reads actual coarse voxel occupancy, checks *every part* and its parent.
## Writes report to user://voxel_part_connectivity_report.json.
const DIRECTORY := "res://data/voxels/"
const SUPPORT := "res://data/voxels/assets/"


func _initialize() -> void:
	var report := {"models": [], "summary": {
		"scanned": 0, "parts": 0, "loose_islands": 0, "parent_gaps": 0,
		"empty_parts": 0, "source_errors": 0, "support_models": 0}}
	_scan_mechs(report)
	_scan_support(report)
	var output := "user://voxel_part_connectivity_report.json"
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("VOXEL_PART_AUDIT_SUMMARY ", JSON.stringify(report["summary"]))
	print("VOXEL_PART_AUDIT_REPORT ", ProjectSettings.globalize_path(output))
	for entry: Dictionary in report["models"]:
		if int(entry["loose_islands"]) > 0 or int(entry["parent_gaps"]) > 0:
			print("VOXEL_PART_AUDIT_WARN ", entry["model"],
				" islands=", entry["loose_islands"], " parent_gaps=", entry["parent_gaps"])
	quit()


func _scan_mechs(report: Dictionary) -> void:
	var dir := DirAccess.open(DIRECTORY)
	if dir == null:
		push_error("Cannot open mech voxel source directory")
		return
	var names := dir.get_files()
	names.sort()
	for name: String in names:
		if not name.ends_with("_shape.json"):
			continue
		var data: Variant = JsonFile.read(DIRECTORY + name)
		if data is Dictionary:
			_add(report, VxModel.from_dict(data))


func _scan_support(report: Dictionary) -> void:
	var dir := DirAccess.open(SUPPORT)
	if dir == null:
		return
	var names := dir.get_files()
	names.sort()
	for name: String in names:
		if not name.ends_with(".json"):
			continue
		var data: Variant = JsonFile.read(SUPPORT + name)
		if data is Dictionary:
			# Audits coarse authored occupancy, without 2x subdivision.
			var coarse: Dictionary = data.duplicate(true)
			coarse["subdivide"] = 1
			var model := VxModel.new()
			model.id = String(coarse.get("id", name))
			for material: Dictionary in coarse.get("materials", []):
				model._mat[material["name"]] = model.colors.size()
				model.colors.append(Color(material["color"]))
				model.roles.append(material.get("role", "armor"))
			for part: Dictionary in coarse.get("parts", []):
				model._add_part(part)
			_add(report, model)
			report["summary"]["support_models"] += 1


func _add(report: Dictionary, model: VxModel) -> void:
	var entry := VxPartConnectivity.audit(model)
	report["models"].append(entry)
	var summary: Dictionary = report["summary"]
	summary["scanned"] += 1
	summary["parts"] += int(entry["part_count"])
	summary["loose_islands"] += int(entry["loose_islands"])
	summary["parent_gaps"] += int(entry["parent_gaps"])
	summary["empty_parts"] += int(entry["empty_parts"])
	summary["source_errors"] += entry["model_errors"].size()
