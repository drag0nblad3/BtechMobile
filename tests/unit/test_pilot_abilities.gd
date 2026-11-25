extends TestCase
## Special Pilot Abilities (Campaign Operations pp. 70-82), batch 1:
## Sniper, Multi-Tasker, Blood Stalker, Speed Demon and Lucky.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _pair(dist: int) -> Array:
	var s := GameState.new(open_map(20, 3))
	var a := mech("hunchback_hbk4g", 0, hex_at(0, 1), 2, 1)
	var b := mech("jenner_jr7d", 1, hex_at(dist, 1), 5, 2)
	var c := mech("wasp_wsp1a", 1, hex_at(dist, 2), 5, 3)
	for u in [a, b, c]:
		s.add_unit(u)
	return [s, a, b, c]


func test_sniper_halves_range_modifiers() -> void:
	var p := _pair(12)  # medium laser at 12 hexes is out of range; use the LRM-free Hunchback's laser at 5
	var s: GameState = p[0]
	var a: Unit = p[1]
	var b: Unit = p[2]
	b.coord = hex_at(5, 1)  # medium laser: 4-6 is medium
	var laser := gun(a, "medium_laser")
	var before := ToHitCalc.weapon(s, a, laser, b).target()
	Spa.grant(a.pilot, Spa.SNIPER)
	check_eq(ToHitCalc.weapon(s, a, laser, b).target(), before - 1, "+2 becomes +1 at medium range")
	b.coord = hex_at(8, 1)  # long range
	var th := ToHitCalc.weapon(s, a, laser, b)
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "Sniper" and m["value"] == -2), "+4 becomes +2")


func test_multi_tasker_removes_secondary_penalty() -> void:
	var p := _pair(3)
	var s: GameState = p[0]
	var a: Unit = p[1]
	var c: Unit = p[3]
	var laser := gun(a, "medium_laser")
	var base := ToHitCalc.weapon(s, a, laser, c).target()
	check_eq(ToHitCalc.weapon(s, a, laser, c, true).target(), base + 1)
	Spa.grant(a.pilot, Spa.MULTI_TASKER)
	check_eq(ToHitCalc.weapon(s, a, laser, c, true).target(), base, "no secondary-target penalty")


func test_blood_stalker_follows_its_quarry() -> void:
	var p := _pair(3)
	var s: GameState = p[0]
	var a: Unit = p[1]
	var b: Unit = p[2]
	var c: Unit = p[3]
	var laser := gun(a, "medium_laser")
	var to_b := ToHitCalc.weapon(s, a, laser, b).target()
	var to_c := ToHitCalc.weapon(s, a, laser, c).target()
	Spa.grant(a.pilot, Spa.BLOOD_STALKER)
	check_eq(ToHitCalc.weapon(s, a, laser, b).target(), to_b - 1, "any primary target could be the quarry")
	BloodStalker.mark(s, a, b)
	check_eq(a.pilot.quarry, b.id)
	check_eq(ToHitCalc.weapon(s, a, laser, c).target(), to_c + 2, "+2 against anything else")
	Damage.destroy_unit(b, "engine destroyed")
	check_eq(ToHitCalc.weapon(s, a, laser, c).target(), to_c, "the quarry is gone: the ability ends")
	check_eq(a.pilot.quarry, BloodStalker.USED)


func test_speed_demon_runs_further_but_cannot_attack() -> void:
	var s := GameState.new(open_map(3, 12))
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 0), 3, 1)  # walk 4, run 6
	var e := mech("jenner_jr7d", 1, hex_at(1, 11), 0, 2)
	s.add_unit(u)
	s.add_unit(e)
	check_eq(MoveMode.budget(u, MoveMode.Kind.RUN), 6)
	Spa.grant(u.pilot, Spa.SPEED_DEMON)
	check_eq(MoveMode.budget(u, MoveMode.Kind.RUN), 7, "+1 running MP")
	check_eq(MoveMode.budget(u, MoveMode.Kind.WALK), 4, "walking is unchanged")
	check(MoveExecutor.run(s, LoadedDice.new(), _emit, u, MoveOptions.key(hex_at(1, 7), 3), MoveMode.Kind.RUN, -1), "ran 7")
	check(u.flat_out, "used the extra MP")
	e.coord = hex_at(1, 9)
	check_eq(ToHitCalc.weapon(s, u, gun(u, "medium_laser"), e).impossible, SpeedDemon.NO_ATTACK)
	u.reset_for_turn()
	check(not u.flat_out, "a new turn")
	SpeedDemon.after_move(u, MoveMode.Kind.RUN, 6, 7)
	check(not u.flat_out, "a normal run keeps its attacks")


func test_lucky_rerolls_failed_rolls() -> void:
	events.clear()
	var s := GameState.new(open_map(3, 3))
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	s.add_unit(u)
	Spa.grant(u.pilot, Spa.LUCKY, 2)
	check_eq(u.pilot.lucky, 2)
	var dice := LoadedDice.new()
	dice.queue_2d6(3)
	dice.queue_2d6(9)
	check(Psr.roll(dice, _emit, u, "test", 0, s), "the reroll stands")
	check_eq(int(events[-1].data["lucky_first"]), 3)
	check_eq(u.pilot.lucky, 1)
	dice.queue_2d6(2)
	dice.queue_2d6(2)
	check(not Psr.roll(dice, _emit, u, "test", 0, s), "the second roll stands even when it fails")
	check_eq(u.pilot.lucky, 0)
	dice.queue_2d6(2)
	check(not Psr.roll(dice, _emit, u, "test", 0, s), "no luck left")
	check(not events[-1].data.has("lucky_first"))
	var w := gun(u, "medium_laser")
	u.pilot.lucky = 1
	check_eq(Lucky.attack(dice, u, gun(u, "machine_gun"), 8), -1, "not worth it for a machine gun")
	check_eq(Lucky.attack(dice, u, w, 11), -1, "not worth it at 11+")
	check(Lucky.attack(dice, u, w, 8) >= 2, "a medium laser at 8+ is worth a reroll")


func test_abilities_survive_battle_save() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	Spa.grant(u.pilot, Spa.LUCKY, 3)
	Spa.grant(u.pilot, Spa.SNIPER)
	u.pilot.quarry = 7
	var fields := BattleFields.names(u.pilot)
	for f in ["abilities", "lucky", "quarry"]:
		check(fields.has(f), f)
	check_eq(Spa.name_of(Spa.MULTI_TASKER), "Multi-Tasker")
	check_eq(int(Spa.info(Spa.SNIPER)["cost"]), 3)
