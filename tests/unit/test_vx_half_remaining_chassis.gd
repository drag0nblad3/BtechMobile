extends TestCase
## New shape-first chassis: check authored topology without allocating 3x
## detailed grids on CI. Godot is the authoritative loader.
const IDS := [
	"adder",
	"akuma",
	"albatross",
	"argus",
	"axman",
	"caesar",
	"chimera",
	"clint",
	"crossbow",
	"devastator",
	"emperor",
	"excalibur",
	"exterminator",
	"falconer",
	"firebee",
	"firefly",
	"goliath",
	"grendel",
	"grizzly",
	"guillotine",
	"hatamoto_chi",
	"hellspawn",
	"hermes_ii",
	"hoplite",
	"linebacker",
	"mackie",
	"night_gyr",
	"pack_hunter",
	"piranha",
	"scorpion",
	"supernova",
	"tarantula",
	"thanatos",
	"viper"
]


func test_source_low_and_high_match_and_official_units_exist() -> void:
	var units := UnitDb.load_dir()
	for id: String in IDS:
		var low: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		var high: Dictionary = JsonFile.read("res://data/voxels/%s.json" % id)
		check(units.get_def(low["unit"]) != null, "%s unit record" % id)
		check_eq(low["unit"], high["unit"])
		check_eq(int(low["subdivide"]), 1)
		check_eq(int(high["subdivide"]), 3)
		check_eq(low["parts"].size(), high["parts"].size())
		for i in low["parts"].size():
			var a: Dictionary = low["parts"][i]
			var b: Dictionary = high["parts"][i]
			check_eq(a["name"], b["name"])
			if a.has("mirror"):
				continue
			check_eq(a["pivot"], b["pivot"])
			for j in a.get("shapes", []).size():
				if a["shapes"][j].has("loft"):
					check_eq(a["shapes"][j]["loft"], b["shapes"][j]["loft"],
						"%s %s low/high contour" % [id, a["name"]])


func test_authored_parts_have_no_interpenetration() -> void:
	for id: String in IDS:
		for suffix in ["_shape", ""]:
			var d: Dictionary = JsonFile.read("res://data/voxels/%s%s.json" % [id, suffix])
			d["subdivide"] = 1
			for part: Dictionary in d["parts"]:
				part.erase("detail")
			var model := VxModel.from_dict(d)
			check(model.errors.is_empty(), "%s%s errors %s" % [id, suffix, model.errors])
			var occupied := {}
			for part: Dictionary in model.parts:
				for c: Vector3i in part["cells"]:
					check(not occupied.has(c), "%s%s overlaps at %s" % [id, suffix, c])
					occupied[c] = true
			for loc in Location.COUNT:
				check(not model.parts_at(loc).is_empty(), "%s%s missing %s" % [id, suffix, Location.code(loc)])