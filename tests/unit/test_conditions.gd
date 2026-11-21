extends TestCase
## Battlefield conditions (book pp. 120-121): temperature, gravity, night.

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func _state(u: Unit, c: Dictionary) -> GameState:
	events.clear()
	var s := GameState.new(open_map(3, 3))
	s.add_unit(u)
	s.conditions = Conditions.from_dict(c)
	return s


func test_loading_rounding_and_problems() -> void:
	var c := Conditions.from_dict({"cold": 5, "gravity": 1.04, "night": true})
	check_eq(c.cold, 3, "at most level 3")
	check(not c.odd_gravity(), "1.04 G rounds to Terran")
	check_eq(Conditions.from_dict({"gravity": 1.05}).gravity_tenths(), 11, "1.05 rounds to 1.1")
	check_eq(Conditions.from_dict({"gravity": 0.0}).gravity_tenths(), 1, "at least 0.1 G")
	check_eq(c.names(), ["Extreme Cold 3", "Night"] as Array[String])
	check(Conditions.from_dict({"rain": true, "heat": 1}).problems().size() == 1, "rain vs heat")
	check(Conditions.new().is_clear())


func test_avoid_numbers_shift() -> void:
	var cold3 := Conditions.from_dict({"cold": 3})
	check_eq(ExtremeTemp.avoid(HeatScale.shutdown_avoid(14), cold3), 0, "book: 14 heat passes by itself")
	check_eq(ExtremeTemp.avoid(HeatScale.shutdown_avoid(18), cold3), 3, "book: 18 heat needs 3+")
	var heat3 := Conditions.from_dict({"heat": 3})
	check_eq(ExtremeTemp.avoid(HeatScale.shutdown_avoid(14), heat3), 7, "book: 14 heat needs 7+")
	check_eq(ExtremeTemp.avoid(HeatScale.shutdown_avoid(26), heat3), 99, "book: 26 heat fails")
	check_eq(ExtremeTemp.avoid(HeatScale.shutdown_avoid(10), heat3), 0, "no roll below 14")


func test_heat_phase_adds_and_sheds_heat() -> void:
	var u := mech("griffin_grf1n", 0, hex_at(1, 1), 0, 1)  # 12 sinks
	var s := _state(u, {"heat": 2})
	u.heat_generated = 12
	HeatPhase.run(s, LoadedDice.new(), _emit)
	check_eq(u.heat, 4, "12 built + 4 from the heat - 12 sinks")
	s.conditions = Conditions.from_dict({"cold": 1})
	u.heat = 0
	u.heat_generated = 14
	HeatPhase.run(s, LoadedDice.new(), _emit)
	check_eq(u.heat, 0, "14 built - 12 sinks - 2 from the cold")


func test_ammo_rolls_shift_with_temperature() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1), 0, 1)
	var s := _state(u, {"heat": 3})
	u.heat = 40
	HeatPhase.run(s, LoadedDice.new(), _emit)
	var rolls := events.filter(func(e): return e[0] == GameEvent.HEAT_ROLL and e[1]["kind"] == "ammo")
	check(u.heat >= 28, "still at 28+ heat: %d" % u.heat)
	check_eq(rolls.size(), 1)
	check_eq(rolls[0][1]["need"], 11, "8+ becomes 11+ at Extreme Heat 3")
	check_eq(ExtremeTemp.avoid(HeatScale.ammo_explosion_avoid(20), Conditions.from_dict({"cold": 3})), 0,
			"4+ drops to 1: no roll in Extreme Cold 3")


func test_life_support_in_the_cold() -> void:
	var c := Conditions.from_dict({"cold": 2})
	check_eq(ExtremeTemp.life_support_hits(c, 0), 2, "cold: one hit per level")
	check_eq(ExtremeTemp.life_support_hits(c, 7), 1, "5-10 heat negates one")
	check_eq(ExtremeTemp.life_support_hits(c, 15), 0, "11-20 negates two")
	var h := Conditions.from_dict({"heat": 2})
	check_eq(ExtremeTemp.life_support_hits(h, 12), 3, "book: 1 + 2 for heat level 2")
	check_eq(ExtremeTemp.life_support_hits(h, 5), 0, "no hits below 10")


func test_gravity_scales_falls_and_adds_jump_roll() -> void:
	var u := mech("atlas_as7d", 0, hex_at(1, 1), 0, 1)
	var s := _state(u, {"gravity": 1.5})
	Fall.fall(s, LoadedDice.new([6]), _emit, u, 0, "test")
	var falls := events.filter(func(e): return e[0] == GameEvent.FALL)
	check_eq(falls[0][1]["damage"], 15, "10 x 1.5")
	check_eq(Gravity.scale(7, Conditions.from_dict({"gravity": 1.2})), 9, "8.4 rounds up")
	check_eq(Gravity.scale(7, Conditions.new()), 7)
	u.psr_pending.clear()
	MovePsr.after_move(u, MoveMode.Kind.JUMP, 3, s.conditions)
	check_eq(u.psr_pending.size(), 1, "jump roll in odd gravity")
	check_eq(int(u.psr_pending[0]["mod"]), -1)
	u.psr_pending.clear()
	MovePsr.after_move(u, MoveMode.Kind.JUMP, 3, Conditions.new())
	check(u.psr_pending.is_empty(), "no roll at 1 G")


func test_explanations_and_start_event() -> void:
	var c := Conditions.from_dict({"cold": 1, "night": true})
	var t := ConditionsText.describe(c, ExplainLevel.FULL)
	check(t.contains("Extreme Cold 1") and t.contains("Night:"), t)
	check_eq(ConditionsText.describe(Conditions.new(), ExplainLevel.FULL), "")
	var a := mech("atlas_as7d", 0, hex_at(0, 2), 0, 1)
	var s := _state(a, {"night": true})
	s.add_unit(mech("atlas_as7d", 1, hex_at(2, 0), 3, 2))
	var ctl := GameController.new(s, 1)
	ctl.start_turn()
	check(ctl.history.any(func(e: GameEvent) -> bool: return e.type == GameEvent.CONDITIONS), "announced on turn 1")


func test_force_builder_cycles_presets() -> void:
	var fb := ForceBuilder.new(UnitDb.load_dir())
	check(fb.conditions.is_clear())
	fb.next_conditions()
	check(fb.conditions.night, "second preset is night")
