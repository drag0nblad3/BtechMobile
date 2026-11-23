extends TestCase
## Bot area-effect fire: Arrow IV munitions, friends in the blast, TAG for homing (BotArtillery).


func _def(id: String, eq: Dictionary) -> UnitDef:
	return UnitDef.from_dict({"id": id, "name": id, "tonnage": 75, "walk_mp": 4,
			"armor": {"CT": 30, "LT": 20, "RT": 20, "LA": 20, "RA": 20, "LL": 20, "RL": 20, "HD": 9},
			"rear_armor": {"CT": 10, "LT": 8, "RT": 8}, "equipment": eq}, weapons())


func _setup(ammo: Array) -> Array:
	var s := GameState.new(open_map(30, 5))
	var a := Unit.new(1, _def("a", {"RA": ["arrow_iv~7"], "RT": ammo}), 0, hex_at(1, 2), 2)
	var e := Unit.new(2, _def("e", {}), 1, hex_at(11, 2), 5)
	s.add_unit(a)
	s.add_unit(e)
	return [s, a, e]


func _value(v: Array) -> float:
	var a: Unit = v[1]
	return BotArtillery.value(v[0], a, a.weapons[0], v[2], ToHitCalc.weapon(v[0], a, a.weapons[0], v[2]))


func test_friends_in_the_blast_count_against() -> void:
	var v := _setup(["ammo:arrow_iv"])
	var alone := _value(v)
	check(alone > 0.0, "worth firing at a lone enemy")
	var f := Unit.new(3, _def("f", {}), 0, Hex.neighbor(v[2].coord, 1), 0)
	v[0].add_unit(f)
	check(_value(v) < alone, "a friend next door makes it worth less")
	f.coord = v[2].coord
	check(_value(v) <= 0.0, "never with a friend in the target hex")


func test_homing_only_with_a_tag() -> void:
	var v := _setup(["ammo:arrow_iv", "ammo:arrow_iv:homing"])
	var s: GameState = v[0]
	var a: Unit = v[1]
	var w := a.weapons[0]
	check_eq(BotArtillery.best_mode(s, a, w, v[2], w.ammo_kinds), "", "no TAG: standard missiles")
	s.tagged[v[2].id] = {"by": a.id, "turn": s.turn}
	check_eq(BotArtillery.best_mode(s, a, w, v[2], w.ammo_kinds), ArrowHoming.KIND, "TAG: homing, 4+")


func test_tag_helps_homing_lancemates() -> void:
	var v := _setup(["ammo:arrow_iv:homing"])
	var s: GameState = v[0]
	var tagger := Unit.new(3, _def("t", {"LT": ["tag"]}), 0, hex_at(5, 2), 2)
	s.add_unit(tagger)
	check(BotTag.choose(s, tagger) == v[2], "designates for the homing Arrow IV, though everyone can see it")
