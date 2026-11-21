extends TestCase
## The computer's aimed shots (BotAim).


func _setup(attacker: String, col: int) -> Array:
	var s := GameState.new(open_map(12, 4))
	var a := mech(attacker, 0, hex_at(1, 2), 2, 1)
	var t := mech("atlas_as7d", 1, hex_at(col, 2), 5, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _ppc_shot(a: Unit, t: Unit) -> Array:
	for i in a.weapons.size():
		if a.weapons[i].def.id == "ppc":
			return [{"weapon": i, "target_id": t.id}]
	return []


func test_no_aim_at_moving_target_without_tc() -> void:
	var v := _setup("griffin_grf1n", 4)
	var t: Unit = v[2]
	t.armor[Location.CT] = 0
	var shots := _ppc_shot(v[1], t)
	check_eq(BotAim.choose(v[0], v[1], shots), "")
	check(not shots[0].has("aim"))


func test_sitting_target_aims_only_when_it_pays() -> void:
	var v := _setup("griffin_grf1n", 4)
	var t: Unit = v[2]
	t.shutdown = true
	var shots := _ppc_shot(v[1], t)
	BotAim.choose(v[0], v[1], shots)
	check(not shots[0].has("aim"), "full armor: an ordinary shot is as good")
	t.armor[Location.CT] = 0
	t.structure[Location.CT] = 6
	var note := BotAim.choose(v[0], v[1], shots)
	check_eq(shots[0].get("aim", -1), Location.CT, "a PPC kills the bare CT")
	check(note.contains("sitting target"), note)
	var opts := FireOptions.declare(v[0], v[1], shots)
	check_eq(opts[0]["to_hit"].aim_loc, Location.CT, "the controller accepts the aim")


func test_targeting_computer_aims_at_moving_target() -> void:
	var v := _setup("test_marauder_mad3r_tc", 5)
	var t: Unit = v[2]
	t.armor[Location.CT] = 0
	t.structure[Location.CT] = 6
	var shots := _ppc_shot(v[1], t)
	var note := BotAim.choose(v[0], v[1], shots)
	check_eq(shots[0].get("aim", -1), Location.CT)
	check(note.contains("targeting computer"), note)
	check_eq(BotAim.location_value(t, Location.HEAD, 10.0), 16.0, "head hit + pilot")
