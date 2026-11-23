extends TestCase
## Source-paired geometry guard for the twenty newly integrated BattleMechs.

const CHASSIS := [
	"arctic_wolf", "avatar", "bane", "battle_cobra", "black_lanner",
	"cerberus", "champion", "cougar", "dragon_fire", "ebon_jaguar",
	"galahad", "gladiator", "glass_spider", "grand_dragon", "griffin_iic",
	"gunsmith", "hermes", "highlander_iic", "huntsman", "jackalope"
]
const CORE := ["ct", "hd", "lt", "rt", "la", "ra", "ll", "rl"]
const SCULPT := ["ct", "lt", "rt", "la", "ra"]


func _recipe(chassis: String, suffix: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, suffix])


func _part(data: Dictionary, part_name: String) -> Dictionary:
	for p: Dictionary in data.get("parts", []):
		if p.get("name", "") == part_name:
			return p
	return {}


func _primary(part: Dictionary) -> Dictionary:
	for shape: Dictionary in part.get("shapes", []):
		if shape.has("loft"):
			return shape["loft"]
	return {}


func test_all_twenty_keep_matching_sculpt_tiers_and_weapon_origins() -> void:
	for chassis: String in CHASSIS:
		var low := _recipe(chassis, "_shape")
		var high := _recipe(chassis, "")
		check_eq(low["unit"], high["unit"], "wrong unit %s" % chassis)
		check_eq(low["legs"], high["legs"], "gait differs %s" % chassis)
		check(low.get("muzzles", {}) == high.get("muzzles", {}),
				"weapon origins differ across source tiers: %s" % chassis)
		for name: String in SCULPT:
			var a := _primary(_part(low, name))
			var b := _primary(_part(high, name))
			check(not a.is_empty() and not b.is_empty(), "lost loft %s:%s" % [
					chassis, name])
			check(a == b, "loft tier drift %s:%s" % [chassis, name])


func test_all_twenty_have_core_joint_ancestry_and_real_loft_area() -> void:
	for chassis: String in CHASSIS:
		var data := _recipe(chassis, "_shape")
		for name: String in CORE:
			check(not _part(data, name).is_empty(), "missing rig location %s:%s" % [
					chassis, name])
		for name: String in SCULPT:
			var loft := _primary(_part(data, name))
			check_eq(loft.get("axis", ""), "y", "wrong sculpt axis %s:%s" % [
					chassis, name])
			for s: Dictionary in loft.get("sections", []):
				var poly: Array = s.get("polygon", [])
				check(poly.size() >= 3, "short contour %s:%s" % [chassis, name])
				if poly.size() < 3:
					continue
				var area := 0.0
				for i in poly.size():
					var a: Array = poly[i]
					var b: Array = poly[(i + 1) % poly.size()]
					area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
				check(absf(area) > 0.02, "collapsed armor section %s:%s" % [
						chassis, name])


func test_specialist_leg_and_launcher_parts_survive() -> void:
	for chassis: String in ["arctic_wolf", "battle_cobra", "black_lanner",
			"champion", "cougar", "ebon_jaguar", "glass_spider",
			"huntsman", "jackalope"]:
		check_eq(_recipe(chassis, "_shape")["legs"], "digitigrade",
				"specialist gait changed %s" % chassis)
	for chassis: String in CHASSIS:
		var data := _recipe(chassis, "_shape")
		check(not data.get("weapons", []).is_empty(), "weapons lost %s" % chassis)
