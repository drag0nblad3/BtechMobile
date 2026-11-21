extends TestCase
## Switching heat sinks off and on (book p. 103).

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func test_switch_off_at_end_phase() -> void:
	var s := GameState.new(open_map(4, 4))
	var u := mech("hatchetman_hct3f_tsm", 0, hex_at(1, 1), 0, 1)
	s.add_unit(u)
	var gc := GameController.new(s)
	check(gc.request_sinks_off(u, 6))
	check(not gc.request_sinks_off(u, 11), "only 10 to switch off")
	check_eq(u.working_heat_sinks(), 10, "nothing changes before the End Phase")
	EndPhase.run(s, LoadedDice.new(), _emit)
	check_eq(u.working_heat_sinks(), 4)
	check_eq(u.dissipation(), 4)
	check_eq(events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.HEAT_SINKS_SWITCHED).size(), 1)
	var t := Explainer.text(events[-1], s, ExplainLevel.FULL)
	check(t.contains("myomer"), t)
	check(gc.request_sinks_off(u, 0))
	EndPhase.run(s, LoadedDice.new(), _emit)
	check_eq(u.working_heat_sinks(), 10, "back on")


func test_works_while_shut_down() -> void:
	var u := mech("hatchetman_hct3f", 0, hex_at(1, 1))
	u.shutdown = true
	check_eq(HeatSinkSwitch.problem(u, 3), "")
