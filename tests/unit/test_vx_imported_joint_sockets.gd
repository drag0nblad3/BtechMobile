extends TestCase
## Imported Mech sculpts must remain physically joined after the real Godot
## raster, exclusive part ownership and connectivity repairs run.

const MECHS := [
	"arctic_wolf", "avatar", "bane", "battle_cobra", "black_lanner",
	"cerberus", "champion", "cougar", "dragon_fire", "ebon_jaguar",
	"galahad", "gladiator", "glass_spider", "grand_dragon", "griffin_iic",
	"gunsmith", "hermes", "highlander_iic", "huntsman", "jackalope",
	"jenner_iic", "jinggau", "kingfisher", "locust_iic", "mad_cat_mk_ii",
	"marauder_ii", "peacekeeper", "raptor", "rattlesnake_ii",
	"rattlesnake", "shadow_hawk_iic", "shiro", "stealth", "sunder",
	"tempest", "templar", "thunder", "thunderbolt_iic", "tian_zong",
	"tiburon", "toro", "uziel",
]


func test_all_missing_mechs_have_backed_joint_contacts() -> void:
	for id: String in MECHS:
		var model := VxModel.load_file("res://data/voxels/%s_shape.json" % id)
		check(model.errors.is_empty(), "%s valid source: %s" % [id, model.errors])
		var result := VxConnectivity.audit(model)
		for fault: Dictionary in result["faults"]:
			check(false, "%s: %s %s -> %s" % [
					id, fault["type"], fault["part"], fault.get("parent", "")])
		check_eq(int(model.quality_report.get("floating_islands", -1)), 0,
				"%s no loose pieces in assembled source rig" % id)


func test_source_and_detailed_recipes_keep_same_structural_shapes() -> void:
	for id: String in MECHS:
		var lo: Dictionary = VxRecipeStore.read("res://data/voxels/%s_shape.json" % id)
		var hi: Dictionary = VxRecipeStore.read("res://data/voxels/%s.json" % id)
		check_eq(lo.get("unit", ""), hi.get("unit", ""), id + " official unit")
		check_eq(lo.get("muzzles", {}), hi.get("muzzles", {}),
				id + " authored muzzle coordinates unchanged between LODs")
		check_eq(lo.get("parts", []).size(), hi.get("parts", []).size(),
				id + " consistent articulation and parts")
		for i in mini(lo.get("parts", []).size(), hi.get("parts", []).size()):
			var a: Dictionary = lo["parts"][i]
			var b: Dictionary = hi["parts"][i]
			check_eq(a.get("name", ""), b.get("name", ""), id + " joint identity")
			check_eq(a.get("parent", ""), b.get("parent", ""),
					id + " kinematic parent")
			check_eq(a.get("pivot", []), b.get("pivot", []),
					id + " kinematic pivot")
			check_eq(a.get("shapes", []), b.get("shapes", []),
					id + " identical coarse structure and weapon bores")
