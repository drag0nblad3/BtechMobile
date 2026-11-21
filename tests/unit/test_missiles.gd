extends TestCase
## MRMs (-1 cluster roll), rocket launchers (one shot, +1 to hit), MMLs
## (SRM or LRM ammo) and Inner Sphere LB-X autocannons.


func _unit(eq: Dictionary, uid := 1, side := 0, at := Vector2i.ZERO, facing := 2) -> Unit:
	var d := UnitDef.from_dict({"id": "t%d" % uid, "name": "Test", "tonnage": 60, "walk_mp": 4,
			"armor": {"HD": 9, "CT": 20, "LT": 15, "RT": 15, "LA": 10, "RA": 10, "LL": 15, "RL": 15},
			"equipment": eq}, weapons())
	return Unit.new(uid, d, side, at, facing)


func _duel(eq: Dictionary, dist: int) -> Array:
	var s := GameState.new(open_map(dist + 3, 3))
	var a := _unit(eq, 1, 0, hex_at(0, 1), 2)
	var t := _unit({"RA": ["medium_laser"]}, 2, 1, hex_at(dist, 1), 5)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func test_mrm_cluster_roll_minus_one() -> void:
	var u := _unit({"RA": ["mrm10"], "RT": ["ammo:mrm10"]})
	var dice := LoadedDice.new()
	dice.queue_2d6(8)
	var c := WeaponModes.cluster(u.weapons[0], 1, dice)
	check_eq(c["n"], ClusterTable.hits(10, 7), "an 8 counts as a 7")
	check_eq(c["packets"], [5, 1], "6 missiles in 5-point groups")


func test_rocket_launcher_fires_once() -> void:
	var v := _duel({"RA": ["rl10"]}, 4)
	var s: GameState = v[0]
	var a: Unit = v[1]
	var t: Unit = v[2]
	var w := a.weapons[0]
	var th := ToHitCalc.weapon(s, a, w, t)
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "Rocket Launcher 10" and m["value"] == 1), th.summary())
	check(a.ammo.is_empty(), "no ammo bins")
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	WeaponFire.resolve(s, dice, func(_t, _d): pass, a, w, t, th)
	check_eq(a.heat_generated, 3)
	check(w.spent and not a.can_fire(w), "its one shot is gone")


func test_mml_switches_between_srm_and_lrm() -> void:
	var u := _unit({"RA": ["mml5"], "RT": ["ammo:mml5", "ammo:mml5:srm"]})
	var w := u.weapons[0]
	check_eq(WeaponModes.modes(w), ["", "srm"] as Array[String])
	check_eq([u.ammo[0].shots, u.ammo[1].shots], [24, 20], "24 LRMs or 20 SRMs a ton")
	var lrm := Atm.profile(w)
	check(lrm.indirect and lrm.min_range == 6 and lrm.long_range == 21, "LRM mode")
	w.mode = "srm"
	var srm := Atm.profile(w)
	check(not srm.indirect and srm.damage == 2 and srm.long_range == 9, "SRM mode")
	check_eq(u.ammo[1].explosion_damage(), 200, "20 SRMs x 5 missiles x 2")
	check(Atm.mode_text(w).begins_with("SRM missiles"), Atm.mode_text(w))


func test_mml_srm_ammo_runs_out_separately() -> void:
	var v := _duel({"RA": ["mml3"], "RT": ["ammo:mml3:srm"]}, 2)
	var a: Unit = v[1]
	var w := a.weapons[0]
	check_eq(w.mode, "srm", "starts on the ammo it has")
	check(a.can_fire(w))
	a.ammo[0].shots = 0
	check(not a.can_fire(w), "no SRMs left")


func test_inner_sphere_lbx() -> void:
	var u := _unit({"RA": ["lb5x_ac"], "LA": ["lb2x_ac"], "RT": ["ammo:lb5x_ac:cluster"]})
	check_eq(WeaponModes.modes(u.weapons[0]), ["", "cluster"] as Array[String])
	check_eq(weapons().get_def("lb20x_ac").slots, 11)
	check_eq(weapons().get_def("lb2x_ac").min_range, 4)
