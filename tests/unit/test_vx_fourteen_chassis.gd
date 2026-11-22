extends TestCase
## New fourteen-chassis batch. Validate coarse authoring grids, not 28 high-poly
## VxPart meshes: fast enough for CI without an APK or GPU.

const MECHS := [
	{"id":"flea","unit":"flea_fle17"},
	{"id":"spider","unit":"spider_sdr5v"},
	{"id":"panther","unit":"panther_pnt9r"},
	{"id":"raven","unit":"raven_rvn3l"},
	{"id":"crab","unit":"crab_crb27"},
	{"id":"bushwacker","unit":"bushwacker_bswx1"},
	{"id":"orion","unit":"orion_on1k"},
	{"id":"longbow","unit":"longbow_lgb7q"},
	{"id":"jagermech","unit":"jagermech_jm6s"},
	{"id":"highlander","unit":"highlander_hgn732"},
	{"id":"nova","unit":"nova_prime"},
	{"id":"summoner","unit":"summoner_prime"},
	{"id":"mad_dog","unit":"mad_dog_prime"},
	{"id":"shadow_cat","unit":"shadow_cat_prime"},
]
const BORE_COUNTS := [
	{"id":"flea", "loc":"LA", "count":1},
	{"id":"flea", "loc":"RA", "count":1},
	{"id":"spider", "loc":"CT", "count":2},
	{"id":"panther", "loc":"RA", "count":1},
	{"id":"panther", "loc":"CT", "count":4},
	{"id":"raven", "loc":"LA", "count":1},
	{"id":"raven", "loc":"RA", "count":2},
	{"id":"raven", "loc":"RT", "count":6},
	{"id":"crab", "loc":"LA", "count":1},
	{"id":"crab", "loc":"RA", "count":1},
	{"id":"bushwacker", "loc":"RA", "count":1},
	{"id":"bushwacker", "loc":"LA", "count":5},
	{"id":"bushwacker", "loc":"LT", "count":5},
	{"id":"orion", "loc":"LT", "count":15},
	{"id":"orion", "loc":"RT", "count":1},
	{"id":"longbow", "loc":"LA", "count":20},
	{"id":"longbow", "loc":"RA", "count":20},
	{"id":"longbow", "loc":"LT", "count":5},
	{"id":"longbow", "loc":"RT", "count":5},
	{"id":"jagermech", "loc":"LA", "count":2},
	{"id":"jagermech", "loc":"RA", "count":2},
	{"id":"highlander", "loc":"LT", "count":20},
	{"id":"highlander", "loc":"LA", "count":6},
	{"id":"highlander", "loc":"RA", "count":1},
	{"id":"nova", "loc":"LA", "count":6},
	{"id":"nova", "loc":"RA", "count":6},
	{"id":"summoner", "loc":"LT", "count":15},
	{"id":"summoner", "loc":"LA", "count":1},
	{"id":"summoner", "loc":"RA", "count":1},
	{"id":"mad_dog", "loc":"LT", "count":20},
	{"id":"mad_dog", "loc":"RT", "count":20},
	{"id":"mad_dog", "loc":"LA", "count":2},
	{"id":"mad_dog", "loc":"RA", "count":2},
	{"id":"shadow_cat", "loc":"LA", "count":1},
	{"id":"shadow_cat", "loc":"RA", "count":1},
]
const DIRS := [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN,
               Vector3i.FORWARD, Vector3i.BACK]

func _raw(id: String, high: bool) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [id, "" if high else "_shape"])

func _coarse_model(d: Dictionary) -> VxModel:
	d["subdivide"] = 1
	for part: Dictionary in d["parts"]:
		part.erase("detail")
	return VxModel.from_dict(d)

func _contiguous(cells: Dictionary) -> bool:
	if cells.is_empty():
		return false
	var queue: Array[Vector3i] = []
	queue.append(cells.keys()[0])
	var seen: Dictionary = {}
	seen[queue[0]] = true
	var i := 0
	while i < queue.size():
		var current := queue[i]
		i += 1
		for direction: Vector3i in DIRS:
			var adjacent: Vector3i = current + direction
			if cells.has(adjacent) and not seen.has(adjacent):
				seen[adjacent] = true
				queue.append(adjacent)
	return seen.size() == cells.size()

func test_low_and_high_preserve_original_contours_and_unit_ids() -> void:
	var db := designs()
	for spec: Dictionary in MECHS:
		var id: String = spec["id"]
		var low: Dictionary = _raw(id, false)
		var high: Dictionary = _raw(id, true)
		check_eq(low["unit"], spec["unit"])
		check_eq(high["unit"], spec["unit"])
		check(db.get_def(spec["unit"]) != null, "Missing official record " + spec["unit"])
		check_eq(int(low["subdivide"]), 1, id + " shape stage")
		check_eq(int(high["subdivide"]), 3, id + " high fidelity")
		check_eq(low["parts"].size(), high["parts"].size())
		check_eq(low["legs"], high["legs"])
		check_eq(low["punch"], high["punch"])
		for i in low["parts"].size():
			var a: Dictionary = low["parts"][i]
			var b: Dictionary = high["parts"][i]
			check_eq(a["name"], b["name"], id + " component order")
			if a.has("mirror"):
				continue
			for j in a["shapes"].size():
				if a["shapes"][j].has("loft"):
					check_eq(a["shapes"][j]["loft"], b["shapes"][j]["loft"],
						"%s/%s hull cross section changed during detailing" % [id, a["name"]])

func test_coarse_geometry_has_no_colliding_detached_or_floating_parts() -> void:
	for spec: Dictionary in MECHS:
		var id: String = spec["id"]
		for high in [false, true]:
			var m := _coarse_model(_raw(id, high))
			check(m.errors.is_empty(), "%s high=%s errors: %s" % [id, high, m.errors])
			var owners := {}
			var overlaps := 0
			for p: Dictionary in m.parts:
				check(_contiguous(p["cells"]), "%s %s detached component" % [id, p["name"]])
				for cell: Vector3i in p["cells"]:
					if owners.has(cell):
						overlaps += 1
					owners[cell] = p["name"]
			check_eq(overlaps, 0, "%s high=%s interpenetrating locations" % [id, high])
			for p: Dictionary in m.parts:
				if p["parent"] == "":
					continue
				var parent: Dictionary = m.part(p["parent"])
				var touching := false
				for cell: Vector3i in p["cells"]:
					for direction: Vector3i in DIRS:
						if parent["cells"].has(cell + direction):
							touching = true
							break
					if touching:
						break
				check(touching, "%s %s has no physical contact to %s" % [id, p["name"], p["parent"]])
			for loc in Location.COUNT:
				check(not m.parts_at(loc).is_empty(), id + " missing " + Location.code(loc))
			if high:
				check(m.cell_count() * 27 >= 100000 and m.cell_count() * 27 <= 165000,
					"%s projected fine count: %d" % [id, m.cell_count() * 27])
			else:
				check(m.cell_count() < 8500, "%s low-res shape is too dense" % id)

func test_signature_weapon_ports_are_real_cutouts() -> void:
	for spec: Dictionary in BORE_COUNTS:
		var d: Dictionary = _raw(spec["id"], true)
		var loc: String = spec["loc"]
		var points: Array = d["muzzles"][loc]
		if not points.is_empty() and points[0] is not Array:
			points = [points]
		check_eq(points.size(), spec["count"], spec["id"] + " " + loc + " signature tubes")
		var drilled := 0
		for point: Array in points:
			var x := roundi(float(point[0]) * 3)
			var y := roundi(float(point[1]) * 3)
			var z := roundi(float(point[2]) * 3)
			var exists := false
			for p: Dictionary in d["parts"]:
				for sh: Dictionary in p.get("detail", []):
					if not sh.has("erase"):
						continue
					var box: Array = sh["erase"]
					if x >= box[0][0] and x <= box[1][0] \
						and y >= box[0][1] and y <= box[1][1] \
						and z >= box[0][2] and z <= box[1][2]:
						exists = true
						break
				if exists:
					break
			if exists:
				drilled += 1
		check_eq(drilled, spec["count"], spec["id"] + " " + loc + " bore count")
