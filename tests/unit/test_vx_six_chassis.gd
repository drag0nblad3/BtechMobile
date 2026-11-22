extends TestCase
## Regression coverage for six independently drawn shape-first mechs.
## This loads the authored grid for every variant, not the million-cell fine grid.

const IDS := ["awesome", "griffin", "thunderbolt", "locust", "centurion", "battlemaster"]
const UNITS := ["awesome_aws8q", "griffin_grf1n", "thunderbolt_tdr5s",
		"locust_lct1v", "centurion_cn9a", "battlemaster_blr1g"]


func test_official_records_and_distinct_shapes() -> void:
	var db := designs()
	for index in IDS.size():
		var id: String = IDS[index]
		var low: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		var high: Dictionary = JsonFile.read("res://data/voxels/%s.json" % id)
		check_eq(low.get("unit"), UNITS[index], id + " low official variant")
		check_eq(high.get("unit"), UNITS[index], id + " high official variant")
		check(db.get_def(UNITS[index]) != null, id + " official record exists")
		check_eq(int(low["subdivide"]), 1, id + " shape is coarse")
		check_eq(int(high["subdivide"]), 3, id + " detail uses 3x subdivision")
		check(low["parts"].size() >= 12, id + " has articulated components")
		check_eq(low["parts"].size(), high["parts"].size(), id + " component count unchanged")
		var high_parts := {}
		for part: Dictionary in high["parts"]:
			high_parts[part["name"]] = part
		for part: Dictionary in low["parts"]:
			if part.has("mirror"):
				continue
			var low_lofts: Array = []
			var high_lofts: Array = []
			for shape: Dictionary in part.get("shapes", []):
				if shape.has("loft"):
					low_lofts.append(shape["loft"])
			for shape: Dictionary in high_parts[part["name"]].get("shapes", []):
				if shape.has("loft"):
					high_lofts.append(shape["loft"])
			check_eq(low_lofts, high_lofts, "%s %s must preserve the outer silhouette" % [id, part["name"]])
		check_eq(bool(low.get("punch", true)), bool(high.get("punch", true)), "same arm capability")
	check_eq(JsonFile.read("res://data/voxels/locust_shape.json")["legs"], "digitigrade")
	check(not bool(JsonFile.read("res://data/voxels/locust.json")["punch"]), "Locust gun pods have no hands")


func test_both_lods_have_exclusive_grid_and_all_locations() -> void:
	for id in IDS:
		for suffix in ["_shape", ""]:
			var d: Dictionary = JsonFile.read("res://data/voxels/%s%s.json" % [id, suffix])
			var scale: int = int(d["subdivide"])
			d["subdivide"] = 1  # 3x subdivision is tested by VxRefine separately.
			for p: Dictionary in d["parts"]:
				p.erase("detail")
			var model := VxModel.from_dict(d)
			check(model.errors.is_empty(), "%s%s load errors: %s" % [id, suffix, model.errors])
			var owners := {}
			var clashes := 0
			for part: Dictionary in model.parts:
				for cell: Vector3i in part["cells"]:
					if owners.has(cell):
						clashes += 1
					else:
						owners[cell] = part["name"]
			check_eq(clashes, 0, "%s%s cells are exclusively assigned" % [id, suffix])
			for loc in Location.COUNT:
				check(not model.parts_at(loc).is_empty(), "%s%s missing %s" % [id, suffix, Location.code(loc)])
			if suffix == "":
				# Pre-bevel voxel estimate. Dense assault designs are deliberately
				# permitted more than lighter scouts, pending mobile profiling.
				var projected: int = model.cell_count() * scale * scale * scale
				check(projected >= (80000 if id == "locust" else 95000) and projected <= 210000,
						"%s high-LOD projected voxels: %d" % [id, projected])


func test_weapon_identifiers_and_launch_racks() -> void:
	for id in ["griffin", "thunderbolt", "centurion", "battlemaster"]:
		var model: Dictionary = JsonFile.read("res://data/voxels/%s.json" % id)
		var parts := {}
		for part: Dictionary in model["parts"]:
			parts[part["name"]] = true
		check(parts.has("rt_rack") or parts.has("lt_rack") or parts.has("lt_srm"),
				id + " keeps its chassis-specific missile housing")
		check(model["muzzles"].size() >= 2, id + " has distinct firing points")
	var awesome: Dictionary = JsonFile.read("res://data/voxels/awesome.json")
	for loc in ["LT", "RT", "RA"]:
		check(awesome["muzzles"].has(loc), "Awesome has PPC in " + loc)
	var locust: Dictionary = JsonFile.read("res://data/voxels/locust.json")
	check(locust["muzzles"].has("LA") and locust["muzzles"].has("RA"),
			"Locust has symmetrical machine gun pods")
