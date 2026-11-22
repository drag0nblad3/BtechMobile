extends TestCase
## Arrow IV artillery missiles (ArrowIv, AreaEffect, pp. 181-182).


func _def(id: String, eq: Dictionary) -> UnitDef:
	return UnitDef.from_dict({"id": id, "name": id, "tonnage": 75, "walk_mp": 4,
			"armor": {"CT": 30, "LT": 20, "RT": 20, "LA": 20, "RA": 20, "LL": 20, "RL": 20, "HD": 9},
			"rear_armor": {"CT": 10, "LT": 8, "RT": 8}, "equipment": eq}, weapons())


func _armor(u: Unit) -> int:
	var n := 0
	for a in u.armor + u.rear_armor:
		n += a
	return n


## A launcher at column 1 facing the targets down the row.
func _setup(dist: int) -> Array:
	var s := GameState.new(open_map(30, 5))
	var a := Unit.new(1, _def("a", {"RA": ["arrow_iv~7"], "RT": ["ammo:arrow_iv"]}), 0, hex_at(1, 2), 2)
	var t := Unit.new(2, _def("t", {}), 1, hex_at(1 + dist, 2), 5)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


## Every hit location roll a 7 (center torso), so no head hits end the test early.
func _center_hits(dice: LoadedDice) -> void:
	for i in 20:
		dice.d6_queue.append_array([3, 4])


func _fire(v: Array, dice: LoadedDice) -> void:
	var a: Unit = v[1]
	WeaponFire.resolve(v[0], dice, func(_t: Variant, _d: Dictionary) -> void: pass, a, a.weapons[0], v[2],
			ToHitCalc.weapon(v[0], a, a.weapons[0], v[2]))


func test_to_hit() -> void:
	var v := _setup(10)
	var th := ToHitCalc.weapon(v[0], v[1], v[1].weapons[0], v[2])
	check(th.possible(), th.impossible)
	check_eq(th.target(), 8, "Gunnery 4 + 4, no range or target movement")
	var near := _setup(6)
	check(not ToHitCalc.weapon(near[0], near[1], near[1].weapons[0], near[2]).possible(), "6 hexes is too close")


func test_close_hit_blasts_the_hex_and_around() -> void:
	var v := _setup(10)
	var s: GameState = v[0]
	var t: Unit = v[2]
	var b := Unit.new(3, _def("b", {}), 1, Hex.neighbor(t.coord, 0), 5)
	s.add_unit(b)
	var t0 := _armor(t)
	var b0 := _armor(b)
	var dice := LoadedDice.new()
	dice.queue_2d6(10)
	_center_hits(dice)
	_fire(v, dice)
	check_eq(t0 - _armor(t), 20, "20 in the target hex")
	check_eq(b0 - _armor(b), 10, "10 next door")
	check_eq(v[1].heat_generated, 10, "10 heat")


func test_miss_scatters() -> void:
	var v := _setup(10)
	var t: Unit = v[2]
	var t0 := _armor(t)
	var dice := LoadedDice.new()
	dice.queue_2d6(5)  # needs 8: margin 3, scatters 2
	dice.d6_queue.append(1)  # on past the target
	_fire(v, dice)
	check_eq(t0 - _armor(t), 0, "two hexes past: the target isn't touched")
	var v2 := _setup(10)
	var dice2 := LoadedDice.new()
	dice2.queue_2d6(7)  # margin 1: one hex
	dice2.d6_queue.append(1)
	_center_hits(dice2)
	var t2: Unit = v2[2]
	var a0 := _armor(t2)
	_fire(v2, dice2)
	check_eq(a0 - _armor(t2), 10, "one hex past: the target takes the 10 of the ring")


func test_distant_lands_next_turn() -> void:
	var v := _setup(20)
	var s: GameState = v[0]
	var t: Unit = v[2]
	var c := t.coord
	var dice := LoadedDice.new()
	_fire(v, dice)
	check_eq(s.artillery.size(), 1, "in flight")
	check_eq(v[1].heat_generated, 10, "heat when launched")
	t.coord = Hex.neighbor(c, 1)  # it moves one hex
	t.coord = Hex.neighbor(t.coord, 1)  # and another: out of the blast
	var t0 := _armor(t)
	s.turn += 1
	dice.queue_2d6(12)
	ArrowIv.resolve_due(s, dice, func(_t: Variant, _d: Dictionary) -> void: pass)
	check(s.artillery.is_empty(), "landed")
	check_eq(t0 - _armor(t), 0, "it lands on the hex, and the target has left")
