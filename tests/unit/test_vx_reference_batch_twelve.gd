extends TestCase
## Twentieth-chassis specialist sculpt parity and silhouette invariants.

const PAIRED := [
	"hollander", "hoplite", "icarus_ii", "jagermech", "katana",
	"kodiak", "lancelot", "legionnaire", "longbow", "mackie",
	"malice", "merlin", "nightsky", "ostwar", "pack_hunter",
	"penetrator", "scarabus"
]
const ALIASES := ["razorback", "sentry"]
const INDEPENDENT := ["rook"]
const SCULPT := ["ct", "lt", "la", "ll_shin"]


func _recipe(chassis: String, tier: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, tier])


func _part(recipe: Dictionary, name: String) -> Dictionary:
	for part: Dictionary in recipe.get("parts", []):
		if part.get("name", "") == name:
			return part
	return {}


func _loft(part: Dictionary) -> Dictionary:
	for shape: Dictionary in part.get("shapes", []):
		if shape.has("loft"):
			return shape["loft"]
	return {}


func test_seventeen_paired_anatomies_have_matching_primary_sections() -> void:
	for chassis: String in PAIRED:
		var low := _recipe(chassis, "_shape")
		var high := _recipe(chassis, "")
		check_eq(low["unit"], high["unit"], "wrong art pair: %s" % chassis)
		for name: String in SCULPT:
			var a := _loft(_part(low, name))
			var b := _loft(_part(high, name))
			check(not a.is_empty() and not b.is_empty(), "lost %s/%s" % [chassis, name])
			check(a == b, "tier geometry divergence %s/%s" % [chassis, name])


func test_specialists_keep_their_original_detail_source_contract() -> void:
	for chassis: String in ALIASES:
		var high := _recipe(chassis, "")
		check_eq(high.get("source", ""), "res://data/voxels/%s_shape.json" % chassis,
				"invalid detail source %s" % chassis)
	for chassis: String in INDEPENDENT:
		var low := _recipe(chassis, "_shape")
		var high := _recipe(chassis, "")
		check(not high.has("source"), "detailed Rook must stay independently sculpted")
		check_eq(high["unit"], low["unit"], "Rook unit mismatch")


func test_primary_sections_have_real_area_and_animated_locations() -> void:
	for chassis: String in PAIRED + ALIASES + INDEPENDENT:
		var data := _recipe(chassis, "_shape")
		for name: String in ["hd", "ct", "lt", "rt", "la", "ra", "ll", "rl"]:
			check(not _part(data, name).is_empty(), "lost %s/%s" % [chassis, name])
		for name: String in SCULPT:
			var loft := _loft(_part(data, name))
			check(not loft.is_empty(), "empty sculpt %s/%s" % [chassis, name])
			for sec: Dictionary in loft.get("sections", []):
				var poly: Array = sec.get("polygon", [])
				check(poly.size() >= 3, "short polygon %s/%s" % [chassis, name])
				if poly.size() < 3:
					continue
				var area := 0.0
				for i in poly.size():
					var a: Array = poly[i]
					var b: Array = poly[(i + 1) % poly.size()]
					area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
				check(absf(area) > 0.01, "collapsed source section %s/%s" % [
						chassis, name])


func test_named_specialist_weapons_and_gait_survive() -> void:
	var kodiak := _recipe("kodiak", "_shape")
	var right_hand := _part(kodiak, "ra")
	check(right_hand.get("add", []).size() > 5, "Kodiak distinctive right claw lost")
	var longbow := _recipe("longbow", "_shape")
	check(_part(longbow, "ra").get("add", []).size() > 5,
			"Longbow paired missile pod lost")
	for chassis: String in ["legionnaire", "pack_hunter"]:
		check_eq(_recipe(chassis, "_shape")["legs"], "digitigrade",
				"specialist gait changed: %s" % chassis)
