extends TestCase
## Shutting down by choice (book p. 105, errata p. 104).

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _setup() -> Array:
	events.clear()
	var s := GameState.new(open_map(6, 3))
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1), 0, 1)
	s.add_unit(u)
	return [s, u]


func test_shuts_down_and_stays_down_until_restarted() -> void:
	var v := _setup()
	var s: GameState = v[0]
	var u: Unit = v[1]
	check_eq(VoluntaryShutdown.problem(u, VoluntaryShutdown.ON), "only a 'Mech shut down by choice can be restarted this way")
	u.power_request = VoluntaryShutdown.OFF
	HeatPhase.run(s, LoadedDice.new(), _emit)
	check(u.shutdown and u.voluntary_shutdown)
	check(Explainer.text(events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.SHUTDOWN)[0], s,
			ExplainLevel.FULL).contains("on purpose"))
	HeatPhase.run(s, LoadedDice.new(), _emit)
	check(u.shutdown, "no automatic restart below 14 heat")
	u.power_request = VoluntaryShutdown.ON
	HeatPhase.run(s, LoadedDice.new(), _emit)
	check(not u.shutdown and not u.voluntary_shutdown, "cool: restarts on request")


func test_hot_restart_needs_the_roll() -> void:
	var v := _setup()
	var s: GameState = v[0]
	var u: Unit = v[1]
	u.shutdown = true
	u.voluntary_shutdown = true
	u.heat = 40  # still 26+ after sinking: avoid on 10+
	u.power_request = VoluntaryShutdown.ON
	var dice := LoadedDice.new()
	dice.queue_2d6(9)
	HeatPhase.run(s, dice, _emit)
	check(u.shutdown, "9 fails a 10+ restart")
	check_eq(RecordSheetView.power_choice(u)[0], VoluntaryShutdown.ON, "can ask again")
	u.heat = 31
	u.power_request = VoluntaryShutdown.ON
	dice.queue_2d6(12)
	HeatPhase.run(s, dice, _emit)
	check(not u.shutdown, "12 restarts it")


func test_controller_request_and_heat_shutdowns() -> void:
	var v := _setup()
	var u: Unit = v[1]
	var gc := GameController.new(v[0])
	check(gc.request_power(u, VoluntaryShutdown.OFF))
	check_eq(u.power_request, VoluntaryShutdown.OFF)
	check(gc.request_power(u, ""), "cancel")
	u.shutdown = true
	check(not gc.request_power(u, VoluntaryShutdown.ON), "a heat shutdown restarts the normal way")
	check_eq(RecordSheetView.power_choice(u)[0], null)
