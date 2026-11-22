extends SceneTree
## Name-blind multi-angle silhouette and connected-mass audit for every
## editable low-detail BattleMech. Run (no APK/rendering required):
## godot --headless --import
## godot --headless -s tools/voxel_multiangle_audit.gd -- /tmp/voxel_audit.json
## Front 55%, side 28%, oblique 12%, top 5%.

func _init() -> void:
	var output := "user://voxel_multiangle_audit.json"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	var fingerprints := {}
	var diagnostics := {}
	var paths := DirAccess.get_files_at("res://data/voxels")
	paths.sort()
	for filename: String in paths:
		if not filename.ends_with("_shape.json"):
			continue
		var id := filename.trim_suffix("_shape.json")
		var m := VxModel.load_file("res://data/voxels/" + filename)
		fingerprints[id] = VxSilhouette.signature(m)
		var inspection := VxConnectivity.audit(m)
		var islands := 0
		var weak_joints := 0
		for issue: Dictionary in inspection["faults"]:
			if issue["type"] == "island":
				islands += 1
			elif issue["type"] == "weak_joint":
				weak_joints += 1
		diagnostics[id] = {
			"cells": m.cell_count(), "island_parts": islands,
			"weak_joints": weak_joints, "faults": inspection["faults"]}

	var result := {"version": 1,
		"weights": VxSilhouette.WEIGHTS.duplicate(true),
		"views": VxSilhouette.VIEWS.duplicate(),
		"count": fingerprints.size(),
		"models": {},
		"total_island_parts": 0, "total_weak_joints": 0,
		"confusion_pairs": []}
	var ids: Array = fingerprints.keys()
	ids.sort()
	var pairs: Array[Dictionary] = []
	for id: String in ids:
		var record: Dictionary = diagnostics[id]
		var guesses := VxSilhouette.closest(id, fingerprints, 3)
		record["blind_guesses"] = guesses
		result["models"][id] = record
		result["total_island_parts"] += int(record["island_parts"])
		result["total_weak_joints"] += int(record["weak_joints"])
		if not guesses.is_empty() and id < String(guesses[0]["id"]):
			pairs.append({"a": id, "b": guesses[0]["id"],
				"similarity": guesses[0]["similarity"]})
	pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["similarity"]) > float(b["similarity"]))
	pairs.resize(mini(30, pairs.size()))
	result["confusion_pairs"] = pairs

	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		printerr("Cannot write multi-angle audit at: " + output)
		quit(1)
		return
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	print("MULTIANGLE_AUDIT|%s|models=%d|island_parts=%d|weak_joints=%d" % [
		output, fingerprints.size(), result["total_island_parts"],
		result["total_weak_joints"]])
	quit(0)
