extends TestCase
## MASC (book p. 204) and its Escalating Failure roll (p. 180).

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


## A 50-ton test 'Mech with MASC (3 slots) in its left torso.
func _masc_mech() -> Unit:
	var d := UnitDef.from_dict({"id": "m", "name": "Masc Test", "tonnage": 50, "walk_mp": 5,
			"armor": {"HD": 9, "CT": 20, "LT": 15, "RT": 15, "LA": 10, "RA": 10, "LL": 15, "RL": 15},
			"equipment": {"LT": ["masc"], "RA": ["medium_laser"]}}, weapons())
	return Unit.new(1, d, 0, hex_at(1, 1), 0)


func test_size_and_slots() -> void:
	var u := _masc_mech()
	check_eq(Masc.size(u.def), 3, "50 t Inner Sphere: tonnage / 20, rounded")
	check_eq(Masc.size(UnitDef.from_dict({"id": "c", "name": "C", "tonnage": 45, "walk_mp": 6, "tech_base": "clan"})), 2, "Clan: / 25")
	var n := 0
	for s: CritSlot in u.slots[Location.LT]:
		n += 1 if s.kind == CritSlot.Kind.MASC else 0
	check_eq(n, 3)
	check_eq(DesignWeight.breakdown(u.def)["masc"], 3.0)


func test_escalating_numbers_and_rest() -> void:
	var u := _masc_mech()
	var dice := LoadedDice.new()
	var needs: Array[int] = []
	for t in 5:
		u.reset_for_turn()
		needs.append(Masc.need(u))
		dice.queue_2d6(12)
		Masc.engage(dice, _emit, u)
	check_eq(needs, [3, 5, 7, 10, 11] as Array[int], "3+, 5+, 7+, 10+, then 11+")
	u.reset_for_turn()
	check_eq(Masc.need(u), 11, "fifth turn and on stays at 11+")
	# Three turns in a row, one rest: 5+ (the book's example).
	u.masc_level = 3
	u.reset_for_turn()
	u.reset_for_turn()
	check_eq(Masc.need(u), 5)
	u.reset_for_turn()
	check_eq(Masc.need(u), 3, "two rests: back to 3+")
	u.reset_for_turn()
	check_eq(Masc.need(u), 3, "never below 3+")


func test_success_doubles_running_mp() -> void:
	var u := _masc_mech()
	check_eq(u.run_mp(), 8)
	var dice := LoadedDice.new()
	dice.queue_2d6(3)
	check(Masc.engage(dice, _emit, u), "3 beats 3+")
	check_eq(u.run_mp(), 10, "twice walking MP")
	check_eq(MoveMode.budget(u, MoveMode.Kind.RUN), 10)
	check(Masc.problem(u) != "", "once per turn")
	u.reset_for_turn()
	check_eq(u.run_mp(), 8, "only for that turn")


func test_failure_hits_one_leg_after_the_move() -> void:
	var s := GameState.new(open_map(8, 6))
	var u := _masc_mech()
	s.add_unit(u)
	s.add_unit(mech("hunchback_hbk4g", 1, hex_at(6, 0), 3, 2))
	var gc := GameController.new(s, 1)
	gc.start_turn()
	var dice := LoadedDice.new()
	gc.dice = dice
	if gc.pending_units()[0] != u:
		check(gc.submit_move(gc.pending_units()[0], MoveOptions.key(hex_at(6, 0), 3), MoveMode.Kind.WALK))
	dice.queue_2d6(2)  # fails the 3+
	check(not gc.engage_masc(u))
	check_eq(u.run_mp(), 8, "no extra speed")
	check(not gc.go_prone(u), "engaging MASC means moving")
	dice.d6_queue.append(1)  # kick table: right leg
	dice.queue_2d6(12)  # a 12 counts as three critical hits
	var before := gc.history.size()
	check(gc.submit_move(u, MoveOptions.key(hex_at(1, 4), 3), MoveMode.Kind.RUN))
	var after := gc.history.slice(before)
	var moved := after.map(func(e: GameEvent) -> StringName: return e.type).find(GameEvent.UNIT_MOVED)
	var crits := after.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.CRITICAL)
	check_eq(crits.size(), 3, "three hits, no limb blown off")
	check(crits.all(func(e: GameEvent) -> bool: return e.data["loc"] == Location.RL), "all in the right leg")
	check(after.find(crits[0]) > moved, "after the move")
	check(not u.is_location_destroyed(Location.RL))
	var check_ev: GameEvent = after.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.CRIT_CHECK)[0]
	check(Explainer.text(check_ev, s, ExplainLevel.FULL).contains("MASC failure"))


func test_destroyed_masc_cant_engage() -> void:
	var u := _masc_mech()
	for sl: CritSlot in u.slots[Location.LT]:
		if sl.kind == CritSlot.Kind.MASC:
			sl.hit = true
			break
	check_eq(Masc.problem(u), "its MASC is destroyed")
	check_eq(Masc.problem(Unit.new(2, make_def(5), 0, Vector2i.ZERO, 0)), "no MASC")


func test_explained() -> void:
	var s := GameState.new(open_map(4, 4))
	var u := _masc_mech()
	s.add_unit(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(9)
	Masc.engage(dice, _emit, u)
	var t := Explainer.text(events[-1], s, ExplainLevel.FULL)
	check(t.contains("twice its walking speed") and t.contains("5+"), t)


func test_bot_engages_masc_to_close_in() -> void:
	var s := GameState.new(open_map(24, 5))
	var u := _masc_mech()
	s.add_unit(u)
	s.add_unit(mech("hunchback_hbk4g", 1, hex_at(22, 2), 5, 2))
	var gc := GameController.new(s, 1)
	gc.start_turn()
	gc.dice = LoadedDice.new()  # sixes: the MASC roll works
	if gc.pending_units()[0] != u:
		Bot.act(gc, 1)
	check(Bot.act(gc, 0))
	var m := gc.history.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.MASC)
	check_eq(m.size(), 1, "engaged MASC")
	check(u.hexes_moved > 6, "ran further than 8 MP allows after turning (%d)" % u.hexes_moved)


func test_button_label() -> void:
	var u := _masc_mech()
	check_eq(MascInput.label(u), "MASC (3+)")
	check_eq(MascInput.label(Unit.new(2, make_def(5), 0, Vector2i.ZERO, 0)), "", "hidden without MASC")
	u.masc_used = true
	u.masc_active = true
	check_eq(MascInput.label(u), "MASC on")
