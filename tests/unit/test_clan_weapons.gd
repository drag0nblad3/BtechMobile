extends TestCase
## Clan weapon stats (book p. 251-252 tables) and their special to-hit rules.


func _shot(weapon_id: String, dist: int) -> ToHit:
	var s := GameState.new(open_map(30, 4))
	var eq := {"RA": [weapon_id]}
	if weapons().get_def(weapon_id).uses_ammo():
		eq["RT"] = ["ammo:" + weapon_id]
	var d := UnitDef.from_dict({"id": "a", "name": "a", "tonnage": 50, "walk_mp": 4,
			"armor": {"CT": 20}, "equipment": eq}, weapons())
	var a := Unit.new(1, d, 0, hex_at(1, 2), 2)
	var t := Unit.new(2, make_def(4), 1, hex_at(1 + dist, 2), 5)
	s.add_unit(a)
	s.add_unit(t)
	return ToHitCalc.weapon(s, a, a.weapons[0], t)


func _mod(th: ToHit, label: String) -> int:
	for m in th.mods:
		if m["label"] == label:
			return int(m["value"])
	return 0


func test_clan_versions_beat_inner_sphere() -> void:
	var db := weapons()
	var c := db.get_def("c_er_medium_laser")
	var i := db.get_def("er_medium_laser")
	check(c.is_clan() and not i.is_clan())
	check_eq([c.damage, c.heat, c.long_range], [7, 5, 15])
	check_eq([i.damage, i.long_range], [5, 12])
	check_eq(db.get_def("c_er_ppc").damage, 15)
	check_eq(db.get_def("c_er_ppc").tons, 6.0)
	check_eq(db.get_def("c_lrm20").min_range, 0, "Clan LRMs have no minimum range")
	check_eq(db.get_def("c_lrm20").slots, 4)
	check_eq(db.get_def("c_gauss_rifle").tons, 12.0)
	for w: WeaponDef in db.by_id.values():
		check_eq(w.is_clan(), w.id.begins_with("c_"), w.id)


func test_heavy_and_er_pulse_mods() -> void:
	check_eq(_mod(_shot("c_heavy_medium_laser", 2), "Heavy Medium Laser"), 1, "heavy lasers +1")
	check_eq(_mod(_shot("c_er_medium_pulse_laser", 2), "ER Medium Pulse Laser"), -1, "ER pulse -1")
	check_eq(_mod(_shot("c_medium_pulse_laser", 2), "Medium Pulse Laser"), -2, "pulse -2")


func test_ranges() -> void:
	check(_shot("c_er_large_laser", 25).possible(), "ER large laser reaches 25")
	check(not _shot("c_er_large_laser", 26).possible())
	check(not _shot("c_heavy_machine_gun", 3).possible(), "HMG has no long range")
	check_eq(_mod(_shot("c_lrm10", 2), "minimum range"), 0, "no minimum range penalty")
	check_eq(_mod(_shot("c_lb2x_ac", 2), "minimum range"), 3, "LB 2-X keeps one")


func test_streak_lrm_hits_with_everything_in_fives() -> void:
	var s := GameState.new(open_map(30, 4))
	var d := UnitDef.from_dict({"id": "a", "name": "a", "tonnage": 50, "walk_mp": 4,
			"armor": {"CT": 20}, "equipment": {"RT": ["c_streak_lrm20", "ammo:c_streak_lrm20"]}}, weapons())
	var a := Unit.new(1, d, 0, hex_at(1, 2), 2)
	var t := Unit.new(2, make_def(4), 1, hex_at(4, 2), 5)
	s.add_unit(a)
	s.add_unit(t)
	check(not a.weapons[0].def.indirect, "no indirect fire")
	check_eq(_mod(ToHitCalc.weapon(s, a, a.weapons[0], t), "minimum range"), 0)
	var dice := LoadedDice.new()
	dice.queue_2d6(2)  # miss: holds fire
	var ev := []
	var log := func(ty: StringName, e: Dictionary) -> void: ev.append([ty, e])
	WeaponFire.resolve(s, dice, log, a, a.weapons[0], t, ToHitCalc.weapon(s, a, a.weapons[0], t))
	check_eq(a.ammo_for(a.weapons[0].def), 6, "no ammo used")
	check_eq(a.heat_generated, 0)
	ev.clear()
	dice.queue_2d6(12)
	for i in 4:
		dice.queue_2d6(7)
	WeaponFire.resolve(s, dice, log, a, a.weapons[0], t, ToHitCalc.weapon(s, a, a.weapons[0], t))
	var dmg := ev.filter(func(e: Array) -> bool: return e[0] == GameEvent.DAMAGE).map(func(e: Array) -> int: return e[1]["amount"])
	check_eq(dmg, [5, 5, 5, 5], "all 20 missiles in groups of 5")


func test_streak_log_explains_the_lock() -> void:
	var t := WeaponText.fired(GameState.new(open_map(4, 4)), {"attacker_id": 1, "target_id": 2, "weapon": "Streak SRM 6",
			"roll": 9, "need": 7, "hit": true, "mods": [], "missiles": 6, "streak_lock": true}, ExplainLevel.FULL, {})
	check(t.contains("every missile hits"), t)
