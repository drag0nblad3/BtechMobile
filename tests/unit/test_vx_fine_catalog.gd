extends TestCase
## Fine-detail tier preserves the base rig and real negative space.

func test_noninteger_grid_expansion_preserves_holes_and_mirrors() -> void:
	var m := VxModel.new()
	m.voxel_size = 0.05
	m.parts = [{"name": "left", "pivot": Vector3(-2, 3, 0), "cells": {
		Vector3i(-2, 0, 0): 0, Vector3i(-2, 0, 2): 0}},
		{"name": "right", "pivot": Vector3(2, 3, 0), "cells": {
		Vector3i(1, 0, 0): 0, Vector3i(1, 0, 2): 0}}]
	m.muzzles = {Location.LA: [Vector3(-2, 0, 1)]}
	var expected := VxFineGrid.count_at(m, 1.7)
	VxFineGrid.expand(m, 1.7)
	check_eq(m.cell_count(), expected, "count matches materialized occupancy")
	check(is_equal_approx(m.voxel_size * 1.7, 0.05), "world pitch")
	check(m.parts[0]["pivot"].is_equal_approx(Vector3(-2, 3, 0) * 1.7), "pivot")
	check(m.muzzles[Location.LA][0].is_equal_approx(Vector3(-2, 0, 1) * 1.7), "muzzle")
	for c: Vector3i in m.parts[0]["cells"]:
		check(m.parts[1]["cells"].has(Vector3i(-c.x - 1, c.y, c.z)), "mirror preserved")
		check(c.z < 2 or c.z >= 3, "authored opening remains empty")


func test_backed_fine_panel_cuts_only_real_armor() -> void:
	var m := VxModel.new()
	m._mat = {"armor": 0, "gun": 1}
	m.colors = PackedColorArray([Color.WHITE, Color.BLACK])
	m.roles = ["armor", "armor"]
	var cells := {}
	for x in range(-5, 5):
		for y in range(10, 20):
			for z in range(-4, 5):
				cells[Vector3i(x, y, z)] = 0
	var gun := Vector3i(0, 15, -4)
	cells[gun] = 1
	m.parts = [{"name": "ct", "pivot": Vector3.ZERO, "cells": cells}]
	var count := m.cell_count()
	var result := VxFineDetail.apply(m)
	check(int(result["cut_cells"]) >= 6, "supported details carved")
	check_eq(m.cell_count(), count - int(result["cut_cells"]))
	check_eq(cells[gun], 1, "weapon untouched")
	check_eq(VxIntegrity.components(cells).size(), 1, "real plate stays connected")
	check_eq(m.roles.back(), "armor", "recess remains damageable armor")


func test_catalog_has_one_fine_entry_per_shape_and_variant() -> void:
	var paths := VxFineCatalog.paths()
	check(paths.size() >= 300, "catalog includes current shipped recipes")
	for file: String in VxRecipeStore.files(VxFineCatalog.ROOT):
		if file.ends_with(".json"):
			check(paths.has(VxFineCatalog.canonical(VxFineCatalog.ROOT + file)), file)
	var variant := VxFineCatalog.recipe("res://data/voxels/spider_sdr10k.json")
	check(not variant.get("parts", []).is_empty(), "resolve nested source manifests")
	check_eq(variant.get("unit", ""), "spider_sdr10k")


func test_hunchback_builds_real_fine_tier_without_changing_battle_recipe() -> void:
	var path := "res://data/voxels/hunchback.json"
	var base := VxModel.load_file(path)
	var original := base.cell_count()
	var high := VxFineCatalog.build(path)
	check(high.errors.is_empty(), str(high.errors))
	check(high.cell_count() >= VxFineGrid.MIN_FINE and high.cell_count() <= VxFineGrid.TARGET,
		"real occupied target range: %d" % high.cell_count())
	check_eq(base.cell_count(), original, "independent source")
	check(high.voxel_size < base.voxel_size, "smaller cells, not inflated dimensions")
	for p: Dictionary in base.parts:
		var q := high.part(p["name"])
		check((p["pivot"] * base.voxel_size).is_equal_approx(q["pivot"] * high.voxel_size),
			"world rig stays fixed: " + str(p["name"]))
