extends TestCase
## Homing and smoke Arrow IV missiles (ArrowHoming, ArrowSmoke, pp. 190-191), TAG surcharge (HomingBv).


func _def(id: String, eq: Dictionary) -> UnitDef:
	return UnitDef.from_dict({"id": id, "name": id, "tonnage": 75, "walk_mp": 4,
			"armor": {"CT": 30, "LT": 20, "RT": 20, "LA": 20, "RA": 20, "LL": 20, "RL": 20, "HD": 9},
			"rear_armor": {"CT": 10, "LT": 8, "RT": 8}, "equipment": eq}, weapons())


func _armor(u: Unit) -> int:
	var n := 0
	for a in u.armor + u.rear_armor:
		n += a
	return n


func _setup(ammo: String) -> Array:
	var s := GameState.new(open_map(30, 5))
	var a := Unit.new(1, _def("a", {"RA": ["arrow_iv~7"], "RT": [ammo]}), 0, hex_at(1, 2), 2)
	var t := Unit.new(2, _def("t", {}), 1, hex_at(11, 2), 5)
	var b := Unit.new(3, _def("b", {}), 1, hex_at(11, 2), 5)
	for u in [a, t, b]:
		s.add_unit(u)
	return [s, a, t, b]


func _fire(v: Array, dice: LoadedDice) -> void:
	var a: Unit = v[1]
	for i in 20:
		dice.d6_queue.append_array([3, 4])  # center torso hits
	WeaponFire.resolve(v[0], dice, func(_t: Variant, _d: Dictionary) -> void: pass, a, a.weapons[0], v[2],
			ToHitCalc.weapon(v[0], a, a.weapons[0], v[2]))


func test_homing_needs_a_tag() -> void:
	var v := _setup("ammo:arrow_iv:homing")
	var th := ToHitCalc.weapon(v[0], v[1], v[1].weapons[0], v[2])
	check_eq(th.target(), 4, "a flat 4+")
	var t0 := _armor(v[2])
	_fire(v, LoadedDice.new())
	check_eq(t0 - _armor(v[2]), 0, "no TAG: the missile is lost, no scatter")


func test_homing_hit_and_miss() -> void:
	for roll in [6, 3]:
		var v := _setup("ammo:arrow_iv:homing")
		var s: GameState = v[0]
		s.tagged[v[2].id] = {"by": v[1].id, "turn": s.turn}
		var t0 := _armor(v[2])
		var b0 := _armor(v[3])
		var dice := LoadedDice.new()
		dice.queue_2d6(roll)
		_fire(v, dice)
		check_eq(t0 - _armor(v[2]), 20 if roll >= 4 else 5, "hit: 20 to the designated 'Mech; miss: 5 AE")
		check_eq(b0 - _armor(v[3]), 5, "5 AE to the other 'Mech in the hex")


func test_smoke_fills_then_thins() -> void:
	var v := _setup("ammo:arrow_iv:smoke")
	var s: GameState = v[0]
	var c: Vector2i = v[2].coord
	var t0 := _armor(v[2])
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	_fire(v, dice)
	check_eq(t0 - _armor(v[2]), 0, "smoke does no damage")
	check_eq(s.smoke_pending.size(), 7, "the hex and the six around it")
	check_eq(s.map.get_tile(c).smoke, 0, "not until the phase ends")
	var emit := func(_t: Variant, _d: Dictionary) -> void: pass
	ArrowSmoke.apply_pending(s, emit)
	check_eq(Obscurant.value(s.map, s.map.get_tile(Hex.neighbor(c, 3))), 2, "heavy smoke next door")
	ArrowSmoke.end_phase(s, emit)
	check_eq(s.map.get_tile(c).smoke, 2, "still heavy at the end of its own turn")
	s.turn += 1
	ArrowSmoke.end_phase(s, emit)
	check_eq(s.map.get_tile(c).smoke, 1, "light a turn later")
	s.turn += 1
	ArrowSmoke.end_phase(s, emit)
	check_eq(s.map.get_tile(c).smoke, 0, "gone the turn after")


func test_tag_surcharge() -> void:
	var arrow := _def("x", {"RA": ["arrow_iv~7"], "RT": ["ammo:arrow_iv:homing"]})
	var tagger := _def("y", {"LT": ["tag"]})
	var n := HomingBv.launchers([arrow, tagger])
	check_eq(n, 1)
	check_eq(HomingBv.surcharge(tagger, n), 50, "50 per homing launcher for each TAG")
	check_eq(HomingBv.surcharge(arrow, n), 0, "no TAG, no surcharge")


func test_smoke_survives_a_save() -> void:
	var s := GameState.new(open_map(8, 4))
	var tile := s.map.get_tile(hex_at(5, 2))
	tile.smoke = 2
	tile.smoke_turn = 3
	s.smoke_pending.append(hex_at(6, 2))
	var payload := BattleSave.capture(GameController.new(s, 7), [1], BotSkill.Level.REGULAR, -1, [])
	var back := BattleSave.restore(payload, designs(), terrain())
	check(not back.is_empty(), "restores")
	if back.is_empty():
		return
	var rs: GameState = back["controller"].state
	check_eq(rs.map.get_tile(hex_at(5, 2)).smoke, 2)
	check_eq(rs.map.get_tile(hex_at(5, 2)).smoke_turn, 3)
	check_eq(rs.smoke_pending.size(), 1)
