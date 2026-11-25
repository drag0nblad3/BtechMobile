extends TestCase
## Distinctive gaits, weapon mounts, shell anatomy and quadruped rigs.

const CORE_RIG := ["ct", "hd", "lt", "rt", "la", "ra", "ll", "rl"]
const QUAD_RIG := [
	"la", "la_shin", "la_foot", "ra", "ra_shin", "ra_foot",
	"ll", "ll_shin", "ll_foot", "rl", "rl_shin", "rl_foot"
]
const WEAPON_PARTS := {
	"hussar": ["ct_laser", "ll_tarsus"],
	"thunderbolt": ["rt_rack"],
	"rakshasa": ["la_rotary"],
	"warlord": ["ct_housing"],
	"cobra": ["la_housing"],
	"imp": ["ra_lrm"],
	"salamander": ["lt_housing"],
	"titan": ["lt_housing"]
}


func _data(id: String, tier: String = "_shape") -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [id, tier])


func _part(data: Dictionary, name: String) -> Dictionary:
	for part: Dictionary in data.get("parts", []):
		if part.get("name", "") == name:
			return part
	return {}


func test_canonical_gaits_stay_specific_to_each_chassis() -> void:
	var expected: Dictionary = JsonFile.read(
			"res://tests/fixtures/voxel_reference_cohorts.json").get("gaits", {})
	check(expected.size() >= 60, "historical gait contracts retained")
	for id: String in expected:
		check_eq(_data(id).get("legs"), expected[id], "changed leg profile %s" % id)


func test_named_weapon_housings_and_scanner_components_stay_distinct() -> void:
	for id: String in WEAPON_PARTS:
		var model := _data(id)
		for name: String in WEAPON_PARTS[id]:
			check(not _part(model, name).is_empty(),
					"lost named subassembly %s/%s" % [id, name])
	for tier: String in ["_shape", ""]:
		var hussar := _data("hussar", tier)
		if hussar.has("source"):
			continue
		for name: String in WEAPON_PARTS["hussar"]:
			check(not _part(hussar, name).is_empty(),
					"Hussar detailed articulation missing %s" % name)


func test_non_generic_weapon_arms_keep_their_original_geometry() -> void:
	for id: String in ["axman", "hatchetman"]:
		var axe := _part(_data(id), "ra")
		check(axe.has("mirror"), "melee arm not mirrored correctly %s" % id)
		check(not axe.get("add", []).is_empty(), "melee blade erased %s" % id)
	var panther := _data("panther")
	var ppcrig := _part(panther, "ra_ppc")
	check(not _part(panther, "ra").get("add", []).is_empty() or not ppcrig.is_empty(),
			"Panther PPC housing missing")
	if not ppcrig.is_empty():
		check_eq(ppcrig.get("parent"), "ra", "Panther PPC arm attachment")
		check(not ppcrig.get("shapes", []).is_empty(), "Panther barrel has no volume")
	for id: String in ["kodiak", "longbow"]:
		check(_part(_data(id), "ra").get("add", []).size() > 5,
				"distinctive right weapon or claw lost %s" % id)


func test_quadrupeds_keep_four_load_bearing_joint_chains() -> void:
	for id: String in ["goliath", "scorpion", "tarantula", "thunder_stallion"]:
		var low := _data(id)
		for name: String in QUAD_RIG:
			check(not _part(low, name).is_empty(), "quad load-bearing part %s/%s" % [id, name])
		if id in ["tarantula", "thunder_stallion"]:
			for tier: String in ["_shape", ""]:
				var raw := _data(id, tier)
				check_eq(bool(raw.get("quad", false)), true, "four-leg flag missing %s%s" % [id, tier])
				for name: String in QUAD_RIG:
					check(not _part(raw, name).is_empty(),
							"quad joint missing %s%s/%s" % [id, tier, name])


func test_unusual_shells_remain_separate_from_the_armor_loft() -> void:
	for id: String in ["garm", "hermit_crab", "jackrabbit"]:
		var part := _part(_data(id), "lt")
		var shell := false
		for shape: Dictionary in part.get("shapes", []):
			if shape.has("shell"):
				shell = true
		check(shell, "missing bespoke shoulder shell %s" % id)


func test_specialist_aliases_and_independent_detail_survive() -> void:
	for id: String in ["razorback", "sentry"]:
		check_eq(_data(id, "").get("source"), "res://data/voxels/%s_shape.json" % id,
				"lost high-detail alias %s" % id)
	var low := _data("rook")
	var high := _data("rook", "")
	check(not high.has("source"), "Rook needs independent detailed sculpt")
	check(String(low.get("unit", "")).begins_with("rook_"), "invalid Rook source design")
	check(String(high.get("unit", "")).begins_with("rook_"), "invalid Rook detail design")
