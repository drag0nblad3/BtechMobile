extends TestCase
## Combat vehicle record sheets (data/vehicles/): loading and data checks.


func test_vehicles_load_apart_from_mechs() -> void:
	var db := UnitDb.load_dir()
	check(db.vehicles.size() >= 20, "vehicle sheets loaded (%d)" % db.vehicles.size())
	check(not db.by_id.has("manticore_heavy_tank"), "not in the 'Mech list")
	check(db.get_def("manticore_heavy_tank") != null, "found by id")
	var clan := 0
	for d: UnitDef in db.vehicles.values():
		check(d.vehicle != null and d.vehicle.cruise_mp > 0, d.id + " has a motive system")
		check(d.bv > 0 and d.source.get("bv", "") == "sheet", d.id + " BV from its official sheet")
		check(d.source.get("megamek", "") != "", d.id + " loadout from MegaMek")
		check(not d.weapon_mounts.is_empty(), d.id + " is armed")
		for m in d.weapon_mounts:
			check(m["weapon"] != null and m["loc"] >= 0 and m["loc"] < VehicleLoc.BODY, d.id + " weapon placed")
		if d.tech_base == "clan":
			clan += 1
	check(clan >= 4, "some Clan vehicles (%d)" % clan)


func test_manticore_sheet() -> void:
	var d := UnitDb.load_dir().get_def("manticore_heavy_tank")
	check_eq(d.tonnage, 60, "60 tons")
	check_eq(d.vehicle.motive, "t", "tracked")
	check_eq(d.walk_mp, 4, "cruise 4")
	check_eq(d.vehicle.flank_mp(), 6, "flank 6")
	check(d.vehicle.turret, "has a turret")
	check_eq([d.armor[VehicleLoc.FRONT], d.armor[VehicleLoc.LEFT], d.armor[VehicleLoc.RIGHT],
			d.armor[VehicleLoc.REAR], d.armor[VehicleLoc.TURRET]], [42, 33, 33, 26, 42], "armor per location")
	var turret := d.weapon_mounts.filter(func(m: Dictionary) -> bool: return m["loc"] == VehicleLoc.TURRET)
	check_eq(turret.size(), 3, "PPC, LRM 10, SRM 6 in the turret")
	check_eq(d.ammo_mounts.size(), 2, "two ammo bins in the body")
	check_eq(VehicleLoc.structure(d.tonnage), 6, "6 structure per location")
	check_eq(d.bv, 993, "sheet BV")
