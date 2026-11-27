extends SceneTree
## Name-blind multi-angle silhouette and connected-mass audit for every
## editable low-detail BattleMech. Run (no APK/rendering required):
## godot --headless --import
## godot --headless -s tools/voxel_multiangle_audit.gd -- /tmp/voxel_audit.json
## Front 55%, side 28%, oblique 12%, top 5%.

# Independent initial sculpts must also participate in the blind, multi-angle
# catalog audit; _shape-only selection previously overlooked these new models.
const SOURCE_CHASSIS := [
    "solitaire", "vulture_mk_iv", "hellhound_conjurer", "koshi_standard",
    "hawkwolf_hwk4f", "black_hawk_standard", "dominator"
]


func _init() -> void:
	var output := "user://voxel_multiangle_audit.json"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	var fingerprints := {}
	var diagnostics := {}
	var paths := VxRecipeStore.files("res://data/voxels")
	paths.sort()
	for filename: String in paths:
		var is_shape := filename.ends_with("_shape.json")
		var is_source := filename.trim_suffix(".json") in SOURCE_CHASSIS
		if not is_shape and not is_source:
			continue
		var id := filename.trim_suffix("_shape.json") if is_shape else filename.trim_suffix(".json")
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
			"weak_joints": weak_joints, "faults": inspection["faults"],
			"proportions": _proportions(m)}

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

## Diagnostic only, not a universal geometry correction.
## Measure actual occupied parts, not author-specific sample positions.
static func _proportions(m: VxModel) -> Dictionary:
	var low := Vector3i(100000, 100000, 100000)
	var high := Vector3i(-100000, -100000, -100000)
	var body_lo := Vector3i(100000, 100000, 100000)
	var body_hi := Vector3i(-100000, -100000, -100000)
	var torso_z: Array[int] = []
	var side_pixels := {}
	var torso_cells := 0
	var leg_pivot := 0.0
	for part: Dictionary in m.parts:
		var part_name: String = part["name"]
		if part_name == "ll":
			leg_pivot = part["pivot"].y
		var is_torso: bool = part_name in ["ct", "lt", "rt"]
		for c: Vector3i in part["cells"]:
			for axis in 3:
				low[axis] = mini(low[axis], c[axis])
				high[axis] = maxi(high[axis], c[axis])
			if is_torso:
				torso_cells += 1
				torso_z.append(c.z)
				side_pixels[Vector2i(c.z, c.y)] = true
				for axis in 3:
					body_lo[axis] = mini(body_lo[axis], c[axis])
					body_hi[axis] = maxi(body_hi[axis], c[axis])
	if torso_z.is_empty() or high.y <= low.y:
		return {}
	torso_z.sort()
	var q05: int = torso_z[floori(float(torso_z.size() - 1) * 0.05)]
	var q95: int = torso_z[ceili(float(torso_z.size() - 1) * 0.95)]
	var h: float = float(high.y - low.y + 1)
	var body_h: float = float(body_hi.y - body_lo.y + 1)
	var body_d: float = float(body_hi.z - body_lo.z + 1)
	var body_w: float = float(body_hi.x - body_lo.x + 1)
	var robust_depth: float = float(q95 - q05 + 1)
	var side_area: float = float(side_pixels.size())
	var side_envelope: float = body_d * body_h
	var leg_fraction: float = (leg_pivot - float(low.y)) / h
	var depth_fraction: float = robust_depth / h
	var side_fill: float = side_area / maxf(1.0, side_envelope)
	var squat_risk: float = maxf(0.0, depth_fraction - 0.30) * 2.5 \
			+ maxf(0.0, 0.52 - leg_fraction) * 2.0 \
			+ maxf(0.0, side_fill - 0.60) * 0.8
	return {
		"bounds": {"min": [low.x, low.y, low.z],
			"max": [high.x, high.y, high.z]},
		"torso_bounds": {"min": [body_lo.x, body_lo.y, body_lo.z],
			"max": [body_hi.x, body_hi.y, body_hi.z]},
		"height": h, "torso_depth": body_d, "torso_width": body_w,
		"torso_height": body_h, "torso_robust_depth": robust_depth,
		"torso_depth_height": snappedf(depth_fraction, 0.001),
		"hip_height_fraction": snappedf(leg_fraction, 0.001),
		"torso_side_fill": snappedf(side_fill, 0.001),
		"torso_cells": torso_cells,
		"proportion_priority_score": snappedf(squat_risk, 0.001)
	}
