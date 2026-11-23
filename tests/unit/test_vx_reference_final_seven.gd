extends TestCase
## Last seven untreated chassis in the 281-model shape-source catalog.

const CHASSIS := [
	"von_rohrs_hebi", "werewolf", "wolf_trap", "wyvern",
	"yeoman", "ymir", "yu_huang"
]


func _data(chassis: String, suffix: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, suffix])


func _part(data: Dictionary, name: String) -> Dictionary:
	for p: Dictionary in data.get("parts", []):
		if p.get("name", "") == name:
			return p
	return {}


func _loft(part: Dictionary) -> Dictionary:
	for s: Dictionary in part.get("shapes", []):
		if s.has("loft"):
			return s["loft"]
	return {}


func test_source_aliases_and_independent_ymir_agree() -> void:
	for chassis: String in CHASSIS:
		var lo := _data(chassis, "_shape")
		var high := _data(chassis, "")
		if high.has("source"):
			check_eq(high["source"], "res://data/voxels/%s_shape.json" % chassis,
					"wrong sourced model %s" % chassis)
		else:
			check_eq(lo["unit"], high["unit"], "mismatched unit %s" % chassis)
			for part_name: String in ["ct", "lt", "la", "ll_shin"]:
				var a := _loft(_part(lo, part_name))
				var b := _loft(_part(high, part_name))
				check(not a.is_empty() and not b.is_empty(), "missing loft %s/%s" % [
						chassis, part_name])
				check(a == b, "source mismatched %s/%s" % [chassis, part_name])


func test_source_rig_and_cross_sections_survive() -> void:
	for chassis: String in CHASSIS:
		var d := _data(chassis, "_shape")
		for p: String in ["ct", "hd", "lt", "rt", "la", "ra", "ll", "rl"]:
			check(not _part(d, p).is_empty(), "missing body part %s/%s" % [
					chassis, p])
		for p: String in ["ct", "ll_shin"]:
			var loft := _loft(_part(d, p))
			check(not loft.is_empty(), "missing profile %s/%s" % [chassis, p])
			for sec: Dictionary in loft.get("sections", []):
				var pts: Array = sec.get("polygon", [])
				check(pts.size() >= 3, "short profile %s/%s" % [chassis, p])
				if pts.size() < 3:
					continue
				var area := 0.0
				for i in pts.size():
					var a: Array = pts[i]
					var b: Array = pts[(i + 1) % pts.size()]
					area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
				check(absf(area) > 0.01, "collapsed body %s/%s" % [chassis, p])


func test_yeoman_keeps_two_distinct_missile_towers_and_fifty_openings() -> void:
	var d := _data("yeoman", "_shape")
	var left := _part(d, "lt_launcher")
	var right := _part(d, "rt_launcher")
	check(not left.is_empty() and not right.is_empty(), "lost dual launchers")
	check_eq(right.get("mirror", ""), "lt_launcher", "lost reflected launcher")
	check_eq(d.get("muzzles", {}).get("LT", []).size(), 25, "left missile count changed")
	check_eq(d.get("muzzles", {}).get("RT", []).size(), 25, "right missile count changed")
	var erased := 0
	for shape: Dictionary in left.get("shapes", []):
		if shape.has("erase"):
			erased += 1
	check_eq(erased, 25, "Yeoman left tower lost source-level bores")


func test_specialist_gaits_and_asymmetric_weapons() -> void:
	for chassis: String in ["von_rohrs_hebi", "werewolf"]:
		check_eq(_data(chassis, "_shape")["legs"], "digitigrade",
				"lost reverse-jointed legs %s" % chassis)
	var huang := _data("yu_huang", "_shape")
	check(huang.get("muzzles", {}).get("RA", []).size() >= 1,
			"Yu Huang distinctive right-hand weapon missing")
