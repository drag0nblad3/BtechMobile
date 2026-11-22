extends TestCase
## X-pulse, variable-speed pulse (VSP) and Clan improved heavy lasers.


func _unit(eq: Dictionary, uid := 1, side := 0, at := Vector2i.ZERO, facing := 2, tech := "inner_sphere") -> Unit:
	var d := UnitDef.from_dict({"id": "t%d" % uid, "name": "Test", "tonnage": 60, "walk_mp": 4, "tech_base": tech,
			"armor": {"HD": 9, "CT": 20, "LT": 15, "RT": 15, "LA": 10, "RA": 10, "LL": 15, "RL": 15},
			"equipment": eq}, weapons())
	return Unit.new(uid, d, side, at, facing)


func _own_mod(eq: Dictionary, dist: int) -> int:
	var s := GameState.new(open_map(dist + 3, 3))
	var a := _unit(eq, 1, 0, hex_at(0, 1), 2)
	var t := _unit({"RA": ["medium_laser"]}, 2, 1, hex_at(dist, 1), 5)
	s.add_unit(a)
	s.add_unit(t)
	var th := ToHitCalc.weapon(s, a, a.weapons[0], t)
	var m := th.mods.filter(func(x: Dictionary) -> bool: return x["label"] == a.weapons[0].def.name)
	return int(m[0]["value"]) if not m.is_empty() else 0


func test_vsp_to_hit_and_damage_by_range() -> void:
	check_eq([_own_mod({"RA": ["vsp_medium_laser"]}, 2), _own_mod({"RA": ["vsp_medium_laser"]}, 4),
			_own_mod({"RA": ["vsp_medium_laser"]}, 8)], [-3, -2, -1])
	var w := weapons().get_def("vsp_medium_laser")
	check_eq([w.damage_at(2), w.damage_at(5), w.damage_at(9)], [9, 7, 5])


func test_x_pulse_laser() -> void:
	check_eq(_own_mod({"RA": ["x_pulse_medium_laser"]}, 4), -2)
	check_eq(weapons().get_def("x_pulse_medium_laser").heat, 6)


func test_improved_heavy_laser_no_penalty_but_explodes() -> void:
	check_eq(_own_mod({"RA": ["c_improved_heavy_medium_laser"]}, 2), 0, "no +1 unlike a heavy laser")
	check_eq(_own_mod({"RA": ["c_heavy_medium_laser"]}, 2), 1)
	var u := _unit({"RA": ["c_improved_heavy_large_laser"]}, 1, 0, Vector2i.ZERO, 2, "clan")
	check(u.weapons[0].def.explodes)
	check_eq(ComponentExplosion.damage(u.weapons[0]), 6, "2 a slot (p. 96)")
	check_eq(ComponentExplosion.damage(_unit({"RA": ["gauss_rifle"]}).weapons[0]), 14, "Gauss: 2 a slot")
