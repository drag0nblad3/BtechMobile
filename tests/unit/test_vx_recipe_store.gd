extends TestCase
## Exercise actual byte offsets, logical paths and independent recipe reads.


func _write(path: String, data: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		check(false, "cannot write " + path)
		return
	file.store_string(data)
	file.close()


func test_indexed_voxel_catalog_and_legacy_paths() -> void:
	var root := "user://test_voxel_shards_%d" % Time.get_ticks_usec()
	var dir := root.path_join("_catalog")
	check_eq(DirAccess.make_dir_recursive_absolute(dir), OK)
	var a := '{"path":"alpha.json","recipe":{"id":"alpha","name":"Éclair","parts":[{"name":"ct"}]}}'
	var b := '{"path":"beta.json","recipe":{"source":"res://data/voxels/alpha.json","subdivide":2}}'
	var c := '{"path":"assets/tank.json","recipe":{"id":"tank","voxel_cap":50000}}'
	var prefix := "[\n"
	var middle := ",\n"
	var text := prefix + a + middle + b + middle + c + "\n]\n"
	var start_a := prefix.to_utf8_buffer().size()
	var start_b := (prefix + a + middle).to_utf8_buffer().size()
	var start_c := (prefix + a + middle + b + middle).to_utf8_buffer().size()
	var index := {"version": 1, "entries": {
		"alpha.json": ["models.json", start_a, a.to_utf8_buffer().size()],
		"beta.json": ["models.json", start_b, b.to_utf8_buffer().size()],
		"assets/tank.json": ["models.json", start_c, c.to_utf8_buffer().size()]}}
	_write(dir.path_join("models.json"), text)
	_write(dir.path_join("index.json"), JSON.stringify(index))
	_write(root.path_join("legacy.json"), '{"id":"legacy"}')
	var alpha := root.path_join("alpha.json")
	var beta := root.path_join("beta.json")
	var legacy := root.path_join("legacy.json")
	var tank := root.path_join("assets/tank.json")
	check(VxRecipeStore.exists(alpha, root))
	check(VxRecipeStore.exists(beta, root))
	check(VxRecipeStore.exists(legacy, root))
	check(VxRecipeStore.exists(tank, root))
	check(not VxRecipeStore.exists(root.path_join("missing.json"), root))
	check_eq(VxRecipeStore.paths(root, root), PackedStringArray([alpha, beta, legacy]))
	check_eq(VxRecipeStore.paths(root.path_join("assets"), root), PackedStringArray([tank]))
	var recipe: Variant = VxRecipeStore.read(alpha, root)
	check(recipe is Dictionary, "recipe must be a dictionary")
	if recipe is Dictionary:
		check_eq(recipe["name"], "Éclair")
		recipe["parts"][0]["name"] = "mutated"
		check_eq(VxRecipeStore.read(alpha, root)["parts"][0]["name"], "ct")
	check_eq(VxRecipeStore.read(beta, root)["source"], "res://data/voxels/alpha.json")
	check_eq(VxRecipeStore.read(tank, root)["voxel_cap"], 50000)
	check_eq(VxRecipeStore.read(legacy, root)["id"], "legacy")
	# An unpacked authoring override is authoritative during phased migration.
	_write(alpha, '{"id":"override"}')
	check_eq(VxRecipeStore.read(alpha, root)["id"], "override")
	check_eq(VxRecipeStore.paths(root, root), PackedStringArray([alpha, beta, legacy]))
	for path in [alpha, legacy, dir.path_join("models.json"), dir.path_join("index.json"), dir, root]:
		check_eq(DirAccess.remove_absolute(path), OK)
