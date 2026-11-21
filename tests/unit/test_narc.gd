extends TestCase
## Narc missile beacons (book p. 188).

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _def(id: String, eq: Dictionary) -> UnitDef:
	return UnitDef.from_dict({"id": id, "name": id, "tonnage": 50, "walk_mp": 4,
			"armor": {"CT": 20, "LT": 20, "RT": 20, "LA": 16, "RA": 16, "LL": 20, "RL": 20, "HD": 9},
			"equipment": eq}, weapons())


## Side 0: a Narc spotter and an LRM boat with Narc-equipped ammo; side 1: the target.
func _setup(target_ecm := false) -> Array:
	events.clear()
	var s := GameState.new(open_map(16, 4))
	s.turn = 1
	var n := Unit.new(1, _def("n", {"RA": ["narc_beacon"], "RT": ["ammo:narc_beacon"]}), 0, hex_at(1, 1), 2)
	var l := Unit.new(2, _def("l", {"LT": ["lrm10", "ammo:lrm10:narc"]}), 0, hex_at(1, 2), 2)
	var t := Unit.new(3, _def("t", {"LT": ["guardian_ecm"]} if target_ecm else {}), 1, hex_at(4, 2), 5)
	for u in [n, l, t]:
		s.add_unit(u)
	return [s, n, l, t]


func _shoot(s: GameState, a: Unit, t: Unit, dice: LoadedDice) -> Dictionary:
	var th := ToHitCalc.weapon(s, a, a.weapons[0], t)
	WeaponFire.resolve(s, dice, _emit, a, a.weapons[0], t, th)
	return events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.WEAPON_FIRED)[-1].data


func test_beacon_attaches_a_pod_without_damage() -> void:
	var v := _setup()
	var t: Unit = v[3]
	var armor := t.armor.duplicate()
	var dice := LoadedDice.new()
	dice.queue_2d6(10)
	dice.queue_2d6(7)  # hit location: CT
	var d := _shoot(v[0], v[1], t, dice)
	check(d["hit"])
	check_eq(d["narc_loc"], Location.CT)
	check_eq(t.narc_pods.size(), 1)
	check_eq(t.armor, armor, "no damage")
	check(Explainer.text(events[0], v[0], ExplainLevel.FULL).contains("Narc pod"))


func test_narc_missiles_home_from_the_next_turn() -> void:
	var v := _setup()
	var s: GameState = v[0]
	var l: Unit = v[2]
	var t: Unit = v[3]
	check_eq(l.weapons[0].mode, Narc.KIND, "only Narc ammo aboard: loaded")
	var before := ToHitCalc.weapon(s, l, l.weapons[0], t).target()
	Narc.attach(s, v[1], t, Location.LT)
	check_eq(ToHitCalc.weapon(s, l, l.weapons[0], t).target(), before, "not in the turn it lands")
	s.turn = 2
	var th := ToHitCalc.weapon(s, l, l.weapons[0], t)
	check_eq(th.target(), before - 1, "-1 to hit")
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.queue_2d6(3)  # 3 + 2 = 5 on the 10 column: 6
	check_eq(_shoot(s, l, t, dice)["missiles"], 6, "+2 cluster roll")
	t.structure[Location.LT] = 0
	check(not Narc.homing(s, l, t), "pod gone with its location")


func test_ecm_and_standard_ammo_get_no_help() -> void:
	var v := _setup(true)
	var s: GameState = v[0]
	s.turn = 2
	Narc.attach(s, v[1], v[3], Location.CT)
	s.turn = 3
	check(not Narc.homing(s, v[2], v[3]), "target inside its own ECM")
	var w := _setup()
	var ws: GameState = w[0]
	Narc.attach(ws, w[1], w[3], Location.CT)
	ws.turn = 2
	var l: Unit = w[2]
	l.weapons[0].mode = ""
	check(not ToHitCalc.weapon(ws, l, l.weapons[0], w[3]).narc_homing, "standard missiles don't home")
	check_eq(AmmoBin.new(WeaponDb.load_file().get_def("narc_beacon"), 0).explosion_damage(), 12, "6 pods x 2")
