extends TestCase
## Batch 24: source-first LOD consistency, official IDs, coarse topology.
## Coarse-only loading avoids expensive 3x subdivision in CI.
const IDS := [
	"wasp",
	"stinger",
	"mercury",
	"mongoose",
	"valkyrie",
	"wolfhound",
	"assassin",
	"vulcan",
	"hatchetman",
	"kintaro",
	"dervish",
	"whitworth",
	"hollander",
	"flashman",
	"victor",
	"zeus",
	"thug",
	"charger",
	"kodiak",
	"executioner",
	"hellbringer",
	"turkina",
	"kit_fox",
	"ice_ferret"
]


func _recipe(id: String, high: bool) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [id, "" if high else "_shape"])


func test_twentyfour_have_record_sheets_and_matching_primary_geometry() -> void:
	var units := UnitDb.load_dir()
	for id: String in IDS:
		var lo := _recipe(id, false)
		var hi := _recipe(id, true)
		check(units.get_def(lo["unit"]) != null, id + " official unit record")
		check_eq(lo["unit"], hi["unit"])
		check_eq(int(lo["subdivide"]), 1)
		check_eq(int(hi["subdivide"]), 3)
		check_eq(lo["parts"].size(), hi["parts"].size())
		for i in lo["parts"].size():
			var a: Dictionary = lo["parts"][i]
			var z: Dictionary = hi["parts"][i]
			check_eq(a["name"], z["name"])
			if a.has("mirror"):
				continue
			check_eq(a["pivot"], z["pivot"])
			for j in a.get("shapes", []).size():
				if a["shapes"][j].has("loft"):
					check_eq(a["shapes"][j]["loft"], z["shapes"][j]["loft"],
						"%s %s primary contour preserved" % [id, a["name"]])


func test_twentyfour_have_8_hit_locations_and_disjoint_coarse_parts() -> void:
	for id: String in IDS:
		for suffix in ["_shape", ""]:
			var d: Dictionary = JsonFile.read("res://data/voxels/%s%s.json" % [id, suffix])
			d["subdivide"] = 1
			for part: Dictionary in d["parts"]:
				part.erase("detail")
			var m := VxModel.from_dict(d)
			check(m.errors.is_empty(), "%s%s parse warnings %s" % [id, suffix, m.errors])
			var owners := {}
			for part: Dictionary in m.parts:
				for c: Vector3i in part["cells"]:
					check(not owners.has(c), "%s%s overlap at %s" % [id, suffix, c])
					owners[c] = true
			for loc in Location.COUNT:
				check(not m.parts_at(loc).is_empty(), "%s%s lacks %s" % [id, suffix, Location.code(loc)])