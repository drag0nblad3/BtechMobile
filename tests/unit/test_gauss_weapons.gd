extends TestCase
## Light, heavy and improved heavy Gauss rifles, HAGs and plasma weapons.


func _unit(eq: Dictionary, uid := 1, side := 0, at := Vector2i.ZERO, facing := 2, tons := 60,
		tech := "inner_sphere") -> Unit:
	var d := UnitDef.from_dict({"id": "t%d" % uid, "name": "Test", "tonnage": tons, "walk_mp": 4, "tech_base": tech,
			"armor": {"HD": 9, "CT": 20, "LT": 15, "RT": 15, "LA": 10, "RA": 10, "LL": 15, "RL": 15},
			"equipment": eq}, weapons())
	return Unit.new(uid, d, side, at, facing)


func _shoot(a: Unit, dist: int, dice: LoadedDice) -> Array:
	var s := GameState.new(open_map(dist + 3, 3))
	a.coord = hex_at(0, 1)
	var t := _unit({"RA": ["medium_laser"]}, 2, 1, hex_at(dist, 1), 5)
	s.add_unit(a)
	s.add_unit(t)
	var ev := []
	WeaponFire.resolve(s, dice, func(ty: StringName, e: Dictionary) -> void: ev.append([ty, e]), a, a.weapons[0], t,
			ToHitCalc.weapon(s, a, a.weapons[0], t))
	return [ev, t]


func _damage(ev: Array) -> Array:
	return ev.filter(func(e: Array) -> bool: return e[0] == GameEvent.DAMAGE).map(func(e: Array) -> int: return e[1]["amount"])


func test_heavy_gauss_damage_by_range() -> void:
	var w := weapons().get_def("heavy_gauss_rifle")
	check_eq([w.damage_at(6), w.damage_at(13), w.damage_at(20)], [25, 20, 10])
	check_eq(weapons().get_def("light_gauss_rifle").long_range, 25)


func test_heavy_gauss_recoil_roll_after_moving() -> void:
	var a := _unit({"RT": ["heavy_gauss_rifle"], "LT": ["ammo:heavy_gauss_rifle"]}, 1, 0, Vector2i.ZERO, 2, 35)
	a.move_mode = MoveMode.Kind.WALK
	var dice := LoadedDice.new()
	dice.queue_2d6(2)  # miss
	_shoot(a, 5, dice)
	check_eq(a.psr_pending.size(), 1)
	check_eq(int(a.psr_pending[0]["mod"]), 2, "light 'Mech +2")
	var b := _unit({"RT": ["heavy_gauss_rifle"], "LT": ["ammo:heavy_gauss_rifle"]}, 3, 0, Vector2i.ZERO, 2, 85)
	var d2 := LoadedDice.new()
	d2.queue_2d6(2)
	_shoot(b, 5, d2)
	check(b.psr_pending.is_empty(), "standing still: no roll")


func test_hag_cluster_range_modifier() -> void:
	var w := weapons().get_def("c_hag20")
	check_eq([GaussWeapons.cluster_mod(w, 8), GaussWeapons.cluster_mod(w, 12), GaussWeapons.cluster_mod(w, 20)], [2, 0, -2])
	var a := _unit({"RT": ["c_hag20"], "LT": ["ammo:c_hag20"]}, 1, 0, Vector2i.ZERO, 2, 60, "clan")
	var dice := LoadedDice.new()
	dice.queue_2d6(12)  # hit
	dice.queue_2d6(5)  # cluster roll 5 + 2 = 7
	for i in 4:
		dice.queue_2d6(7)
	var ev: Array = _shoot(a, 4, dice)[0]
	var shot: Dictionary = ev.filter(func(e: Array) -> bool: return e[0] == GameEvent.WEAPON_FIRED)[0][1]
	check_eq(shot["missiles"], ClusterTable.hits(20, 7))
	check_eq(_damage(ev).reduce(func(s: int, x: int) -> int: return s + x, 0), 12)


func test_plasma_adds_heat() -> void:
	var a := _unit({"RA": ["c_plasma_cannon"], "RT": ["ammo:c_plasma_cannon"]}, 1, 0, Vector2i.ZERO, 2, 60, "clan")
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.d6_queue.append_array([4, 3])
	var r := _shoot(a, 4, dice)
	var t: Unit = r[1]
	check_eq(t.outside_heat, 7, "2d6 heat")
	check(_damage(r[0]).is_empty(), "no damage to a 'Mech")
	check_eq(a.ammo[0].explosion_damage(), 0, "plasma ammo doesn't explode")
