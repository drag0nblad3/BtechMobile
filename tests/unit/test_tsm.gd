extends TestCase
## Triple-strength myomer (book p. 205).


func _setup() -> Array:
	var s := GameState.new(open_map(5, 5))
	var a := mech("hatchetman_hct3f_tsm", 0, hex_at(2, 3), 0, 1)
	var t := mech("hunchback_hbk4g", 1, Hex.neighbor(hex_at(2, 3), 0), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _dmg(opts: Array[Dictionary], kind: String) -> int:
	for o in opts:
		if o["kind"] == kind:
			return o["damage"]
	return -1


func test_slots_and_weight() -> void:
	var a: Unit = _setup()[1]
	check(Tsm.has(a.def))
	var n := 0
	for loc in Location.COUNT:
		for sl: CritSlot in a.slots[loc]:
			if sl.name == "Triple-Strength Myomer":
				n += 1
				check(not sl.can_be_hit(), "TSM slots can't take critical hits")
	check_eq(n, Tsm.SLOTS)
	check(not Tsm.has(mech("hatchetman_hct3f", 0, hex_at(1, 1)).def))


func test_wakes_up_at_heat_9() -> void:
	var r := _setup()
	var a: Unit = r[1]
	a.heat = 8
	check_eq(a.walk_mp(), 3, "heat 8: -1, no TSM")
	check_eq(_dmg(PhysicalOptions.for_target(r[0], a, r[2]), "hatchet"), 9)
	a.heat = 9
	check(Tsm.active(a))
	check_eq(a.walk_mp(), 5, "4 + 2, then -1 for heat")
	check_eq(a.run_mp(), 8)
	var opts := PhysicalOptions.for_target(r[0], a, r[2])
	check_eq(_dmg(opts, "punch"), 10, "punch 5 doubled")
	check_eq(_dmg(opts, "kick"), 18, "kick 9 doubled")
	check_eq(_dmg(opts, "hatchet"), 18, "hatchet 9 doubled")
	check_eq(_dmg(opts, "push"), 0)


func test_log_says_doubled() -> void:
	var r := _setup()
	var d := {"attacker_id": 1, "target_id": 2, "kind": "kick", "limb": Location.RL, "roll": 9, "need": 5,
			"hit": true, "damage": 18, "mods": [], "tsm": true}
	var t := Explainer.text(GameEvent.new(GameEvent.PHYSICAL, d), r[0], ExplainLevel.FULL)
	check(t.contains("myomer"), t)
