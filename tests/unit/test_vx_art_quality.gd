extends TestCase
## Quality-pass regression: verify every editable silhouette pair, not just a
## hand-picked set of 'Mechs. Full 3x geometry is covered by existing tests.
const REVISION := "silhouette-and-weapon-clarity-20261121"


func test_every_shape_study_has_matching_detailed_contours_after_art_pass() -> void:
	var files: PackedStringArray = DirAccess.get_files_at("res://data/voxels")
	var pairs := 0
	for filename: String in files:
		if not filename.ends_with("_shape.json"):
			continue
		var id: String = filename.trim_suffix("_shape.json")
		var low: Dictionary = JsonFile.read("res://data/voxels/" + filename)
		var high_path := "res://data/voxels/" + id + ".json"
		check(FileAccess.file_exists(high_path), id + " must have detailed counterpart")
		if not FileAccess.file_exists(high_path):
			continue
		var high: Dictionary = JsonFile.read(high_path)
		if low.has("source") or not low.has("parts"):
			# Atlas/Jenner/Wolverine source manifests use the procedural pipeline.
			continue
		var lo: Dictionary = VxArtQuality.apply(low)
		var hi: Dictionary = VxArtQuality.apply(high)
		check_eq(String(lo.get("art_quality_revision", "")), REVISION, id + " art pass present")
		check_eq(String(hi.get("art_quality_revision", "")), REVISION, id + " detailed art pass")
		check(lo.get("exclusive_parts", false), id + " overlapping moving pieces prohibited")
		check(hi.get("exclusive_parts", false), id + " high-detail overlap prohibited")
		check_eq(lo.get("muzzles", {}), low.get("muzzles", {}), id + " muzzle positions unchanged")
		check_eq(hi.get("muzzles", {}), high.get("muzzles", {}), id + " fine muzzle positions unchanged")
		check_eq(lo.get("weapons", []), low.get("weapons", []), id + " weapon assignments unchanged")
		check_eq(lo.get("parts", []).size(), hi.get("parts", []).size(), id + " same articulated parts")
		for i in mini(lo["parts"].size(), hi["parts"].size()):
			var a: Dictionary = lo["parts"][i]
			var b: Dictionary = hi["parts"][i]
			check_eq(a["name"], b["name"], id + " matching part")
			if a.has("mirror"):
				continue
			check_eq(a.get("pivot", []), b.get("pivot", []), id + " pivot unchanged")
			var ash: Array = a.get("shapes", [])
			var bsh: Array = b.get("shapes", [])
			for k in mini(ash.size(), bsh.size()):
				if ash[k].has("loft") and ash[k]["loft"].get("axis", "y") == "y":
					check_eq(ash[k]["loft"], bsh[k].get("loft", {}),
						"%s/%s shape and detailed contour agree" % [id, a["name"]])
		pairs += 1
	check(pairs >= 140, "expect the full chassis catalog, not a partial subset")


func test_known_problematic_parts_have_clean_coarse_cell_ownership() -> void:
	for id in ["archer", "shadow_hawk", "awesome", "griffin", "thunderbolt",
			"king_crab", "scorpion", "viper", "raven", "shadow_cat"]:
		var low: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		low["subdivide"] = 1
		for p: Dictionary in low.get("parts", []):
			p.erase("detail")
		var m := VxModel.from_dict(low)
		check(m.errors.is_empty(), id + " coarse loader")
		var owned := {}
		for part: Dictionary in m.parts:
			for cell: Vector3i in part["cells"]:
				check(not owned.has(cell), id + " unique coarse cell ownership")
				owned[cell] = true
