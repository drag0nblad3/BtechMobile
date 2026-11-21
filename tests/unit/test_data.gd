extends TestCase
## Sanity checks on shipped data files.


func test_terrain_loads() -> void:
	var db := terrain()
	check(db.by_token.has("c"), "clear")
	check(db.by_token.has("w"), "water")


func test_units_load() -> void:
	var db := UnitDb.load_dir()
	check(db.by_id.size() >= 5, "unit count")
	check_eq(db.get_def("atlas_as7d").walk_mp, 3)


func test_scenario_loads() -> void:
	var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json",
			terrain(), UnitDb.load_dir())
	check_eq(s.map.width, 15)
	check_eq(s.map.height, 17)
	check_eq(s.units.size(), 4)
	for u in s.units:
		check(s.map.has(u.coord), "unit %d on map" % u.id)


func test_water_token() -> void:
	var t := MapLoader.parse_token("w0d2", Vector2i.ZERO, terrain())
	check_eq(t.depth, 2)
	check_eq(t.floor_level(), -2)
	check(t.is_water())


func test_every_design_is_legal() -> void:
	var db := UnitDb.load_dir()
	for def: UnitDef in db.by_id.values():
		var hs := 0
		var jj := 0
		for loc: int in def.other_items:
			hs += def.other_items[loc].count("heat_sink")
			jj += def.other_items[loc].count("jump_jet")
		var cap := DesignWeight.engine_sink_capacity(def)
		check(hs >= def.heat_sinks - cap and hs <= def.heat_sinks - UnitDef.ENGINE_HEAT_SINKS,
				"%s lists %d heat sinks; %d total, engine holds up to %d" % [def.id, hs, def.heat_sinks, cap])
		check_eq(jj, def.jump_mp, def.id + " jump jets")
		check(not def.weapon_mounts.is_empty(), def.id + " has weapons")
		for loc in Location.COUNT:
			check(def.armor[loc] <= StructureTable.max_armor(def.tonnage, loc),
					"%s %s armor over max" % [def.id, Location.code(loc)])
		var u := Unit.new(1, def, 0, Vector2i.ZERO, 0)
		check_eq(u.structure[Location.HEAD], 3)
		for w in u.weapons:
			if w.def.uses_ammo():
				check(u.ammo_for(w.def) + u.ammo_for(w.def, Narc.KIND) > 0, "%s ammo for %s" % [def.id, w.def.name])


func test_designs_weigh_their_tonnage() -> void:
	var db := UnitDb.load_dir()
	check(db.by_id.size() >= 30, "30+ designs")
	for def: UnitDef in db.by_id.values():
		var parts := DesignWeight.breakdown(def)
		check(parts["engine"] > 0.0, "%s engine rating %d in table" % [def.id, def.tonnage * def.walk_mp])
		var t := DesignWeight.total(def)
		check(t <= def.tonnage and t >= def.tonnage - 1.0,
				"%s weighs %.1f t, built as %d t" % [def.id, t, def.tonnage])
	check_eq(DesignWeight.total(db.get_def("atlas_as7d")), 100.0)


func test_equipment_fits_slots() -> void:
	var db := UnitDb.load_dir()
	for def: UnitDef in db.by_id.values():
		var want := 0
		for m in def.weapon_mounts:
			want += (m["weapon"] as WeaponDef).slots
			if m.get("artemis", false):
				want += 1
		want += def.ammo_mounts.size() + def.case_locs.size()
		if def.ecm_loc >= 0:
			want += 2
		if def.tc_loc >= 0:
			want += TargetingComputer.size(def)
		for loc: int in def.bulk_slots:
			want += def.bulk_slots[loc].size()
		for m in def.melee:
			want += def.melee_slots(m["kind"])
		for loc: int in def.other_items:
			for item: String in def.other_items[loc]:
				want += ClanTech.dhs_slots(def) if item == "heat_sink" and def.double_heat_sinks else 1
		var got := 0
		var u := Unit.new(1, def, 0, Vector2i.ZERO, 0)
		for loc in Location.COUNT:
			for s: CritSlot in u.slots[loc]:
				if s.kind in [CritSlot.Kind.WEAPON, CritSlot.Kind.AMMO, CritSlot.Kind.HEAT_SINK,
						CritSlot.Kind.JUMP_JET, CritSlot.Kind.CASE, CritSlot.Kind.ARTEMIS, CritSlot.Kind.MELEE,
						CritSlot.Kind.BULK, CritSlot.Kind.TARGETING, CritSlot.Kind.ECM]:
					got += 1
		check_eq(got, want, def.id + " every item has a critical slot")


func test_crit_layout() -> void:
	var u := Unit.new(1, UnitDb.load_dir().get_def("atlas_as7d"), 0, Vector2i.ZERO, 0)
	var rt: Array = u.slots[Location.RT]
	check_eq(rt.size(), 12)
	check_eq(rt[0].name, "AC/20")
	check_eq(rt[11].kind, CritSlot.Kind.AMMO)
	check_eq(u.slots[Location.CT][3].kind, CritSlot.Kind.GYRO)
	check(u.has_working_actuator(Location.LA, "hand"), "atlas has hands")
	var j := Unit.new(2, UnitDb.load_dir().get_def("jenner_jr7d"), 0, Vector2i.ZERO, 0)
	check(not j.has_working_actuator(Location.LA, "hand"), "jenner has no hands")
	check_eq(j.run_mp(), 11)


func test_structure_table() -> void:
	check_eq(StructureTable.points(100, Location.CT), 31)
	check_eq(StructureTable.points(35, Location.LA), 6)
	check_eq(StructureTable.points(65, Location.LL), 15)
	check_eq(StructureTable.max_armor(50, Location.HEAD), 9)


func test_roster_spans_weight_classes() -> void:
	var classes := {}
	for def: UnitDef in UnitDb.load_dir().by_id.values():
		classes[def.weight_class()] = true
		check(def.role != "", def.id + " has a role line")
		check(def.sprite != "", def.id + " names a sprite folder")
	check_eq(classes.size(), 4, "light, medium, heavy and assault")
