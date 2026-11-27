extends TestCase
## Asset naming must not silently turn supported BattleMechs into placeholders.

func test_renamed_chassis_resolve() -> void:
	var db := designs()
	for stem: String in ["wolverine", "atlas", "jenner"]:
		var count := 0
		for d: UnitDef in db.sorted_defs():
			if d.sprite != stem:
				continue
			count += 1
			check(VxRecipeStore.exists(UnitVoxels.model_path(d)), d.id + " must resolve a model")
		check(count > 0, "catalog contains " + stem)


func test_catalog_suffixed_models_resolve() -> void:
	var checked := 0
	for d: UnitDef in designs().sorted_defs():
		if not VxRecipeStore.exists(UnitVoxels.PATH % (d.sprite + "_voxel")) and not VxRecipeStore.exists(UnitVoxels.PATH % (d.id + "_voxel")):
			continue
		checked += 1
		check(VxRecipeStore.exists(UnitVoxels.model_path(d)), "unresolved voxel model: " + d.id)
	check(checked > 0, "catalog has suffixed model files")
