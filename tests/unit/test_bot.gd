extends TestCase
## The bot opponent plays legal, sensible games and explains itself.


func _play(gc: GameController, bot_sides: Array, max_turns: int) -> void:
	gc.start_turn()
	var guard := 0
	while not gc.state.game_over and gc.state.turn <= max_turns and guard < 3000:
		guard += 1
		var side := gc.state.active_side()
		if bot_sides.has(side):
			if not Bot.act(gc, side):
				break
		else:
			var p := gc.pending_units()
			if p.is_empty():
				break
			match gc.state.phase:
				Phase.Kind.MOVEMENT:
					SimBot._move(gc, p[0])
				Phase.Kind.WEAPON_ATTACK:
					SimBot._fire(gc, p[0])
				_:
					SimBot._physical(gc, p[0])


func test_bot_vs_bot_finishes() -> void:
	var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json",
			terrain(), UnitDb.load_dir())
	var gc := GameController.new(s, 77)
	var t0 := Time.get_ticks_msec()
	_play(gc, [0, 1], 30)
	var intents := gc.history.filter(func(e): return e.type == GameEvent.INTENT)
	check(intents.size() > 4, "bot explains its moves")
	check(gc.state.turn > 1, "played more than one turn")
	check(Time.get_ticks_msec() - t0 < 60000, "fast enough")


func test_bot_beats_crude_bot_usually() -> void:
	var wins := 0
	for seed_value in [1, 2, 3]:
		var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json",
				terrain(), UnitDb.load_dir())
		var gc := GameController.new(s, seed_value)
		_play(gc, [1], 30)
		if s.game_over and s.winner == 1:
			wins += 1
	check(wins >= 2, "bot won %d of 3 against the crude bot" % wins)


func test_bot_holds_fire_to_stay_cool() -> void:
	var s := GameState.new(open_map(10, 4))
	var r := mech("rifleman_rfl3n", 0, hex_at(1, 2), 2, 1)
	var t := mech("atlas_as7d", 1, hex_at(5, 2), 5, 2)
	s.add_unit(r)
	s.add_unit(t)
	var plan := BotFire.plan(s, r)
	var heat := 0
	for sh in plan["shots"]:
		heat += r.weapons[sh["weapon"]].def.heat
	check(heat < 28, "doesn't fire all 28 heat with 10 sinks")
	check(Advisor.projected_heat(r, heat) <= BotFire.HEAT_STRETCH, "heat in check")
	check(plan["reason"].contains("holds"), plan["reason"])


func test_bot_double_fires_ultras_when_cool() -> void:
	var s := GameState.new(open_map(10, 4))
	var j := mech("jagermech_jm6dd", 0, hex_at(1, 2), 2, 1)
	var t := mech("atlas_as7d", 1, hex_at(5, 2), 5, 2)
	s.add_unit(j)
	s.add_unit(t)
	var plan := BotFire.plan(s, j)
	var ultras := 0
	for i: int in plan["modes"]:
		if plan["modes"][i] == WeaponModes.ULTRA:
			ultras += 1
	check(ultras >= 1, "double-fires: " + plan["reason"])
	check(plan["reason"].contains("double-fires"), plan["reason"])
	for w in j.weapons:
		check_eq(w.mode, "", "planning leaves the modes as they were")
	check_eq(FireOptions.volley_heat(j, [0]), 1, "one Ultra AC/5 shot: 1 heat")


func test_bot_lbx_mode() -> void:
	var s := GameState.new(open_map(10, 4))
	var c := mech("centurion_cn9d", 0, hex_at(1, 2), 2, 1)
	var t := mech("atlas_as7d", 1, hex_at(4, 2), 5, 2)
	s.add_unit(c)
	s.add_unit(t)
	var lbx := c.weapons[0]
	check(lbx.def.lbx)
	BotModes.apply(s, c, t, false)
	check_eq(lbx.mode, "", "slugs: 10 damage beats about 6 pellets for one point of to-hit")
	for a in c.ammo:
		if a.kind == "":
			a.shots = 0
	BotModes.apply(s, c, t, false)
	check_eq(lbx.mode, WeaponModes.CLUSTER, "out of slugs: cluster")


func test_bot_swings_hatchet() -> void:
	var s := GameState.new(open_map(6, 4))
	var h := mech("hatchetman_hct3f", 0, hex_at(1, 2), 2, 1)
	var t := mech("atlas_as7d", 1, hex_at(2, 2), 5, 2)
	s.add_unit(h)
	s.add_unit(t)
	s.phase = Phase.Kind.PHYSICAL_ATTACK
	Damage.destroy_location(h, Location.LA)  # one punch (5) against a hatchet (9)
	var p := BotPhysical.plan(s, h)
	check_eq(p["attacks"].size(), 1, p["reason"])
	if p["attacks"].size() == 1:
		check_eq(p["attacks"][0]["kind"], "hatchet", p["reason"])
