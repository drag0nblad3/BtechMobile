extends TestCase
## Exact MegaMek advanced-equipment variants and their damageable voxel sculpts.

const IDS := ["spider_sdr10k", "victor_vtrcr", "rook_nh3x", "nova_t", "nova_cat_g"]
const ART := ["spider_sdr10k", "victor_vtrcr", "rook", "nova_t", "nova_cat"]


func test_official_equipment_variants_and_bv() -> void:
	var db := designs()
	var bv := [824, 1465, 1746, 1579, 2522]
	for i in IDS.size():
		var d: UnitDef = db.get_def(IDS[i])
		check(d != null, IDS[i] + " must be in the force catalog")
		if d == null:
			continue
		check_eq(d.bv, bv[i], IDS[i] + " official Master Unit List BV")
		check(String(d.source.get("megamek", "")).ends_with(".mtf"), IDS[i] + " source file")
		check(int(d.source.get("mul_id", 0)) > 0, IDS[i] + " MUL identity")
		check(d.role != "", IDS[i] + " tactical role")
		var u := Unit.new(i + 1, d, 0, Vector2i.ZERO, 0)
		for w in u.weapons:
			if w.def.uses_ammo():
				check(u.ammo.any(func(a: AmmoBin) -> bool: return a.weapon == w.def),
						IDS[i] + " must have ammunition for " + w.def.name)


func test_exact_special_weapon_mounts() -> void:
	var db := designs()
	_check_mounts(db.get_def("spider_sdr10k"), [["re_large_laser", Location.RT]])
	_check_mounts(db.get_def("victor_vtrcr"), [["hvac10", Location.RA]])
	_check_mounts(db.get_def("rook_nh3x"), [["binary_laser_cannon", Location.RT]])
	var nova: UnitDef = db.get_def("nova_t")
	check_eq(_count(nova, "c_medium_chemical_laser", Location.LA), 6, "left chemical battery")
	check_eq(_count(nova, "c_medium_chemical_laser", Location.RA), 6, "right chemical battery")
	check_eq(nova.ammo_mounts.size(), 4, "four tons of chemical laser ammunition")
	var cat: UnitDef = db.get_def("nova_cat_g")
	check_eq(_count(cat, "c_ap_gauss_rifle", Location.LT), 4, "left AP Gauss group")
	check_eq(_count(cat, "c_ap_gauss_rifle", Location.RT), 4, "right AP Gauss group")
	check_eq(_count(cat, "c_lrm20", Location.LA), 1, "one left LRM20")
	check_eq(_count(cat, "c_lrm20", Location.RA), 2, "two right LRM20")
	check(not cat.has_actuator(Location.LA, "hand") and not cat.has_actuator(Location.RA, "hand"),
			"Nova Cat G has launcher arms, not fists")


func _count(d: UnitDef, id: String, loc: int) -> int:
	var total := 0
	for m: Dictionary in d.weapon_mounts:
		if (m["weapon"] as WeaponDef).id == id and m["loc"] == loc:
			total += 1
	return total


func _check_mounts(d: UnitDef, mounts: Array) -> void:
	for want: Array in mounts:
		check_eq(_count(d, want[0], want[1]), 1, d.id + " cannon")


func test_variants_have_eight_damageable_locations() -> void:
	for i in ART.size():
		var m := VxModel.load_file("res://data/voxels/" + ART[i] + ".json")
		check(m.errors.is_empty(), ART[i] + ": " + ", ".join(m.errors))
		check_eq(m.unit_id, IDS[i], ART[i] + " authoritative record sheet")
		for loc in Location.COUNT:
			check(not m.parts_at(loc).is_empty(), ART[i] + " needs " + Location.code(loc))
		check(m.cell_count() > 5000, ART[i] + " missing solid physical geometry")
		check(m.cell_count() < 200000, ART[i] + " exceeds model budget")


func test_source_variants_preserve_base_chassis() -> void:
	var raw: Dictionary = JsonFile.read("res://data/voxels/spider_sdr10k.json")
	var original: Dictionary = JsonFile.read(raw["source"])
	var count: int = original["parts"].size()
	var expanded := VxVariant.resolve(original, raw)
	check_eq(original["parts"].size(), count, "shared Spider source is not mutated")
	check_eq(expanded["parts"].size(), count, "no duplicate moving parts")
	check_eq(expanded["unit"], "spider_sdr10k")
	var upgraded := VxModel.load_file("res://data/voxels/spider_sdr10k.json")
	check(upgraded.part("rt")["cells"].size() > 0, "RE laser has an articulated right torso mount")
	check_eq(upgraded.muzzles[Location.RT].size(), 1, "RE large laser visible muzzle")
	var nova := VxModel.load_file("res://data/voxels/nova_t.json")
	check_eq(nova.muzzles[Location.LA].size(), 6)
	check_eq(nova.muzzles[Location.RA].size(), 6)


func test_nova_cat_has_separate_physical_missile_ports() -> void:
	var raw: Dictionary = JsonFile.read("res://data/voxels/nova_cat.json")
	raw["subdivide"] = 1
	var m := VxModel.from_dict(raw)
	check(m.errors.is_empty(), "Nova Cat original sculpt: " + ", ".join(m.errors))
	check_eq(m.muzzles[Location.LA].size(), 20, "one 20-tube left rack")
	check_eq(m.muzzles[Location.RA].size(), 40, "two 20-tube right racks")
	for loc in [Location.LA, Location.RA]:
		var p: Dictionary = m.part("la" if loc == Location.LA else "ra")
		var cells: Dictionary = p["cells"]
		var seen: Dictionary = {}
		for point: Vector3 in m.muzzles[loc]:
			var coord := Vector3i(floori(point.x), floori(point.y), -15)
			seen[coord] = true
			check(not cells.has(coord), "missile tube must have a true open muzzle " + str(coord))
			check(cells.has(coord + Vector3i(1, 0, 0)) or
					cells.has(coord + Vector3i(-1, 0, 0)), "port needs a physical rim")
		check_eq(seen.size(), m.muzzles[loc].size(), "each missile has a distinct port")


func test_new_chassis_use_connected_masses_and_solid_joints() -> void:
	# Inspect coarse authored volumes before subdivision; a single face-touching
	# component or a hidden floating island is not an acceptable model.
	for chassis in ["rook", "nova_cat"]:
		var raw: Dictionary = JsonFile.read("res://data/voxels/" + chassis + ".json")
		raw["subdivide"] = 1
		var m := VxModel.from_dict(raw)
		for part: Dictionary in m.parts:
			var cells: Dictionary = part["cells"]
			check(_one_solid(cells), chassis + ": disconnected mass inside " + part["name"])
			var parent_name: String = part["parent"]
			if parent_name.is_empty():
				continue
			var parent_cells: Dictionary = m.part(parent_name)["cells"]
			var contacts := 0
			for c: Vector3i in cells:
				for direction: Vector3i in VxPart.DIRS:
					if parent_cells.has(c + direction):
						contacts += 1
			check(contacts >= 4, chassis + ": insufficient physical mating surfaces at " + part["name"])


func _one_solid(cells: Dictionary) -> bool:
	if cells.is_empty():
		return false
	var remaining: Dictionary = {}
	for c: Vector3i in cells:
		remaining[c] = true
	var first: Vector3i = remaining.keys()[0]
	remaining.erase(first)
	var queue: Array[Vector3i] = [first]
	var cursor := 0
	while cursor < queue.size():
		var current: Vector3i = queue[cursor]
		cursor += 1
		for delta: Vector3i in VxPart.DIRS:
			var next: Vector3i = current + delta
			if remaining.has(next):
				remaining.erase(next)
				queue.append(next)
	if not remaining.is_empty():
		printerr("Disconnected voxel island, first unvisited cell: ", remaining.keys()[0],
				" (", remaining.size(), " unconnected cells)")
	return remaining.is_empty()
