extends TestCase
## Eight low/high shape-first chassis. Avoid loading all 8 high-poly meshes in tests:
## validate their editable coarse recipes before subdivision and expensive bevels.

const CASES := [
	{"id": "king_crab", "unit": "king_crab_kgc000"},
	{"id": "stalker", "unit": "stalker_stk3f"},
	{"id": "rifleman", "unit": "rifleman_rfl3n"},
	{"id": "phoenix_hawk", "unit": "phoenix_hawk_pxh1"},
	{"id": "urbanmech", "unit": "urbanmech_umr60"},
	{"id": "firestarter", "unit": "firestarter_fs9h"},
	{"id": "black_knight", "unit": "black_knight_bl7knt"},
	{"id": "vindicator", "unit": "vindicator_vnd1r"},
]

func _data(id: String, high: bool) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [id, "" if high else "_shape"])


func test_unit_ids_and_both_lod_recipes() -> void:
	var db := UnitDb.load_dir()
	for spec: Dictionary in CASES:
		var id: String = spec["id"]
		var low := _data(id, false)
		var high := _data(id, true)
		check_eq(low["unit"], spec["unit"], id + " low unit")
		check_eq(high["unit"], spec["unit"], id + " high unit")
		check(db.get_def(spec["unit"]) != null, id + " official unit exists")
		check_eq(int(low["subdivide"]), 1, id + " low sculpt")
		check_eq(int(high["subdivide"]), 3, id + " fine sculpt")
		check_eq(low["legs"], high["legs"], id + " leg solver agreement")
		check_eq(low["punch"], high["punch"], id + " hand actuators agreement")
		check_eq(low["parts"].size(), high["parts"].size(), id + " matching articulated parts")


func test_no_coarse_part_voxel_overlap_and_detail_budget() -> void:
	for spec: Dictionary in CASES:
		var id: String = spec["id"]
		for high in [false, true]:
			var d := _data(id, high)
			d["subdivide"] = 1
			for p: Dictionary in d["parts"]:
				p.erase("detail")
			var m := VxModel.from_dict(d)
			check(m.errors.is_empty(), "%s%s authoring errors: %s" % [id, " high" if high else " low", m.errors])
			var owner := {}
			var overlaps := 0
			for p: Dictionary in m.parts:
				for c: Vector3i in p["cells"]:
					if owner.has(c):
						overlaps += 1
					owner[c] = p["name"]
			check_eq(overlaps, 0, "%s%s overlap" % [id, " high" if high else " low"])
			for loc in Location.COUNT:
				check(not m.parts_at(loc).is_empty(), "%s missing %s" % [id, Location.code(loc)])
			if high:
				var projected := m.cell_count() * 27
				check(projected >= 95000 and projected <= 170000,
						"%s projected 3x budget: %d (before bevel)" % [id, projected])
			else:
				check(m.cell_count() < 12500, "%s is a lightweight shape study" % id)


func test_primary_loft_profiles_preserved_in_high_detail() -> void:
	for spec: Dictionary in CASES:
		var id: String = spec["id"]
		var low := _data(id, false)
		var high := _data(id, true)
		for i in low["parts"].size():
			var lp: Dictionary = low["parts"][i]
			var hp: Dictionary = high["parts"][i]
			check_eq(lp["name"], hp["name"], id + " part order")
			if lp.has("mirror"):
				continue
			for j in lp["shapes"].size():
				if lp["shapes"][j].has("loft"):
					check_eq(lp["shapes"][j]["loft"], hp["shapes"][j]["loft"],
						"%s %s original silhouette intact" % [id, lp["name"]])


func test_launcher_and_cannon_bores_have_aligned_fine_grid_cutouts() -> void:
	var expected := {
		"king_crab": {"LT": 15, "LA": 1, "RA": 1},
		"stalker": {"LA": 10, "RA": 10, "LT": 6, "RT": 6},
		"rifleman": {"LA": 2, "RA": 2},
		"vindicator": {"LT": 5, "RA": 1},
	}
	var parts := {
		"king_crab": {"LT": "lt", "LA": "la", "RA": "ra"},
		"stalker": {"LA": "la", "RA": "ra", "LT": "lt", "RT": "rt"},
		"rifleman": {"LA": "la", "RA": "ra"},
		"vindicator": {"LT": "lt", "RA": "ra"},
	}
	for id: String in expected:
		var d := _data(id, true)
		var by_name := {}
		for p: Dictionary in d["parts"]:
			by_name[p["name"]] = p
		for loc: String in expected[id]:
			var points: Array = d["muzzles"][loc]
			if not points.is_empty() and points[0] is not Array:
				points = [points]
			check_eq(points.size(), expected[id][loc], id + " " + loc + " tube count")
			var p: Dictionary = by_name[parts[id][loc]]
			for pt: Array in points:
				var x := roundi(float(pt[0]) * 3.0)
				var y := roundi(float(pt[1]) * 3.0)
				var z := roundi(float(pt[2]) * 3.0)
				var drilled := false
				for detail: Dictionary in p.get("detail", []):
					if not detail.has("erase"):
						continue
					var lo: Array = detail["erase"][0]
					var hi: Array = detail["erase"][1]
					if x >= lo[0] and x <= hi[0] and y >= lo[1] and y <= hi[1] \
							and z >= lo[2] and z <= hi[2]:
						drilled = true
						break
				check(drilled, "%s %s port %s is physically drilled" % [id, loc, pt])
