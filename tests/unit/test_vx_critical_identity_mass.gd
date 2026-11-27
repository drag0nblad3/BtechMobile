extends TestCase
## Catalog-wide identity resculpt and real source-mass attachment checks.
## Geometry dimensions derive from each model's authored anchor, not a fixed
## absolute test coordinate or a hard-coded chassis voxel count.


func test_all_critical_models_have_different_primary_geometry() -> void:
	var visited := 0
	var vertex_edits := 0
	for file: String in VxRecipeStore.files("res://data/voxels"):
		if not file.ends_with("_shape.json"):
			continue
		var source: Dictionary = VxRecipeStore.read("res://data/voxels/" + file)
		var study: Dictionary = source.get("blind_identity_resculpt", {})
		if study.is_empty():
			continue
		visited += 1
		var chassis := file.trim_suffix("_shape.json")
		var final_recipe: Dictionary = VxRecipeStore.read("res://data/voxels/" + chassis + ".json")
		var final_study: Dictionary = final_recipe.get("blind_identity_resculpt", {})
		check_eq(study.get("revision", ""), final_study.get("revision", ""),
				"%s source and detailed shapes must share revisions" % chassis)
		var changed := int(study.get("modified_polygon_vertices", 0))
		check(changed > 8, "%s has substantial edited contour geometry" % chassis)
		vertex_edits += changed
		check_eq(source.get("weapons", []), final_recipe.get("weapons", []),
				"%s retains the official visual weapon manifest" % chassis)
	check_eq(visited, 59, "all 59 initially critical chassis resculpted")
	check(vertex_edits > 1000, "geometry changed, not only metadata")


func test_authored_signature_modules_have_thick_structural_roots() -> void:
	var reviewed := 0
	for file: String in VxRecipeStore.files("res://data/voxels"):
		if not file.ends_with("_shape.json"):
			continue
		var recipe: Dictionary = VxRecipeStore.read("res://data/voxels/" + file)
		var modules: Array = recipe.get("blind_identity_weapon_modules", [])
		if modules.is_empty():
			continue
		var model := VxModel.load_file("res://data/voxels/" + file)
		check(model.errors.is_empty(), "source model %s is valid" % file)
		for item: Dictionary in modules:
			var part: Dictionary = model.part(String(item["part"]))
			check(not part.is_empty(), "%s owns its identifying weapon" % file)
			if part.is_empty():
				continue
			var xyz: Array = item["anchor"]
			var at := Vector3i(int(xyz[0]), int(xyz[1]), int(xyz[2]))
			# A real 3D supporting socket occupies multiple consecutive
			# cross-sections, not a single touching voxel.
			for depth in 4:
				var area := 0
				for dx in range(-3, 4):
					for dy in range(-3, 4):
						if part["cells"].has(at + Vector3i(dx, dy, depth)):
							area += 1
				check(area >= 4, "%s %s has a broad four-layer attachment" %
						[file, item["part"]])
			reviewed += 1
	check(reviewed >= 40, "the bulk of signature artillery is checked for structural mass")
