extends TestCase
## Every voxel 'Mech file is well-formed: parts name a hit location (or mirror
## a part that does) and together cover all eight. Cheap JSON check; the art
## itself is reviewed by eye, not pinned by tests.


func test_every_voxel_mech_covers_every_location() -> void:
	var flip := {"LA": "RA", "RA": "LA", "LT": "RT", "RT": "LT", "LL": "RL", "RL": "LL"}
	var files := 0
	for f in DirAccess.get_files_at("res://data/voxels"):
		if not f.ends_with(".json"):
			continue
		files += 1
		var d: Dictionary = JsonFile.read("res://data/voxels/" + f)
		var loc_of := {}
		for p: Dictionary in d.get("parts", []):
			if p.has("loc"):
				loc_of[p["name"]] = p["loc"]
		var seen := {}
		for p: Dictionary in d.get("parts", []):
			var loc: String = p.get("loc", "")
			if loc == "" and p.has("mirror"):
				loc = flip.get(loc_of.get(p["mirror"], ""), loc_of.get(p["mirror"], ""))
			check(Location.from_code(loc) >= 0, "%s part %s has no location" % [f, p.get("name")])
			seen[loc] = true
		if d.has("parts") and not d["parts"].is_empty() and d["parts"][0].has("loc"):
			for loc in Location.COUNT:
				check(seen.has(Location.code(loc)), "%s missing %s" % [f, Location.code(loc)])
	check(files > 100, "voxel catalog found")
