extends TestCase
## Indirect Fire Special (IF X) and Assets as spotters (book p. 145).


## Carrier at the south end, a level 3 hill across row 5, target north of it.
func _setup(spotter_id: String) -> Array:
	var rows := []
	for r in 10:
		rows.append("c0 c0 c3 c0 c0" if r == 5 else "c0 c0 c0 c0 c0")
	var s := GameState.new(make_map(rows))
	var a := asset("test_lrm_carrier", 0, hex_at(2, 9), 0, 1)
	var t := asset("test_tank", 1, hex_at(2, 1), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	if spotter_id != "":
		s.add_unit(asset(spotter_id, 0, hex_at(0, 2), 0, 3))
	return [s, a, t]


func _labels(th: ToHit) -> Array:
	return th.mods.map(func(m: Dictionary) -> String: return m["label"])


func test_if_weapons_mounted() -> void:
	var a := asset("test_lrm_carrier", 0, hex_at(0, 0))
	check_eq(a.weapons.size(), 3, "one regular grouping plus IF2")
	check(AssetIndirect.is_indirect(a.weapons[1].def), "indirect attack")
	check_eq(a.weapons[1].def.damage, 5, "5 damage")
	check_eq(a.weapons[1].def.long_range, 21, "7/14/21")


func test_needs_spotter_and_no_mp() -> void:
	var r := _setup("")
	var a: Unit = r[1]
	check(not ToHitCalc.weapon(r[0], a, a.weapons[1], r[2]).possible(), "hill blocks with no spotter")
	r = _setup("test_tank")
	a = r[1]
	var th := ToHitCalc.weapon(r[0], a, a.weapons[1], r[2])
	check(th.possible(), "spotted: " + th.impossible)
	var labels := _labels(th)
	check(labels.has("indirect special") and labels.has("indirect fire"), "-2 special and +1 indirect")
	check(labels.has("spotter Asset"), "a vehicle spots as running")
	check(not ToHitCalc.weapon(r[0], a, a.weapons[0], r[2]).possible(), "regular attack needs line of sight")
	a.move_mode = MoveMode.Kind.RUN
	check(not ToHitCalc.weapon(r[0], a, a.weapons[1], r[2]).possible(), "not after spending MP")


func test_infantry_spot_as_not_moved() -> void:
	var r := _setup("test_foot")
	var a: Unit = r[1]
	var th := ToHitCalc.weapon(r[0], a, a.weapons[1], r[2])
	check(th.possible(), th.impossible)
	check(not _labels(th).has("spotter Asset"), "infantry add nothing for movement")
	# Skill 5, medium range +2 (8 hexes), indirect +1, special -2, target TMM +1.
	check_eq(th.target(), 7, "to-hit")


func test_indirect_replaces_regular_and_costs_tmm() -> void:
	var r := _setup("test_tank")
	var s: GameState = r[0]
	var a: Unit = r[1]
	s.turn = 1
	var decl := FireOptions.declare(s, a, [{"weapon": 1, "target_id": 2}, {"weapon": 2, "target_id": 2}, {"weapon": 0, "target_id": 2}])
	check_eq(decl.size(), 2, "both IF attacks, no regular one")
	AssetIndirect.record(s, a, decl)
	var e := mech("griffin_grf1n", 1, hex_at(2, 7), 0, 4)
	s.add_unit(e)
	var th := ToHitCalc.weapon(s, e, gun(e, "ppc"), a)
	check(not _labels(th).has("target TMM"), "TMM lost the turn it fires indirectly")


func test_indirect_hit_deals_five() -> void:
	var r := _setup("test_tank")
	var s: GameState = r[0]
	var a: Unit = r[1]
	var t: Unit = r[2]
	var th := ToHitCalc.weapon(s, a, a.weapons[1], t)
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	WeaponFire.resolve(s, dice, func(_t: StringName, _d: Dictionary) -> void: pass, a, a.weapons[1], t, th)
	check_eq(t.asset.damage, 5, "5 points")
