extends TestCase
## Line of sight, arcs, to-hit numbers, damage and the weapon phase.


func test_arcs() -> void:
	var c := hex_at(5, 5)
	check_eq(FiringArc.arc(c, 0, Hex.neighbor(c, 0)), FiringArc.FRONT, "ahead")
	check_eq(FiringArc.arc(c, 0, Hex.neighbor(c, 1)), FiringArc.FRONT, "front right")
	check_eq(FiringArc.arc(c, 0, Hex.neighbor(c, 2)), FiringArc.RIGHT, "right")
	check_eq(FiringArc.arc(c, 0, Hex.neighbor(c, 3)), FiringArc.REAR, "behind")
	check_eq(FiringArc.arc(c, 0, Hex.neighbor(c, 4)), FiringArc.LEFT, "left")
	check_eq(FiringArc.arc(c, 2, Hex.neighbor(c, 5)), FiringArc.REAR, "turned")
	check(FiringArc.weapon_covers(Location.RA, false, FiringArc.RIGHT), "arm covers side")
	check(not FiringArc.weapon_covers(Location.RT, false, FiringArc.RIGHT), "torso doesn't")
	check(FiringArc.weapon_covers(Location.CT, true, FiringArc.REAR), "rear mount")


func test_los_woods_and_hills() -> void:
	var s := GameState.new(make_map(["c0 L0 H0 c0 c0", "c0 c2 c0 c0 c0"]))
	var a := mech("hunchback_hbk4g", 0, hex_at(0, 0), 2, 1)
	var b := mech("hunchback_hbk4g", 1, hex_at(3, 0), 5, 2)
	var los := LineOfSight.check(s.map, a, b)
	check(los["blocked"], "3 points of woods block")
	check_eq(los["woods"], 3)
	check(LineOfSight.check(s.map, a, b)["woods"] >= 3, "woods counted")
	var c := mech("hunchback_hbk4g", 1, hex_at(2, 1), 5, 3)
	var d := mech("hunchback_hbk4g", 0, hex_at(0, 1), 2, 4)
	check(LineOfSight.check(s.map, d, c)["blocked"], "level 2 hill blocks")


func test_to_hit_modifiers() -> void:
	var s := GameState.new(open_map(12, 3))
	var a := mech("hunchback_hbk4g", 0, hex_at(0, 1), 2, 1)
	var b := mech("hunchback_hbk4g", 1, hex_at(5, 1), 5, 2)
	s.add_unit(a)
	s.add_unit(b)
	a.move_mode = MoveMode.Kind.WALK
	b.hexes_moved = 5
	var ml := a.weapons[2]  # LA medium laser
	check_eq(ml.def.id, "medium_laser")
	var th := ToHitCalc.weapon(s, a, ml, b)
	# 4 gunnery + 1 walked + 2 target moved 5 + 2 medium range (5 hexes)
	check_eq(th.target(), 9, th.summary())
	check(absf(th.chance() - 10.0 / 36.0) < 0.001, "9+ is 10/36")
	var ac := a.weapons[1]
	check_eq(ac.def.id, "ac20")
	check_eq(ToHitCalc.weapon(s, a, ac, b).target(), 9, "AC/20 at 5 is medium")


func test_minimum_range_and_out_of_range() -> void:
	var s := GameState.new(open_map(25, 3))
	var a := mech("catapult_cplt_c1", 0, hex_at(0, 1), 2, 1)
	var b := mech("hunchback_hbk4g", 1, hex_at(2, 1), 5, 2)
	s.add_unit(a)
	s.add_unit(b)
	var lrm := a.weapons[4]
	check_eq(lrm.def.id, "lrm15")
	# 2 hexes, min 6: +5
	check_eq(ToHitCalc.weapon(s, a, lrm, b).target(), 9)
	b.coord = hex_at(23, 1)
	check(not ToHitCalc.weapon(s, a, lrm, b).possible(), "23 hexes is out of range")


func test_damage_transfers_inward() -> void:
	var u := mech("jenner_jr7d", 0, Vector2i.ZERO)
	# LA: 6 armor + 6 structure; 20 damage leaves 8 for LT.
	var steps := Damage.apply(u, Location.LA, 20)
	check(u.is_location_destroyed(Location.LA), "arm gone")
	check_eq(steps.size(), 2)
	check_eq(u.armor[Location.LT], 4, "LT armor 12 - 8")
	check(u.weapons[2].destroyed, "arm lasers destroyed")
	Damage.apply(u, Location.CT, 15 + 11)
	check(u.destroyed, "center torso destroyed")


func test_side_torso_takes_arm() -> void:
	var u := mech("hunchback_hbk4g", 0, Vector2i.ZERO)
	Damage.apply(u, Location.RT, 20 + 12)
	check(u.is_location_destroyed(Location.RT), "RT")
	check(u.is_location_destroyed(Location.RA), "RA goes with RT")
	check(not u.destroyed, "still alive")


func test_rear_armor() -> void:
	var u := mech("atlas_as7d", 0, Vector2i.ZERO)
	Damage.apply(u, Location.CT, 10, true)
	check_eq(u.rear_armor[Location.CT], 4)
	check_eq(u.armor[Location.CT], 47, "front untouched")


func test_cluster_table() -> void:
	check_eq(ClusterTable.hits(15, 7), 9)
	check_eq(ClusterTable.hits(6, 2), 2)
	check_eq(ClusterTable.hits(20, 12), 20)
	check_eq(Damage.clusters(13, 5), [5, 5, 3] as Array[int])


func test_weapon_phase_and_heat() -> void:
	var s := GameState.new(open_map(8, 3))
	var a := mech("jenner_jr7d", 0, hex_at(0, 1), 2, 1)
	var b := mech("hunchback_hbk4g", 1, hex_at(3, 1), 5, 2)
	s.add_unit(a)
	s.add_unit(b)
	var gc := GameController.new(s, 42)
	gc.start_turn()
	for u in [s.unit_by_id(1), s.unit_by_id(2)]:
		var mover := gc.pending_units()[0]
		gc.submit_move(mover, MoveOptions.key(mover.coord, mover.facing), 0)
	check_eq(s.phase, Phase.Kind.WEAPON_ATTACK)
	for i in 2:
		var shooter := gc.pending_units()[0]
		var shots := []
		if shooter == a:
			for wi in a.weapons.size():
				shots.append({"weapon": wi, "target_id": b.id})
		gc.declare_fire(shooter, shots)
	check_eq(s.turn, 2, "turn advanced after heat and end")
	# Jenner fired 4 ML (12) + SRM 4 (3) = 15 heat with 10 sinks.
	check_eq(a.heat, 5, "jenner heat after dissipation")
	check_eq(a.ammo_for(a.weapons[0].def), 24, "one SRM shot used")
	var fired := 0
	for e in gc.history:
		if e.type == GameEvent.WEAPON_FIRED:
			fired += 1
	check_eq(fired, 5, "five weapons resolved")


func test_heat_scale() -> void:
	check_eq(HeatScale.mp_penalty(4), 0)
	check_eq(HeatScale.mp_penalty(10), 2)
	check_eq(HeatScale.to_hit_penalty(13), 2)
	check_eq(HeatScale.shutdown_avoid(14), 4)
	check_eq(HeatScale.shutdown_avoid(30), 99)
	check_eq(HeatScale.ammo_explosion_avoid(19), 4)


func test_ammo_explosion() -> void:
	var s := GameState.new(open_map(3, 3))
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1), 0, 1)
	s.add_unit(u)
	var gc := GameController.new(s, 7)
	# 5 AC/20 shots x 20 = 100 damage into LT structure: destroys LT and more.
	AmmoExplosion.explode(s, gc.dice, gc._emit_cb, u, u.ammo[0])
	check(u.is_location_destroyed(Location.LT), "LT gone")
	check_eq(u.pilot.hits, 2, "pilot hurt")
