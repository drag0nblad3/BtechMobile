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


## Check the authored mass before any subdivision, bevel or repair can hide
## gaps. Independent soldiers are intentional; disconnected limbs are not.
func test_support_source_assemblies_are_connected() -> void:
	for id: String in IDS:
		var data: Dictionary = JsonFile.read("res://data/voxels/assets/%s.json" % id)
		var m := VxModel.new()
		for material: Dictionary in data["materials"]:
			m._mat[material["name"]] = m.colors.size()
			m.colors.append(Color(material["color"]))
			m.roles.append(material.get("role", "armor"))
		for p: Dictionary in data["parts"]:
			m._add_part(p)
		check(m.errors.is_empty(), "%s source painter issues" % id)
		var squad: bool = data.get("asset_kind") in ["infantry", "battle_armor"]
		var occupied := {}
		for p: Dictionary in m.parts:
			var cells: Dictionary = p["cells"]
			if squad:
				check_eq(VxIntegrity.components(cells).size(), 1,
					"%s: %s has unsupported equipment or limbs" % [id, p["name"]])
			for c: Vector3i in cells:
				occupied[c] = true
		check_eq(VxIntegrity.components(occupied).size(), m.parts.size() if squad else 1,
			"%s: independent physical assemblies" % id)
		var n := int(data.get("subdivide", 1))
		check(occupied.size() * n * n * n <= VoxelAsset.MAX_VOXELS,
			"%s source geometry exceeds the pre-bevel budget" % id)
