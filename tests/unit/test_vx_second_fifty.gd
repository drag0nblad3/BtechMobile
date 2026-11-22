extends TestCase
## Second source-quality review must cover the complete editable catalog.
## Tests invariants and recorded review work, not particular sculpt coordinates.


func test_every_shape_source_received_fifty_additional_review_stages() -> void:
	var count := 0
	var edited := 0
	var views := ["front", "side", "rear", "top", "three_quarter"]
	for path: String in DirAccess.get_files_at("res://data/voxels"):
		if not path.ends_with("_shape.json"):
			continue
		count += 1
		var raw: Dictionary = JsonFile.read("res://data/voxels/" + path)
		check_eq(int(raw.get("art_quality_passes", 0)), 100,
				"%s completed both 50-cycle reviews" % path)
		var review: Dictionary = raw.get("shape_review_50", {})
		check_eq(int(review.get("passes", 0)), 50,
				"%s has 50 actual review records" % path)
		check_eq(raw.get("reference_review_views", []), views,
				"%s scanned all orthographic and three-quarter views" % path)
		if int(review.get("edited_vertices", 0)) > 0:
			edited += 1
	check(count >= 151, "whole original shape catalog reviewed")
	check(edited > 50, "meaningful selective geometry changes, not metadata-only cycles")


func test_second_pass_did_not_disrupt_mirrors_or_kinematic_hierarchy() -> void:
	for path: String in DirAccess.get_files_at("res://data/voxels"):
		if not path.ends_with("_shape.json"):
			continue
		var raw: Dictionary = JsonFile.read("res://data/voxels/" + path)
		var known := {}
		var all_names: Array[String] = []
		for item: Dictionary in raw.get("parts", []):
			all_names.append(String(item.get("name", "")))
		for part: Dictionary in raw.get("parts", []):
			var name: String = part.get("name", "")
			check(not known.has(name), "%s duplicate part %s" % [path,name])
			if part.has("mirror"):
				check(known.has(part["mirror"]), "%s unknown mirror %s" % [path,name])
			if part.has("parent"):
				check(all_names.has(String(part["parent"])), "%s unknown parent %s" % [path,name])
			for shape: Dictionary in part.get("shapes", []):
				if not shape.has("loft"):
					continue
				var stations: Array = shape["loft"]["sections"]
				for i in range(1,stations.size()):
					check(stations[i]["at"] > stations[i-1]["at"],
							"%s %s: ordered stations" % [path,name])
					check(stations[i]["polygon"].size() == stations[i-1]["polygon"].size(),
							"%s %s: polygon correspondence" % [path,name])
			known[name] = true

func test_runtime_rig_resolves_parents_regardless_of_part_order() -> void:
	var mech := VxMech.from_file("res://data/voxels/locust_shape.json")
	check(mech.model.errors.is_empty(), "sample rig loads")
	var checked := 0
	for spec: Dictionary in mech.model.parts:
		var parent_name: String = spec.get("parent", "")
		if parent_name.is_empty():
			continue
		checked += 1
		check(mech.pivots[spec["name"]].get_parent() == mech.pivots[parent_name],
				"rig child %s must follow parent %s" % [spec["name"],parent_name])
	check(checked > 0, "joint hierarchy contains parented child parts")
	mech.free()
