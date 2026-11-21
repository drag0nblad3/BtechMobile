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


func test_designs_carry_narc() -> void:
	var db := UnitDb.load_dir()
	var raven := Unit.new(9, db.get_def("raven_rvn3l"), 0, Vector2i.ZERO, 0)
	check(raven.weapons.any(func(w: MountedWeapon) -> bool: return w.def.beacon), "Raven has a beacon")
	var kto := Unit.new(9, db.get_def("kintaro_kto19"), 0, Vector2i.ZERO, 0)
	check(kto.weapons.filter(func(w: MountedWeapon) -> bool: return w.narc_ammo).size() == 2, "both SRM racks can load Narc missiles")
	check(db.get_def("hunchback_hbk4g_rac").weapon_mounts.any(func(m: Dictionary) -> bool: return m["weapon"].rotary))


func test_bot_tags_target_for_homing_missiles() -> void:
	var v := _setup()
	var n: Unit = v[1]
	var t: Unit = v[3]
	n.weapons.append(MountedWeapon.new(WeaponDb.load_file().get_def("medium_laser"), Location.LA, false))
	var shots := [{"weapon": 1, "target_id": t.id}]
	check(BotNarc.add_beacons(v[0], n, shots).contains("Narc pod"))
	check_eq(shots.size(), 2)
	Narc.attach(v[0], n, t, Location.CT)
	var again := [{"weapon": 1, "target_id": t.id}]
	check_eq(BotNarc.add_beacons(v[0], n, again), "", "already tagged")


func test_indirect_fire_at_a_pod_needs_no_spotter() -> void:
	var v := _setup()
	var s: GameState = v[0]
	var l: Unit = v[2]
	var t: Unit = v[3]
	for r in 4:
		s.map.get_tile(hex_at(2, r)).level = 4  # a ridge hides the target from both friends
	l.weapons[0].mode = Narc.KIND
	var th := ToHitCalc.weapon(s, l, l.weapons[0], t)
	check(not th.possible(), "no pod, no spotter: can't fire")
	Narc.attach(s, v[1], t, Location.CT)
	s.turn = 2
	th = ToHitCalc.weapon(s, l, l.weapons[0], t)
	check(th.possible(), th.impossible)
	check(th.indirect and th.spotter_id == -1, "indirect, with no spotter (p. 188)")
	check(not th.narc_homing, "no -1 and no +2 cluster bonus when indirect")
	check(th.mods.any(func(m: Dictionary) -> bool: return m["value"] == 1 and m["label"].begins_with("indirect")), th.summary())
	check(not th.mods.any(func(m: Dictionary) -> bool: return m["label"].begins_with("spotter")), "no spotter modifiers")
	l.weapons[0].mode = ""
	check(not ToHitCalc.weapon(s, l, l.weapons[0], t).possible(), "standard missiles can't home on the pod")


func test_ams_can_shoot_down_a_pod() -> void:
	events.clear()
	var s := GameState.new(open_map(16, 4))
	s.turn = 1
	var n := Unit.new(1, _def("n", {"RA": ["narc_beacon"], "RT": ["ammo:narc_beacon"]}), 0, hex_at(1, 2), 2)
	var t := Unit.new(3, _def("t", {"CT": ["ams"], "LT": ["ammo:ams"]}), 1, hex_at(4, 2), 5)
	s.add_unit(n)
	s.add_unit(t)
	check(AntiMissile.engaging(t, n, n.weapons[0]) != null, "a Narc pod is a missile the AMS can engage")
	var dice := LoadedDice.new()
	dice.queue_2d6(10)
	dice.d6_queue.append(4)  # 4-6: shot down (p. 206)
	var d := _shoot(s, n, t, dice)
	check(d.get("pod_shot_down", false), "4 destroys the pod")
	check(t.narc_pods.is_empty())
	check(Explainer.text(events[-1], s, ExplainLevel.FULL).contains("shoots down"))
	dice = LoadedDice.new()
	dice.queue_2d6(10)
	dice.d6_queue.append(3)  # 1-3: the pod gets through
	d = _shoot(s, n, t, dice)
	check(not d.get("pod_shot_down", false) and d.has("narc_loc"), "3: it sticks")
	check_eq(t.narc_pods.size(), 1)
