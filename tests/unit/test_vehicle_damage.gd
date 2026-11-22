extends TestCase
## Combat vehicle damage: hit locations, motive system, critical hits.

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func _dice(rolls: Array) -> LoadedDice:
	var d := LoadedDice.new()
	for r: int in rolls:
		d.queue_2d6(r)
	return d


func _of(kind: String) -> Array:
	return events.filter(func(e: Array) -> bool: return e[0] == GameEvent.VEHICLE and e[1]["kind"] == kind)


func test_record_sheet_becomes_unit() -> void:
	var m := vehicle("manticore_heavy_tank", 0, hex_at(0, 0))
	check_eq(m.armor[VehicleLoc.TURRET], 42, "turret armor")
	check_eq(m.structure[VehicleLoc.REAR], 6, "6 structure")
	check_eq(m.structure[VehicleLoc.BODY], 1, "the body takes no hits")
	check_eq(m.legs_destroyed(), 0, "no legs to lose")
	check_eq(m.weapons.size(), 4, "four weapons")
	check_eq([m.walk_mp(), m.run_mp(), m.jump_mp()], [4, 6, 0], "cruise 4, flank 6")
	var h := vehicle("hetzer_wheeled_assault_gun", 0, hex_at(0, 0))
	check_eq(h.armor[VehicleLoc.TURRET], 0, "no turret")


func test_hit_table() -> void:
	check_eq(VehicleHitTable.roll(_dice([7]), FiringArc.FRONT, true)["loc"], VehicleLoc.FRONT, "7: the side it faces")
	var r5 := VehicleHitTable.roll(_dice([5]), FiringArc.FRONT, true)
	check(r5["loc"] == VehicleLoc.RIGHT and r5["motive"], "5 from the front: right side, motive roll")
	check_eq(VehicleHitTable.roll(_dice([9]), FiringArc.LEFT, true)["loc"], VehicleLoc.REAR, "9 from the left: rear")
	check_eq(VehicleHitTable.roll(_dice([10]), FiringArc.REAR, true)["loc"], VehicleLoc.TURRET, "10: turret")
	check_eq(VehicleHitTable.roll(_dice([10]), FiringArc.REAR, false)["loc"], VehicleLoc.REAR, "no turret: the rear instead")
	check(VehicleHitTable.roll(_dice([2]), FiringArc.FRONT, true)["crit"], "2: a critical check")


func test_location_loss_destroys_but_turret_blows_off() -> void:
	var m := vehicle("manticore_heavy_tank", 0, hex_at(0, 0))
	VehicleDamage.take(_dice([10, 2]), _emit, m, FiringArc.FRONT, 50, -1, "test")
	check(not m.destroyed, "losing the turret isn't fatal")
	check(m.vehicle.turret_lost, "turret gone")
	check_eq(m.weapons.filter(func(w: MountedWeapon) -> bool: return w.destroyed).size(), 3, "its weapons with it")
	VehicleDamage.take(_dice([7]), _emit, m, FiringArc.FRONT, 48, -1, "test")
	check(m.destroyed, "front structure gone: destroyed")


func test_motive_damage() -> void:
	var p := vehicle("pegasus_scout_hover_tank", 0, hex_at(0, 0))
	MotiveDamage.roll(_dice([7]), _emit, p, FiringArc.LEFT)
	check(p.vehicle.immobile, "hover hit from the side: 7 + 2 + 3 = major")
	check_eq(p.walk_mp(), 0, "can't move")
	var m := vehicle("manticore_heavy_tank", 0, hex_at(0, 0))
	MotiveDamage.roll(_dice([8]), _emit, m, FiringArc.FRONT)
	check_eq(m.walk_mp(), 3, "moderate: -1 Cruising MP")
	MotiveDamage.roll(_dice([10]), _emit, m, FiringArc.FRONT)
	check_eq(m.walk_mp(), 1, "heavy: then halved")


func test_critical_hits() -> void:
	var m := vehicle("manticore_heavy_tank", 0, hex_at(0, 0))
	VehicleCrits.roll(_dice([8]), _emit, m, VehicleLoc.LEFT)
	check_eq(m.vehicle.crew_stunned, 2, "crew stunned")
	check(not m.can_act(), "can't act")
	m.reset_for_turn()
	check(not m.can_act(), "nor next turn")
	m.reset_for_turn()
	check(m.can_act(), "then recovers")
	VehicleCrits.roll(_dice([11]), _emit, m, VehicleLoc.REAR)
	check(m.destroyed, "rear 11 with ammo aboard: it blows up")
	var d := vehicle("demolisher_heavy_tank_mk_i", 0, hex_at(0, 0))
	VehicleCrits.roll(_dice([10]), _emit, d, VehicleLoc.TURRET)
	check_eq(d.weapons.filter(func(w: MountedWeapon) -> bool: return w.destroyed).size(), 1, "one AC/20 destroyed")
	var p := vehicle("pegasus_scout_hover_tank", 0, hex_at(0, 0))
	VehicleCrits.roll(_dice([12]), _emit, p, VehicleLoc.LEFT)
	check(p.destroyed, "ICE fuel tank")
	var mm := vehicle("manticore_heavy_tank", 0, hex_at(0, 0))
	VehicleCrits.roll(_dice([12]), _emit, mm, VehicleLoc.RIGHT)
	check(not mm.destroyed and mm.vehicle.immobile, "fusion: an engine hit instead")


func test_weapon_fire_hits_vehicle() -> void:
	var s := GameState.new(make_map(["c0 c0 c0"]))
	var a := mech("griffin_grf1n", 0, hex_at(0, 0), 2, 1)
	var t := vehicle("vedette_medium_tank", 1, hex_at(2, 0), 5, 2)
	s.add_unit(a)
	s.add_unit(t)
	var w := gun(a, "ppc")
	var th := ToHitCalc.weapon(s, a, w, t)
	var before := t.armor[VehicleLoc.FRONT]
	WeaponFire.resolve(s, _dice([12, 7]), _emit, a, w, t, th)
	check_eq(t.armor[VehicleLoc.FRONT], before - 10, "PPC on the front armor")


func test_log_explains_vehicle_hits() -> void:
	var s := GameState.new(make_map(["c0"]))
	var m := vehicle("manticore_heavy_tank", 0, hex_at(0, 0), 0, 1)
	s.add_unit(m)
	VehicleDamage.take(_dice([10, 12, 9]), _emit, m, FiringArc.FRONT, 45, -1, "test")
	VehicleCrits.roll(_dice([6]), _emit, m, VehicleLoc.FRONT)
	MotiveDamage.roll(_dice([9]), _emit, m, FiringArc.REAR)
	for e: Array in events:
		var t := Explainer.text(GameEvent.new(e[0], e[1]), s, ExplainLevel.FULL)
		check(t != "", "text for %s" % e[0])
