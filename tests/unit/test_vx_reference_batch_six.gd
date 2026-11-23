extends TestCase
## Imported BattleMech source geometry review, sixth batch of twenty.

const CHASSIS := [
	"alfar", "apollo", "bandersnatch", "battle_hawk", "behemoth",
	"blade", "bombard", "brigand", "cestus", "cossack",
	"cronus", "daedalus", "daikyu", "daimyo", "dart",
	"dragoon", "duan_gung", "eagle", "eisenfaust", "enfield"
]


func _source(chassis: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s_shape.json" % chassis)


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


func test_all_imported_high_detail_recipes_still_share_the_authoritative_source() -> void:
	for chassis: String in CHASSIS:
		var detailed: Dictionary = JsonFile.read("res://data/voxels/%s.json" % chassis)
		if detailed.has("source"):
			check_eq(detailed["source"], "res://data/voxels/%s_shape.json" % chassis,
					"wrong source alias %s" % chassis)
		else:
			for name: String in ["ct", "lt", "la", "ll_shin"]:
				check(_loft(_part(detailed, name)) == _loft(_part(_source(chassis), name)),
						"unpaired source silhouette: %s/%s" % [chassis, name])


func test_all_source_lofts_keep_nonzero_sculpted_sections() -> void:
	for chassis: String in CHASSIS:
		var source := _source(chassis)
		for name: String in ["ct", "lt", "la", "ll_shin"]:
			var loft := _loft(_part(source, name))
			check(not loft.is_empty(), "missing core sculpt %s/%s" % [chassis, name])
			for section: Dictionary in loft.get("sections", []):
				var points: Array = section.get("polygon", [])
				check(points.size() >= 3, "invalid polygon %s/%s" % [chassis, name])
				if points.size() < 3:
					continue
				var area := 0.0
				for i in points.size():
					var a: Array = points[i]
					var b: Array = points[(i + 1) % points.size()]
					area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
				check(absf(area) > 0.01, "collapsed section %s/%s" % [chassis, name])


func test_unique_rigs_keep_eight_hit_locations_and_reverse_jointed_chassis() -> void:
	for chassis: String in CHASSIS:
		var source := _source(chassis)
		for name: String in ["ct", "hd", "lt", "rt", "la", "ra", "ll", "rl"]:
			check(not _part(source, name).is_empty(), "lost joint %s/%s" % [chassis, name])
	for chassis: String in ["battle_hawk", "cossack", "duan_gung", "eagle"]:
		check_eq(_source(chassis)["legs"], "digitigrade",
				"lost source gait %s" % chassis)
