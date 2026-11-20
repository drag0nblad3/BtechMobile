extends TestCase
## Line of sight and partial cover checked against the book (pp. 56-58, 66).

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


## One column of hexes, top to bottom, from the given tokens (3 columns wide).
func _column(tokens: Array) -> GameState:
	var rows := []
	for t in tokens:
		rows.append("c0 %s c0" % t)
	events.clear()
	return GameState.new(make_map(rows))


func _pair(s: GameState, a_row: int, t_row: int) -> Array:
	var a := mech("griffin_grf1n", 0, hex_at(1, a_row), 0, 1)
	var t := mech("griffin_grf1n", 1, hex_at(1, t_row), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [a, t]


func test_hill_next_to_target_hides_it_from_above() -> void:
	# Attacker high on a level 5 hill; a level 2 hill right in front of the target.
	var s := _column(["c0", "c2", "c0", "c0", "c5"])
	var r := _pair(s, 4, 0)
	var los := LineOfSight.check(s.map, r[0], r[1])
	check(los["blocked"], "terrain as tall as the target and next to it blocks")
	var s2 := _column(["c0", "c0", "c0", "c2", "c5"])
	var r2 := _pair(s2, 4, 0)
	check(not LineOfSight.check(s2.map, r2[0], r2[1])["blocked"], "the same hill next to the high attacker is below it")


func test_woods_below_both_dont_count() -> void:
	var s := _column(["c0", "c0", "H0", "c0", "c3"])
	var r := _pair(s, 4, 0)
	check_eq(LineOfSight.check(s.map, r[0], r[1])["woods"], 0, "woods top out at 2, under both LOS levels")
	var s2 := _column(["c0", "H0", "c0", "c0", "c3"])
	var r2 := _pair(s2, 4, 0)
	check_eq(LineOfSight.check(s2.map, r2[0], r2[1])["woods"], 2, "but woods next to the target count")


func test_partial_cover_from_a_hill() -> void:
	var s := _column(["c0", "c1", "c0", "c0", "c0"])
	var r := _pair(s, 4, 0)
	var los := LineOfSight.check(s.map, r[0], r[1])
	check(not los["blocked"])
	check_eq(los["cover"], hex_at(1, 1), "one level higher, next to the target, on the line")
	var a: Unit = r[0]
	var t: Unit = r[1]
	var th := ToHitCalc.weapon(s, a, a.weapons[0], t)
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "partial cover"), th.summary())
	var hl := {"loc": Location.LL, "rear": false, "tac": false}
	var before := t.armor[Location.LL]
	WeaponFire.hit_with(s, LoadedDice.new(), _emit, t, FiringArc.FRONT, 5, a.id, "x", hl, th.cover_hex)
	check_eq(t.armor[Location.LL], before, "leg hit strikes the hill")
	t.prone = true
	check(LineOfSight.check(s.map, a, t)["blocked"], "a prone 'Mech behind a level 1 hex can't be seen")
	t.prone = false
	var high := _column(["c0", "c1", "c0", "c0", "c2"])
	var r3 := _pair(high, 4, 0)
	check_eq(LineOfSight.check(high.map, r3[0], r3[1])["cover"], Hex.INVALID, "a higher attacker sees over the cover")


func test_divided_line_takes_the_worse_side() -> void:
	events.clear()
	var s := GameState.new(open_map(5, 6))
	var a_c := hex_at(1, 4)
	var b_c := a_c + Vector2i(1, 1)
	check(Hex.line(a_c, b_c) != Hex.line(a_c, b_c, -1.0), "this line runs along a hexside")
	var mid1 := a_c + Vector2i(1, 0)
	var mid2 := a_c + Vector2i(0, 1)
	s.map.get_tile(mid1).level = 3  # a hill on one side only
	var a := mech("griffin_grf1n", 0, a_c, 0, 1)
	var t := mech("griffin_grf1n", 1, b_c, 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	check(LineOfSight.check(s.map, a, t)["blocked"], "the target's side picks the hill")
	s.map.get_tile(mid1).level = 0
	s.map.get_tile(mid2).level = 3
	check(LineOfSight.check(s.map, a, t)["blocked"], "either side")
