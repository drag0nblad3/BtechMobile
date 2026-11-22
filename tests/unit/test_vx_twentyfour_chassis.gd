extends TestCase
## Regression guard for 24 signature-specific silhouette and fine-grid voxel pairs.
## Intentionally rasterizes only the editable coarse grid to stay CI friendly.

const IDS := [
	"annihilator",
	"nightstar",
	"dire_wolf",
	"warhawk",
	"grasshopper",
	"quickdraw",
	"dragon",
	"trebuchet",
	"cicada",
	"commando",
	"javelin",
	"fire_moth",
	"mist_lynx",
	"banshee",
	"cyclops",
	"mauler",
	"enforcer",
	"blackjack",
	"crusader",
	"cataphract",
	"ostsol",
	"ostroc",
	"gargoyle",
	"stormcrow"
]

func _recipe(id: String, high: bool) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [id, "" if high else "_shape"])


func _coarse(d: Dictionary) -> VxModel:
	d["subdivide"] = 1
	for p: Dictionary in d["parts"]:
		p.erase("detail")
	return VxModel.from_dict(d)


func test_twentyfour_records_and_shared_primary_contours() -> void:
	var units := UnitDb.load_dir()
	for id: String in IDS:
		var lo := _recipe(id, false)
		var hi := _recipe(id, true)
		check(units.get_def(lo["unit"]) != null, id + " official unit record exists")
		check_eq(lo["unit"], hi["unit"])
		check_eq(int(lo["subdivide"]), 1)
		check_eq(int(hi["subdivide"]), 3)
		check_eq(lo["parts"].size(), hi["parts"].size())
		check_eq(lo["legs"], hi["legs"])
		for i in lo["parts"].size():
			var a: Dictionary = lo["parts"][i]
			var b: Dictionary = hi["parts"][i]
			check_eq(a["name"], b["name"])
			if a.has("mirror"):
				continue
			check_eq(a["pivot"], b["pivot"])
			for j in a["shapes"].size():
				if a["shapes"][j].has("loft"):
					check_eq(a["shapes"][j]["loft"], b["shapes"][j]["loft"],
						"%s/%s shape-first sections remain intact" % [id, a["name"]])


func test_twentyfour_coarse_parts_are_disjoint_and_connected() -> void:
	for id: String in IDS:
		for high in [false, true]:
			var m := _coarse(_recipe(id, high))
			check(m.errors.is_empty(), "%s errors high=%s: %s" % [id, high, m.errors])
			var owners := {}
			for part: Dictionary in m.parts:
				for cell: Vector3i in part["cells"]:
					check(not owners.has(cell), "%s collision at %s" % [id, cell])
					owners[cell] = part["name"]
			for loc in Location.COUNT:
				check(not m.parts_at(loc).is_empty(), "%s missing %s" % [id, Location.code(loc)])
			check(owners.size() > 2000, id + " silhouette contains enough geometry")
			if high:
				check(m.cell_count() * 27 >= 90000 and m.cell_count() * 27 <= 165000,
					"%s offline fine-grid budget: %d" % [id, m.cell_count() * 27])


func test_twentyfour_have_real_bores_with_distinct_muzzle_coordinates() -> void:
	for id: String in IDS:
		var d := _recipe(id, true)
		for loc: String in d["muzzles"]:
			var points: Array = d["muzzles"][loc]
			if not points.is_empty() and points[0] is not Array:
				points = [points]
			var positions := {}
			for position: Array in points:
				var fine := Vector3i(roundi(float(position[0]) * 3.0),
					roundi(float(position[1]) * 3.0), roundi(float(position[2]) * 3.0))
				check(not positions.has(fine), "%s %s muzzle coordinates unique" % [id, loc])
				positions[fine] = true
				var erased := false
				for part: Dictionary in d["parts"]:
					for shape: Dictionary in part.get("detail", []):
						if not shape.has("erase"):
							continue
						var corners: Array = shape["erase"]
						if fine.x >= corners[0][0] and fine.x <= corners[1][0] \
							and fine.y >= corners[0][1] and fine.y <= corners[1][1] \
							and fine.z >= corners[0][2] and fine.z <= corners[1][2]:
							erased = true
							break
					if erased:
						break
				check(erased, "%s %s muzzle is drilled, not painted" % [id, loc])
