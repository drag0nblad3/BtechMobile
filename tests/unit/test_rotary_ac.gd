extends TestCase
## Rotary autocannons (book p. 183).

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _setup() -> Array:
	events.clear()
	var s := GameState.new(open_map(10, 4))
	var d := UnitDef.from_dict({"id": "rac", "name": "RAC", "tonnage": 60, "walk_mp": 4,
			"armor": {"CT": 20}, "equipment": {"RT": ["rotary_ac5", "ammo:rotary_ac5*2"]}}, weapons())
	var a := Unit.new(1, d, 0, hex_at(1, 2), 2)
	var t := mech("atlas_as7d", 1, hex_at(4, 2), 5, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _fire(v: Array, dice: LoadedDice) -> Dictionary:
	var a: Unit = v[1]
	var th := ToHitCalc.weapon(v[0], a, a.weapons[0], v[2])
	WeaponFire.resolve(v[0], dice, _emit, a, a.weapons[0], v[2], th)
	return events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.WEAPON_FIRED)[-1].data


func test_six_shots_use_the_six_column() -> void:
	var v := _setup()
	var a: Unit = v[1]
	var w := a.weapons[0]
	check_eq(WeaponModes.modes(w), RotaryAc.MODES)
	w.mode = "x6"
	check_eq(WeaponModes.shots(w), 6)
	var dice := LoadedDice.new()
	dice.queue_2d6(10)  # hit, no jam
	dice.queue_2d6(7)   # 7 on the 6 column: 4 shots hit
	var d := _fire(v, dice)
	check(not d.has("jammed"))
	check_eq(d["missiles"], 4)
	check_eq(a.heat_generated, 6, "1 heat a shot")
	check_eq(a.ammo_for(w.def), 34, "6 rounds used")


func test_jam_numbers_and_shots_still_fire() -> void:
	check_eq(RotaryAc.jams_on(1), 0)
	check_eq(RotaryAc.jams_on(3), 2)
	check_eq(RotaryAc.jams_on(5), 3)
	check_eq(RotaryAc.jams_on(6), 4)
	var v := _setup()
	var a: Unit = v[1]
	var w := a.weapons[0]
	w.mode = "x6"
	var d := _fire(v, LoadedDice.new([2, 2, 1, 1, 3, 4, 3, 4]))  # 4: hits (need 4) and jams; 2 shots hit the CT
	check(d["hit"], "the jamming attack still hits")
	check(d["jammed"])
	check(w.jammed and not a.can_fire(w))
	check(ToHitCalc.weapon(v[0], a, w, v[2]).impossible.contains("jammed"))
	check(Explainer.text(events[0], v[0], ExplainLevel.FULL).contains("JAMS"))
	var u := _setup()
	u[1].weapons[0].mode = "x2"
	check(not _fire(u, LoadedDice.new([1, 2])).has("jammed"), "two shots only jam on a 2")


func test_clearing_a_jam() -> void:
	var v := _setup()
	var s: GameState = v[0]
	var a: Unit = v[1]
	var w := a.weapons[0]
	w.jammed = true
	check_eq(WeaponModes.modes(w), ["", RotaryAc.UNJAM] as Array[String])
	a.move_mode = MoveMode.Kind.RUN
	w.mode = RotaryAc.UNJAM
	RotaryAc.resolve_unjams(s, LoadedDice.new(), _emit)
	check(w.jammed, "running: no clearing roll")
	check(events[-1].data.has("why"))
	a.move_mode = MoveMode.Kind.WALK
	w.mode = RotaryAc.UNJAM
	var dice := LoadedDice.new()
	dice.queue_2d6(6)  # needs 4 + 3 = 7
	RotaryAc.resolve_unjams(s, dice, _emit)
	check(w.jammed, "6 fails")
	w.mode = RotaryAc.UNJAM
	dice.queue_2d6(7)
	RotaryAc.resolve_unjams(s, dice, _emit)
	check(not w.jammed, "7 clears it")
	check(Explainer.text(events[-1], s, ExplainLevel.FULL).contains("cleared"))


func test_bot_fires_four_and_clears_jams() -> void:
	var v := _setup()
	var a: Unit = v[1]
	BotModes.apply(v[0], a, v[2], true)
	check_eq(a.weapons[0].mode, "x4")
	a.weapons[0].jammed = true
	BotModes.apply(v[0], a, v[2], true)
	check_eq(a.weapons[0].mode, RotaryAc.UNJAM)
