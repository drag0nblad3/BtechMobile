extends TestCase
## Battlefield support graphics are hard-capped, independent of hit tables.
const IDS := [
	"savior_repair_vehicle", "tracked_tank", "lrm_carrier", "wheeled_apc",
	"wheeled_supply_truck", "hover_scout", "hover_tank", "attack_vtol",
	"transport_vtol", "artillery_carrier", "field_emplacement",
	"missile_emplacement", "infantry_rifles", "infantry_jump",
	"infantry_motorized", "battle_armor_elementals",
]


func test_each_asset_has_strict_fifty_thousand_voxel_ceiling() -> void:
	for id: String in IDS:
		var data: Dictionary = JsonFile.read("res://data/voxels/assets/%s.json" % id)
		check_eq(int(data.get("voxel_cap", 0)), 50000)
		var m := VoxelAsset.model_from_dict(data)
		check(m.errors.is_empty(), "%s painter issues: %s" % [id, m.errors])
		check(m.cell_count() > 100, "%s should contain geometry" % id)
		check(m.cell_count() <= VoxelAsset.MAX_VOXELS, "%s exceeded cap: %d" % [id, m.cell_count()])


func test_asset_selection_uses_rules_kind_and_motive() -> void:
	for id in ["test_tank", "test_hover", "test_apc", "test_vtol",
			"test_foot", "test_jump", "test_elementals", "test_lrm_carrier"]:
		var d: Dictionary = JsonFile.read("res://tests/fixtures/assets/%s.json" % id)
		var def := UnitDef.from_dict(d)
		var recipe := VoxelAsset.recipe_for(def)
		check(recipe != "", "%s needs a matching voxel recipe" % id)
		check(FileAccess.file_exists(VoxelAsset.DIR + recipe + ".json"),
			"%s recipe exists: %s" % [id, recipe])


func test_rejects_asset_over_cap() -> void:
	var d: Dictionary = JsonFile.read("res://data/voxels/assets/tracked_tank.json")
	d["voxel_cap"] = 50001
	var m := VoxelAsset.model_from_dict(d)
	check(not m.errors.is_empty(), "a recipe may not raise the hard cap")
