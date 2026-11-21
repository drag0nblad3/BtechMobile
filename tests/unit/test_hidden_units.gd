extends TestCase
## Hidden units and point-blank attacks (book pp. 230-231).

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


## 3 x 8 clear map with heavy woods at column 1, row 3.
func _state() -> GameState:
	events.clear()
	var rows := []
	for r in 8:
		rows.append("c0 H0 c0" if r == 3 else "c0 c0 c0")
	return GameState.new(make_map(rows))


## Side 0 runs a Hunchback north toward a Hunchback hiding in the woods.
func _ambush() -> Array:
	var s := _state()
	var mover := mech("hunchback_hbk4g", 0, hex_at(1, 6), 0, 1)
	var h := mech("hunchback_hbk4g", 1, hex_at(1, 3), 3, 2)
	s.add_unit(mover)
	s.add_unit(h)
	HiddenUnits.hide(s, h)
	var gc := GameController.new(s, 3)
	gc.start_turn()
	return [s, gc, mover, h]


func _count(gc: GameController, type: StringName) -> int:
	return gc.history.filter(func(e: GameEvent) -> bool: return e.type == type).size()


func test_where_a_unit_can_hide() -> void:
	var s := GameState.new(make_map(["c0 H0 L0 r0 w0d1 w0d2 p0"]))
	var u := mech("hunchback_hbk4g", 0, hex_at(0, 0))
	check(HiddenUnits.problem(s, u, hex_at(0, 0)) != "", "not in the open")
	for col in [1, 2, 3, 5]:
		check_eq(HiddenUnits.problem(s, u, hex_at(col, 0)), "", "woods, rough, deep water %d" % col)
	check(HiddenUnits.problem(s, u, hex_at(4, 0)) != "", "depth 1 doesn't cover a standing 'Mech")
	check(HiddenUnits.problem(s, u, hex_at(6, 0)) != "", "not on pavement")


func test_hidden_units_are_out_of_sight_but_still_alive() -> void:
	var a := _ambush()
	var s: GameState = a[0]
	var h: Unit = a[3]
	check(not s.units.has(h) and s.hidden.has(h), "kept off the field")
	check_eq(s.unit_at(h.coord), null, "nothing sees it")
	check_eq(s.sides_alive(), [0, 1], "its side is still in the game")
	check_eq(s.active_side(), 0, "only the visible side has turns")


func test_walking_into_a_hidden_unit_stops_next_to_it() -> void:
	var a := _ambush()
	var s: GameState = a[0]
	var gc: GameController = a[1]
	var mover: Unit = a[2]
	var h: Unit = a[3]
	check(gc.submit_move(mover, MoveOptions.key(hex_at(1, 2), 0), MoveMode.Kind.RUN), "move accepted")
	check_eq(mover.coord, hex_at(1, 4), "stopped short of the woods")
	check(s.units.has(h) and not s.hidden.has(h), "revealed")
	check(h.tmm_zero and h.has_moved, "caught out: no move this phase, no movement modifier")
	check_eq(s.point_blank.size(), 1, "it may fire point-blank")
	check_eq(gc.deciding_side(), 1, "the game waits on its owner")
	check_eq(s.phase, Phase.Kind.MOVEMENT, "the move isn't finished yet")
	check(not gc.submit_move(mover, MoveOptions.key(hex_at(1, 4), 0), MoveMode.Kind.WALK), "nobody else acts meanwhile")


func test_point_blank_volley_uses_up_the_turn() -> void:
	var a := _ambush()
	var s: GameState = a[0]
	var gc: GameController = a[1]
	var mover: Unit = a[2]
	var h: Unit = a[3]
	gc.submit_move(mover, MoveOptions.key(hex_at(1, 2), 0), MoveMode.Kind.RUN)
	var p := PointBlank.plan(s, h, mover)
	check(p["shots"].size() > 0, "it has shots")
	var th := ToHitCalc.weapon(s, h, h.weapons[p["shots"][0]], mover, false, true)
	check(not th.mods.any(func(m: Dictionary) -> bool: return String(m["label"]).begins_with("target ran")),
			"no target movement modifier")
	check(gc.point_blank(h, p["shots"], p["twist"]), "fired")
	check(_count(gc, GameEvent.WEAPON_FIRED) >= p["shots"].size(), "shots resolved at once")
	check(h.has_fired and h.has_physical, "nothing else this turn")
	check_eq(s.phase, Phase.Kind.WEAPON_ATTACK, "the turn goes on")


func test_declining_keeps_the_unit_able_to_shoot() -> void:
	var a := _ambush()
	var s: GameState = a[0]
	var gc: GameController = a[1]
	var mover: Unit = a[2]
	var h: Unit = a[3]
	gc.submit_move(mover, MoveOptions.key(hex_at(1, 2), 0), MoveMode.Kind.RUN)
	gc.point_blank(h, [])
	check_eq(_count(gc, GameEvent.WEAPON_FIRED), 0)
	check_eq(s.phase, Phase.Kind.WEAPON_ATTACK)
	check(not h.has_fired, "it fires normally this phase")
	var th := ToHitCalc.weapon(s, mover, mover.weapons[0], h)
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "target caught off guard") or h.hexes_moved == 0,
			"found units get no movement modifier")


func test_ending_next_to_a_hidden_unit_reveals_it() -> void:
	var a := _ambush()
	var s: GameState = a[0]
	var gc: GameController = a[1]
	var mover: Unit = a[2]
	var h: Unit = a[3]
	gc.submit_move(mover, MoveOptions.key(hex_at(1, 4), 0), MoveMode.Kind.WALK)
	check_eq(mover.coord, hex_at(1, 4))
	check(s.units.has(h), "next door: found")


func test_owner_reveals_only_at_the_start_of_a_phase() -> void:
	var s := _state()
	var a := mech("hunchback_hbk4g", 0, hex_at(0, 7), 0, 1)
	var b := mech("hunchback_hbk4g", 0, hex_at(2, 7), 0, 2)
	var h := mech("hunchback_hbk4g", 1, hex_at(1, 3), 3, 3)
	var e := mech("hunchback_hbk4g", 1, hex_at(0, 0), 3, 4)
	for u in [a, b, h, e]:
		s.add_unit(u)
	HiddenUnits.hide(s, h)
	var gc := GameController.new(s, 5)
	gc.start_turn()
	check(gc.reveal(h), "before anyone moves")
	check(s.units.has(h) and not h.has_moved, "and it may move")
	var first: Unit = gc.pending_units()[0]
	gc.submit_move(first, MoveOptions.key(first.coord, first.facing), MoveMode.Kind.WALK)
	var h2 := mech("hunchback_hbk4g", 1, hex_at(2, 3), 3, 5)
	s.add_unit(h2)
	HiddenUnits.hide(s, h2)
	check(not gc.reveal(h2), "too late once the phase is under way")


func test_jumping_over_hides_nothing_landing_on_it_does() -> void:
	var s := _state()
	var j := mech("jenner_jr7d", 0, hex_at(1, 6), 0, 1)
	var h := mech("hunchback_hbk4g", 1, hex_at(1, 4), 3, 2)
	s.add_unit(j)
	s.add_unit(h)
	HiddenUnits.hide(s, h)
	var path: Array[Vector3i] = [MoveOptions.key(hex_at(1, 4), 0)]
	check(HiddenUnits.blocked_path(s, j, path, MoveMode.Kind.JUMP).is_empty(), "jumps aren't stopped")
	var gc := GameController.new(s, 9)
	gc.start_turn()
	check(gc.submit_move(j, MoveOptions.key(hex_at(1, 4), 0), MoveMode.Kind.JUMP), "jump accepted")
	check(s.units.has(h), "landing on it reveals it")
	check(j.coord != h.coord, "the jumper is shoved aside")


func test_burning_hex_drives_it_out() -> void:
	var s := _state()
	var h := mech("hunchback_hbk4g", 1, hex_at(1, 3), 3, 2)
	s.add_unit(h)
	HiddenUnits.hide(s, h)
	s.map.get_tile(h.coord).on_fire = true
	HiddenUnits.reveal_burning(s, _emit)
	check(s.units.has(h))
	check_eq(events[0][0], GameEvent.UNIT_REVEALED)


func test_bots_play_with_a_hidden_side() -> void:
	var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json", terrain(), UnitDb.load_dir())
	HiddenUnits.place_side(s, 1)
	var gc := GameController.new(s, 11)
	gc.start_turn()
	var guard := 0
	while not s.game_over and guard < 4000 and s.turn <= 20:
		guard += 1
		for side in 2:  # as BotDriver does: hidden units may come out at a phase start
			BotHidden.reveal(gc, side)
		if not Bot.act(gc, gc.deciding_side()):
			break
	check(s.turn > 1, "the game moved on (turn %d, guard %d)" % [s.turn, guard])
	check(s.game_over or s.turn > 20, "no stall (turn %d, guard %d)" % [s.turn, guard])
	check(gc.history.any(func(e: GameEvent) -> bool: return e.type == GameEvent.UNIT_REVEALED), "came out sometime")
