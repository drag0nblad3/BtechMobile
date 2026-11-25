extends TestCase
## Special Pilot Abilities, batch 5 (Campaign Operations pp. 73-77):
## Melee Master, Environmental Specialist, Combat Intuition; the computer
## player's Marksman shot.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _pair(a_id: String, t_id: String) -> Array:
	events.clear()
	var s := GameState.new(open_map(6, 6))
	var a := mech(a_id, 0, hex_at(2, 3), 0, 1)
	var t := mech(t_id, 1, Hex.neighbor(hex_at(2, 3), 0), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func test_melee_master_adds_one_attack() -> void:
	var r := _pair("atlas_as7d", "hunchback_hbk4g")
	var s: GameState = r[0]
	var a: Unit = r[1]
	var asks := [{"kind": "punch", "limb": Location.LA, "target_id": 2},
			{"kind": "punch", "limb": Location.RA, "target_id": 2},
			{"kind": "kick", "limb": Location.RL, "target_id": 2}]
	check_eq(PhysicalOptions.declare(s, a, asks).size(), 2, "two punches, no kick")
	Spa.grant(a.pilot, Spa.MELEE_MASTER)
	check_eq(PhysicalOptions.declare(s, a, asks).size(), 3, "two punches and a kick")
	asks.append({"kind": "kick", "limb": Location.LL, "target_id": 2})
	check_eq(PhysicalOptions.declare(s, a, asks).size(), 3, "never a kick with both legs")
	var push := [{"kind": "push", "limb": -1, "target_id": 2}, {"kind": "punch", "limb": Location.LA, "target_id": 2}]
	check_eq(PhysicalOptions.declare(s, a, push).size(), 1, "a push uses both arms")


func test_environmental_specialist() -> void:
	var s := GameState.new(open_map(4, 4))
	s.conditions = Conditions.from_dict({"wind": true, "low_visibility": true})
	var u := mech("locust_lct1v", 0, hex_at(1, 1), 0, 1)
	s.add_unit(u)
	var th := ToHit.new()
	Wind.add(th, s, u)
	check_eq(th.target(), 1, "wind: +1")
	Spa.grant(u.pilot, Spa.ENV_SPECIALIST, 1, EnvSpecialist.WIND)
	th = ToHit.new()
	Wind.add(th, s, u)
	check_eq(th.target(), 0, "halved, rounding down")
	th = ToHit.new()
	LowVisibility.add(th, s, u)
	check_eq(th.target(), 1, "not a low visibility specialist")
	Spa.grant(u.pilot, Spa.ENV_SPECIALIST, 1, EnvSpecialist.LOW_VISIBILITY)
	th = ToHit.new()
	LowVisibility.add(th, s, u)
	check_eq(th.target(), 0, "+1 murk, -1 specialist")
	s.map.get_tile(u.coord).surface = Surfaces.ICE
	th = ToHit.new()
	Surfaces.add_psr(th, s, u)
	check_eq(th.target(), 1, "ice is a third choice")


func test_combat_intuition_acts_last() -> void:
	var s := GameState.new(open_map(10, 10))
	var mine := mech("locust_lct1v", 0, hex_at(1, 1), 3, 1)
	s.add_unit(mine)
	s.add_unit(mech("locust_lct1v", 0, hex_at(2, 1), 3, 2))
	s.add_unit(mech("atlas_as7d", 1, hex_at(1, 8), 0, 3))
	var gc := GameController.new(s, 1)
	check(not gc.request_intuition(mine, true), "needs the ability")
	Spa.grant(mine.pilot, Spa.COMBAT_INTUITION)
	check(gc.request_intuition(mine, true))
	s.turn = 3
	EndPhase.run(s, LoadedDice.new(), _emit)
	check_eq(mine.pilot.hits, 1, "one pilot hit")
	check(not mine.pilot.roll_owed, "no consciousness roll")
	check_eq(mine.intuition_turn, 4)
	gc.start_turn()
	check_eq(s.late_from, 2, "after the other two")
	check_eq(s.side_order.back(), 0)
	check(not gc.pending_units().has(mine), "waits its turn")


func test_bot_takes_a_marksman_shot() -> void:
	var r := _pair("hunchback_hbk4g", "jenner_jr7d")
	var s: GameState = r[0]
	var a: Unit = r[1]
	var t: Unit = r[2]
	t.coord = hex_at(2, 1)
	t.move_mode = MoveMode.Kind.RUN
	t.hexes_moved = 3
	t.armor[Location.CT] = 0
	t.structure[Location.CT] = 4
	var shots := [{"weapon": gun_index(a, "medium_laser"), "target_id": 2}]
	check_eq(BotAim.marksman(s, a, shots), "", "no ability, no aim")
	Spa.grant(a.pilot, Spa.MARKSMAN)
	check(BotAim.marksman(s, a, shots) != "", "aims for the open torso")
	check_eq(int(shots[0]["aim"]), Location.CT)
