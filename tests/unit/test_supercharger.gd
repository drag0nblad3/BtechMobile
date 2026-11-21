extends TestCase
## Supercharger (book p. 204).

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


## A 50-ton test 'Mech with a supercharger in the center torso, MASC optional.
func _mech(masc := false) -> Unit:
	var eq := {"CT": ["supercharger"], "RA": ["medium_laser"]}
	if masc:
		eq["LT"] = ["masc"]
	var d := UnitDef.from_dict({"id": "sc", "name": "SC Test", "tonnage": 50, "walk_mp": 5,
			"armor": {"HD": 9, "CT": 20, "LT": 15, "RT": 15, "LA": 10, "RA": 10, "LL": 15, "RL": 15},
			"equipment": eq}, weapons())
	return Unit.new(1, d, 0, hex_at(1, 1), 0)


func test_weight_and_slot() -> void:
	var u := _mech()
	check_eq(DesignWeight.breakdown(u.def)["supercharger"], 1.5, "250 engine 12.5 t / 10, up to the half ton")
	check_eq(u.slots[Location.CT].filter(func(sl: CritSlot) -> bool: return sl.kind == CritSlot.Kind.SUPERCHARGER).size(), 1)
	check_eq(DesignWeight.breakdown(mech("test_griffin_grf1n_sc", 0, hex_at(1, 1)).def)["supercharger"], 2.0)


func test_success_and_with_masc() -> void:
	var u := _mech()
	var dice := LoadedDice.new()
	dice.queue_2d6(3)
	check(Supercharger.engage(dice, _emit, u))
	check_eq(u.run_mp(), 10, "twice walking MP")
	check_eq(Supercharger.need(u), 5, "escalates like MASC")
	var both := _mech(true)
	dice.queue_2d6(3)
	dice.queue_2d6(3)
	check(Masc.engage(dice, _emit, both) and Supercharger.engage(dice, _emit, both))
	check_eq(both.run_mp(), 13, "5 x 2.5, rounded up")


func test_failure_wrecks_it_and_hits_the_engine() -> void:
	var s := GameState.new(open_map(4, 4))
	var u := _mech()
	s.add_unit(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(2)
	check(not Supercharger.engage(dice, _emit, u))
	check(Supercharger.broken(u), "wrecked on a failure")
	dice.queue_2d6(10)  # two critical hits
	Supercharger.apply_failure(s, dice, _emit, u)
	check_eq(u.engine_hits, 2)
	check(u.slots[Location.CT][0].hit and u.slots[Location.CT][1].hit, "top-most engine slots")
	check(not u.slots[Location.CT][2].hit)
	u.reset_for_turn()
	check_eq(Supercharger.problem(u), "its supercharger is wrecked")


func test_explained() -> void:
	var s := GameState.new(open_map(4, 4))
	var u := _mech()
	s.add_unit(u)
	var e := GameEvent.new(GameEvent.MASC, {"unit_id": 1, "roll": 2, "need": 3, "ok": false, "next": 5, "system": "supercharger"})
	check(Explainer.text(e, s, ExplainLevel.FULL).contains("supercharger"))
