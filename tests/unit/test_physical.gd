extends TestCase
## Punches and kicks.


func _setup() -> Array:
	var s := GameState.new(open_map(5, 5))
	var a := mech("atlas_as7d", 0, hex_at(2, 3), 0, 1)
	var t := mech("hunchback_hbk4g", 1, Hex.neighbor(hex_at(2, 3), 0), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func test_punch_and_kick_numbers() -> void:
	var r := _setup()
	var opts := PhysicalOptions.for_target(r[0], r[1], r[2])
	check_eq(opts.size(), 5, "2 punches, 2 kicks, push")
	var punch: Dictionary = opts[0]
	check(punch["to_hit"].possible(), punch["to_hit"].summary())
	check_eq(punch["to_hit"].target(), 4, "piloting 5 - 1")
	check_eq(punch["damage"], 10)
	var kick: Dictionary = opts[2]
	check_eq(kick["to_hit"].target(), 4, "piloting 5 - 1")
	check_eq(kick["damage"], 20)


func test_no_hand_and_fired_arm() -> void:
	var s := GameState.new(open_map(5, 5))
	var j := mech("jenner_jr7d", 0, hex_at(2, 3), 0, 1)
	var t := mech("hunchback_hbk4g", 1, Hex.neighbor(hex_at(2, 3), 0), 3, 2)
	s.add_unit(j)
	s.add_unit(t)
	var punch: Dictionary = PhysicalOptions.for_target(s, j, t)[0]
	# 5 - 1 punch, no hand +1, no lower arm +2
	check_eq(punch["to_hit"].target(), 7)
	check_eq(punch["damage"], 2, "4 halved")
	for w in j.weapons:
		if w.loc == Location.LA:
			w.fired = true
	check(not PhysicalOptions.for_target(s, j, t)[0]["to_hit"].possible(), "fired arm can't punch")


func test_not_adjacent() -> void:
	var r := _setup()
	r[2].coord = hex_at(2, 0)
	for o in PhysicalOptions.for_target(r[0], r[1], r[2]):
		check(not o["to_hit"].possible(), "too far")


func test_declare_two_punches_or_one_kick() -> void:
	var r := _setup()
	var both := PhysicalOptions.declare(r[0], r[1], [
			{"kind": "punch", "limb": Location.LA, "target_id": 2},
			{"kind": "punch", "limb": Location.RA, "target_id": 2}])
	check_eq(both.size(), 2)
	var mixed := PhysicalOptions.declare(r[0], r[1], [
			{"kind": "punch", "limb": Location.LA, "target_id": 2},
			{"kind": "kick", "limb": Location.RL, "target_id": 2}])
	check_eq(mixed.size(), 1, "kick can't join a punch")


func test_kick_resolution_forces_roll() -> void:
	var r := _setup()
	var s: GameState = r[0]
	var t: Unit = r[2]
	s.declared_physical = PhysicalOptions.declare(s, r[1], [
			{"kind": "kick", "limb": Location.RL, "target_id": 2}])
	var dice := LoadedDice.new()
	dice.queue_2d6(9)   # hit (needs 4)
	dice.d6_queue.append(1)  # kick table: right leg
	PhysicalPhase.resolve(s, dice, func(_t, _d): pass)
	check_eq(t.armor[Location.RL], 0, "20 damage strips 20 armor")
	check_eq(t.psr_pending.size(), 1, "kicked -> piloting roll")


func _melee_pair(eq: Dictionary, tons := 45) -> Array:
	var s := GameState.new(open_map(5, 5))
	var def := UnitDef.from_dict({"id": "h", "name": "Hatch", "tonnage": tons, "walk_mp": 4,
			"equipment": eq}, weapons())
	var a := Unit.new(1, def, 0, hex_at(2, 3), 0)
	var t := mech("hunchback_hbk4g", 1, hex_at(2, 2), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _opt(s: GameState, a: Unit, t: Unit, kind: String) -> Dictionary:
	for o in PhysicalOptions.for_target(s, a, t):
		if o["kind"] == kind:
			return o
	return {}


func test_hatchet_and_sword() -> void:
	var g := _melee_pair({"RA": ["hatchet"], "LA": ["sword"]})
	var s: GameState = g[0]
	var a: Unit = g[1]
	var t: Unit = g[2]
	var h := _opt(s, a, t, "hatchet")
	check_eq(h["damage"], 9, "45 t / 5")
	check_eq(h["to_hit"].target(), 4, "piloting 5 - 1 " + h["to_hit"].summary())
	var sw := _opt(s, a, t, "sword")
	check_eq(sw["damage"], 6, "ceil(45 / 10) + 1")
	check_eq(sw["to_hit"].target(), 3, "piloting 5 - 2")
	check_eq(a.slots[Location.RA].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.MELEE).size(), 3, "45 t / 15")
	var decl := PhysicalOptions.declare(s, a, [{"kind": "hatchet", "limb": Location.RA, "target_id": t.id},
			{"kind": "punch", "limb": Location.LA, "target_id": t.id}])
	check_eq(decl.size(), 1, "a swing is the only attack that turn")


func test_club_from_woods() -> void:
	var s := GameState.new(make_map(["c0 c0 c0", "c0 H0 c0", "c0 c0 c0"]))
	var a := mech("blackjack_bj1", 0, hex_at(1, 1), 0, 1)
	var t := mech("hunchback_hbk4g", 1, hex_at(1, 0), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	check_eq(MeleeWeapons.club_here(s, a), "tree")
	a.club = "tree"
	var c := _opt(s, a, t, "club")
	check_eq(c["damage"], 9, "45 t / 5")
	check(c["to_hit"].possible(), c["to_hit"].impossible)
	s.declared_physical.append_array(PhysicalOptions.declare(s, a, [{"kind": "club", "limb": -1, "target_id": t.id}]))
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.queue_2d6(7)
	PhysicalPhase.resolve(s, dice, func(_t, _d): pass)
	check(t.psr_pending.any(func(p: Dictionary) -> bool: return p["reason"] == "was clubbed"), "target rolls")
	check_eq(a.club, "", "the tree broke")


func test_swings_across_levels() -> void:
	check_eq(MeleeWeapons.swing_table(0, true), "full", "prone, same level")
	check_eq(MeleeWeapons.swing_table(1, true), "full", "prone, one up")
	check_eq(MeleeWeapons.swing_table(-1, true), "", "prone, one down: DFA only")
	check_eq(MeleeWeapons.swing_table(1, false), "kick", "standing one up: at its legs")
	check_eq(MeleeWeapons.swing_table(-1, false), "punch", "standing one down: at its upper body")
	var g := _melee_pair({"RA": ["hatchet"]})
	var s: GameState = g[0]
	var a: Unit = g[1]
	var t: Unit = g[2]
	t.prone = true
	var h := _opt(s, a, t, "hatchet")
	check(h["to_hit"].possible(), h["to_hit"].impossible)
	check_eq(h["to_hit"].target(), 2, "piloting 5 - 1 - 2 for a prone target " + h["to_hit"].summary())
	check_eq(h["table"], "full")
	t.prone = false
	s.map.get_tile(t.coord).level = 1
	h = _opt(s, a, t, "hatchet")
	check(h["to_hit"].possible(), h["to_hit"].impossible)
	check_eq(h["table"], "kick", "no +4 when the level forces the table")
	check_eq(h["to_hit"].target(), 4)
	s.map.get_tile(t.coord).level = 0
	s.map.get_tile(a.coord).level = 1
	t.prone = true
	check(not _opt(s, a, t, "hatchet")["to_hit"].possible(), "prone a level down")


func test_cant_push_a_pushing_mech() -> void:
	var s := GameState.new(open_map(5, 5))
	var a := mech("atlas_as7d", 0, hex_at(2, 3), 0, 1)
	var t := mech("hunchback_hbk4g", 1, hex_at(2, 2), 0, 2)
	var c := mech("atlas_as7d", 0, hex_at(2, 1), 3, 3)
	for u in [a, t, c]:
		s.add_unit(u)
	s.declared_physical.append_array(PhysicalOptions.declare(s, t, [{"kind": "push", "limb": -1, "target_id": c.id}]))
	check_eq(s.declared_physical.size(), 1, "t pushes c")
	check(not _opt(s, a, t, "push")["to_hit"].possible(), "errata p. 83: t is pushing")
	s.declared_physical.clear()
	var ok := _opt(s, a, t, "push")
	check(ok["to_hit"].possible(), ok["to_hit"].impossible)
	s.declared_physical.append_array(PhysicalOptions.declare(s, a, [{"kind": "push", "limb": -1, "target_id": t.id}]))
	s.declared_physical.append_array(PhysicalOptions.declare(s, t, [{"kind": "push", "limb": -1, "target_id": c.id}]))
	var ev := []
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.queue_2d6(12)
	PhysicalPhase.resolve(s, dice, func(ty: StringName, d: Dictionary) -> void: ev.append([ty, d]))
	var mine: Array = ev.filter(func(e: Array) -> bool: return e[0] == GameEvent.PHYSICAL and e[1]["attacker_id"] == a.id)
	check(not mine[0][1]["hit"] and mine[0][1].get("why", "") != "", "declared first, then cancelled at resolution")
