extends TestCase
## Special Pilot Abilities, batch 2 (Campaign Operations pp. 74-82):
## Jumping Jack, Weapon Specialist, Oblique Attacker, Forward Observer,
## Hot Dog, Melee Specialist, Eagle's Eyes, Maneuvering Ace.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _labels(th: ToHit) -> Array:
	return th.mods.map(func(m: Dictionary) -> String: return m["label"])


func _hill() -> Array:
	var rows := []
	for r in 10:
		rows.append("c0 c0 c3 c0 c0" if r == 5 else "c0 c0 c0 c0 c0")
	var s := GameState.new(make_map(rows))
	var a := mech("catapult_cplt_c1", 0, hex_at(2, 9), 0, 1)
	var t := mech("hunchback_hbk4g", 1, hex_at(2, 1), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _lrm(u: Unit) -> MountedWeapon:
	for w in u.weapons:
		if w.def.indirect:
			return w
	return null


func test_jumping_jack_and_weapon_specialist() -> void:
	var s := GameState.new(open_map(10, 3))
	var a := mech("hunchback_hbk4g", 0, hex_at(0, 1), 2, 1)
	var t := mech("jenner_jr7d", 1, hex_at(3, 1), 5, 2)
	s.add_unit(a)
	s.add_unit(t)
	var laser := gun(a, "medium_laser")
	a.move_mode = MoveMode.Kind.JUMP
	var jumped := ToHitCalc.weapon(s, a, laser, t).target()
	Spa.grant(a.pilot, Spa.JUMPING_JACK)
	check_eq(ToHitCalc.weapon(s, a, laser, t).target(), jumped - 2, "+3 for jumping becomes +1")
	Spa.grant(a.pilot, Spa.WEAPON_SPECIALIST, 1, "medium_laser")
	check(Spa.has(a, Spa.WEAPON_SPECIALIST))
	check_eq(Spa.choice(a, Spa.WEAPON_SPECIALIST), "medium_laser")
	check_eq(ToHitCalc.weapon(s, a, laser, t).target(), jumped - 4, "-2 with the chosen weapon")
	check(not _labels(ToHitCalc.weapon(s, a, gun(a, "ac20"), t)).has("Weapon Specialist"), "not with others")


func test_oblique_attacker_needs_no_spotter() -> void:
	var r := _hill()
	var a: Unit = r[1]
	check(not ToHitCalc.weapon(r[0], a, _lrm(a), r[2]).possible(), "no spotter: no shot")
	Spa.grant(a.pilot, Spa.OBLIQUE_ATTACKER)
	var th := ToHitCalc.weapon(r[0], a, _lrm(a), r[2])
	check(th.possible() and th.indirect, "fires indirectly on its own: " + th.impossible)
	check(_labels(th).has("indirect fire") and _labels(th).has("Oblique Attacker"), "+1 indirect, -1 Oblique Attacker")


func test_forward_observer_spots_while_shooting() -> void:
	var r := _hill()
	var s: GameState = r[0]
	var a: Unit = r[1]
	var sp := mech("jenner_jr7d", 0, hex_at(0, 2), 0, 3)
	s.add_unit(sp)
	s.declared_fire.append({"attacker_id": sp.id, "target_id": r[2].id})
	var busy := ToHitCalc.weapon(s, a, _lrm(a), r[2]).target()
	Spa.grant(sp.pilot, Spa.FORWARD_OBSERVER)
	check_eq(ToHitCalc.weapon(s, a, _lrm(a), r[2]).target(), busy - 1, "no +1 for the spotter also shooting")


func test_hot_dog_lowers_heat_rolls() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	check_eq(HotDog.need(u, 8), 8)
	Spa.grant(u.pilot, Spa.HOT_DOG)
	check_eq(HotDog.need(u, 8), 7)
	check_eq(HotDog.need(u, 0), 0, "no roll stays no roll")
	check_eq(HotDog.need(u, 99), 99, "automatic stays automatic")
	u.heat = 14
	var dice := LoadedDice.new()
	dice.queue_2d6(4)  # shutdown at 14 heat is avoided on 4+ (3+ for a Hot Dog)
	HeatShutdown.check(dice, _emit, u)
	check(not u.shutdown, "a Hot Dog avoids it")


func test_melee_specialist_hits_harder() -> void:
	var s := GameState.new(open_map(3, 3))
	var a := mech("hunchback_hbk4g", 0, hex_at(1, 1), 0, 1)
	var t := mech("jenner_jr7d", 1, Hex.neighbor(hex_at(1, 1), 0), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	var before := PhysicalOptions.for_target(s, a, t)
	Spa.grant(a.pilot, Spa.MELEE_SPECIALIST)
	var after := PhysicalOptions.for_target(s, a, t)
	for i in before.size():
		if int(before[i]["damage"]) > 0:
			check_eq(int(after[i]["damage"]), int(before[i]["damage"]) + 1, String(before[i]["kind"]))
			var b: ToHit = before[i]["to_hit"]
			var c: ToHit = after[i]["to_hit"]
			check_eq(c.target(), b.target() - 1, "-1 to hit")


func test_eagles_eyes_and_maneuvering_ace() -> void:
	var s := GameState.new(open_map(5, 5))
	var a := mech("hunchback_hbk4g", 0, hex_at(2, 2), 0, 1)
	var t := mech("jenner_jr7d", 1, Hex.neighbor(hex_at(2, 2), 0), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	check(not ActiveProbe.clears(s, a, t), "no probe")
	Spa.grant(a.pilot, Spa.EAGLES_EYES)
	check(ActiveProbe.clears(s, a, t), "a 1-hex probe")
	t.coord = hex_at(2, 0)
	check(not ActiveProbe.clears(s, a, t), "only 1 hex")
	check(not LateralShift.allowed(a), "a biped can't shift")
	Spa.grant(a.pilot, Spa.MANEUVERING_ACE)
	check(LateralShift.allowed(a), "a Maneuvering Ace can")
	check_eq(LateralShift.extra_mp(a), 1)
	check(LateralShift.steps(s, a, a.coord, 0, MoveMode.Kind.WALK).size() > 0, "sideways steps offered")
