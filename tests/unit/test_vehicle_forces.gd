extends TestCase
## Combat vehicles in the force builder, deployment, nameplates and the
## record sheet panel.


func test_force_builder_buys_vehicles_as_support() -> void:
	var db := UnitDb.load_dir()
	var fb := ForceBuilder.new(db, 12000)
	check(fb.add(0, "atlas_as7d"), "a 'Mech")
	var before := fb.bv(0)
	check(fb.add(0, "manticore_heavy_tank"), "a vehicle")
	check_eq(fb.bv(0) - before, 993, "sheet BV at the default 4/5 crew")
	check_eq(fb.asset_ids(0).size(), 1, "counts as support")
	check_eq(fb.mech_ids(0).size(), 1, "not a 'Mech")
	for i in 3:
		fb.add(0, "pegasus_scout_hover_tank")
	check(fb.cant_add(0, "srm_carrier") != "", "at most four support units")
	check(fb.cant_add(0, "griffin_grf1n") == "", "'Mech slots still open")


func test_vehicle_bv_follows_crew_skill() -> void:
	var fb := ForceBuilder.new(UnitDb.load_dir(), 12000)
	var def := fb.units.get_def("manticore_heavy_tank")
	var regular := fb.unit_bv(0, def)
	fb.skills[0] = Vector2i(3, 4)
	check(fb.unit_bv(0, def) > regular, "a better crew costs more")


func test_built_vehicles_deploy_on_ground_they_can_use() -> void:
	var fb := ForceBuilder.new(UnitDb.load_dir(), 12000)
	fb.add(0, "atlas_as7d")
	fb.add(0, "pegasus_scout_hover_tank")
	fb.add(0, "hetzer_wheeled_assault_gun")
	fb.add(1, "griffin_grf1n")
	var map := MapLoader.load_file("res://data/maps/river_crossing.json", terrain())
	var s := fb.build(map)
	var vs: Array = s.units.filter(func(u: Unit) -> bool: return u.vehicle != null)
	check_eq(vs.size(), 2)
	for u: Unit in vs:
		check(VehicleMoveCost.may_enter(u.def.vehicle.motive, s.map.get_tile(u.coord)), "%s deployed legally" % u.def.name)
		check(u.pilot != null and u.pilot.gunnery == 4, "crew skill from the side")


func test_plate_health_counts_vehicle_locations() -> void:
	var tank := vehicle("manticore_heavy_tank", 0, hex_at(0, 0))
	check_eq(PlateInfo.health(tank), 1.0, "undamaged")
	tank.armor[VehicleLoc.FRONT] = 0
	var h := PlateInfo.health(tank)
	check(h < 1.0 and h > 0.5, "front armor gone: %f" % h)


func test_vehicle_sheet_text() -> void:
	var tank := vehicle("manticore_heavy_tank", 0, hex_at(0, 0))
	tank.vehicle.turret_locked = true
	var t := VehicleSheetView.text(tank)
	check(t.contains("cruise") and t.contains("TU  armor"), "MP and turret line")
	check(t.contains("turret locked"), "damage listed")
	check(not t.contains("Heat "), "no heat scale")


func test_vehicles_cruise_and_flank() -> void:
	var tank := vehicle("manticore_heavy_tank", 0, hex_at(0, 0))
	check_eq(AssetMove.mode_name(tank, MoveMode.Kind.WALK), "Cruise")
	check_eq(AssetMove.mode_name(tank, MoveMode.Kind.RUN), "Flank")
	check_eq(MoveMode.verb_for(tank, MoveMode.Kind.RUN), "flanked")
	var mech := mech("griffin_grf1n", 1, hex_at(2, 0))
	check_eq(AssetMove.mode_name(mech, MoveMode.Kind.RUN), "Run")
	check_eq(MoveMode.verb_for(mech, MoveMode.Kind.RUN), "ran")
