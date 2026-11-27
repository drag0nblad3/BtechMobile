extends TestCase
## Distinct official combat-vehicle and battle-armor graphics; hard 50k occupancy cap.

const VEHICLES := ["behemoth_heavy_tank","bulldog_medium_tank","condor_heavy_hover_tank","demolisher_heavy_tank_clan","demolisher_heavy_tank_mk_i","drillson_heavy_hover_tank","galleon_light_tank_gal_100","hetzer_wheeled_assault_gun","j_edgar_light_hover_tank","lrm_carrier","lrm_carrier_c","manticore_heavy_tank","patton_tank","pegasus_scout_hover_tank","pike_support_vehicle","pike_support_vehicle_clan","schrek_ppc_carrier","skulker_wheeled_scout_tank","srm_carrier","srm_carrier_c","vedette_medium_tank","von_luckner_heavy_tank_vnl_k65n"]
const BATTLE_ARMOR := ["elemental_ba_ap_gauss","elemental_ba_flamer","elemental_ba_laser","elemental_ba_mg","is_standard_ba_flamer","is_standard_ba_laser","is_standard_ba_mg"]


func test_all_vehicle_records_have_individual_fifty_pass_voxel_models() -> void:
	for id: String in VEHICLES:
		var path := "res://data/voxels/vehicles/%s.json" % id
		check(VxRecipeStore.exists(path), id + " has a distinct vehicle sculpt")
		if not VxRecipeStore.exists(path):
			continue
		var d: Dictionary = VxRecipeStore.read(path)
		check_eq(d.get("official_unit", ""), id, id + " backed by official sheet")
		check_eq(int(d.get("voxel_cap", 0)), 50000, id + " strict cap")
		check_eq(int(d.get("art_quality_passes", 0)), 50, id + " 50 source edits")
		check(int(d.get("geometry_edits", 0)) > 500, id + " actual geometry refinements")
		check(String(d.get("signature", "")).length() > 15, id + " recognisable weapon/silhouette")
		check_eq(d.get("vehicle_shape_revision", ""), "unit-specific-50-cycle-20261122")
		var m := VoxelAsset.model_from_dict(d)
		check(m.errors.is_empty(), "%s geometry errors: %s" % [id, m.errors])
		check(m.cell_count() > 500, id + " has solid vehicle geometry")
		check(m.cell_count() <= 50000, "%s exceeded occupied voxel cap: %d" % [id, m.cell_count()])


func test_all_record_sheet_battle_armor_have_distinct_squads_and_weapons() -> void:
	for id: String in BATTLE_ARMOR:
		var path := "res://data/voxels/battle_armor/%s.json" % id
		check(VxRecipeStore.exists(path), id + " squad recipe")
		if not VxRecipeStore.exists(path):
			continue
		var d: Dictionary = VxRecipeStore.read(path)
		check_eq(d.get("official_unit", ""), id)
		check_eq(int(d.get("voxel_cap", 0)), 50000)
		check_eq(int(d.get("art_quality_passes", 0)), 50)
		check(int(d.get("geometry_edits", 0)) > 0, id + " fifty actual edits")
		var expected := "laser"
		if id.contains("gauss"):
			expected = "gauss"
		elif id.contains("flamer"):
			expected = "flamer"
		elif id.ends_with("_mg"):
			expected = "mg"
		check_eq(String(d.get("weapon_kind", "")), expected,
			id + " distinctive anti-personnel weapon")
		check_eq(d["parts"].size(), 4 if id.begins_with("is_standard") else 5,
			id + " squad silhouette has official trooper count")
		var model := VoxelAsset.model_from_dict(d)
		check(model.errors.is_empty(), "%s errors: %s" % [id, model.errors])
		check(model.cell_count() <= 50000, id + " squad under voxel cap")


## Audit coarse authored geometry independently of runtime repair.
func test_record_support_source_assemblies_are_connected() -> void:
	for id: String in VEHICLES:
		_check_source_assembly("vehicles", id, 1)
	for id: String in BATTLE_ARMOR:
		_check_source_assembly("battle_armor", id, 4 if id.begins_with("is_standard") else 5)


func _check_source_assembly(folder: String, id: String, expected: int) -> void:
	var data: Dictionary = VxRecipeStore.read("res://data/voxels/%s/%s.json" % [folder, id])
	var model := VxModel.new()
	for material: Dictionary in data["materials"]:
		model._mat[material["name"]] = model.colors.size()
		model.colors.append(Color(material["color"]))
		model.roles.append(material.get("role", "armor"))
	for part: Dictionary in data["parts"]:
		model._add_part(part)
	check(model.errors.is_empty(), "%s source painter issues" % id)
	var occupied := {}
	for part: Dictionary in model.parts:
		var cells: Dictionary = part["cells"]
		if expected > 1:
			check_eq(VxIntegrity.components(cells).size(), 1,
				"%s: %s must have connected limbs and gear" % [id, part["name"]])
		for cell: Vector3i in cells:
			occupied[cell] = true
	check_eq(VxIntegrity.components(occupied).size(), expected,
		"%s authored physical assemblies" % id)
	var n := int(data.get("subdivide", 1))
	check(occupied.size() * n * n * n <= VoxelAsset.MAX_VOXELS,
		"%s authored mass must fit the pre-bevel budget" % id)
