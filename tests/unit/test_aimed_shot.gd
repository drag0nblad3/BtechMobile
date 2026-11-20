extends TestCase
## Aimed shots at immobile targets (p. 70).


func _setup() -> Array:
	var s := GameState.new(open_map(10, 4))
	var a := mech("griffin_grf1n", 0, hex_at(1, 2), 2, 1)
	var t := mech("atlas_as7d", 1, hex_at(4, 2), 5, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _wi(u: Unit, id: String) -> int:
	for i in u.weapons.size():
		if u.weapons[i].def.id == id:
			return i
	return -1


func _mod(th: ToHit, label: String) -> int:
	for m in th.mods:
		if m["label"] == label:
			return int(m["value"])
	return 999


func test_only_immobile_and_no_clusters() -> void:
	var v: Array = _setup()
	var s: GameState = v[0]
	var a: Unit = v[1]
	var t: Unit = v[2]
	var ppc := a.weapons[_wi(a, "ppc")]
	var lrm := a.weapons[_wi(a, "lrm10")]
	var th := ToHitCalc.weapon(s, a, ppc, t, false)
	check(AimedShot.problem(s, ppc, t, Location.CT, th) != "", "a moving target can't be aimed at")
	t.shutdown = true
	th = ToHitCalc.weapon(s, a, ppc, t, false)
	check_eq(AimedShot.problem(s, ppc, t, Location.CT, th), "")
	check(AimedShot.problem(s, lrm, t, Location.CT, ToHitCalc.weapon(s, a, lrm, t, false)) != "", "missiles can't aim")


func test_head_shot_modifiers() -> void:
	var v: Array = _setup()
	var s: GameState = v[0]
	var a: Unit = v[1]
	var t: Unit = v[2]
	t.shutdown = true
	var wi := _wi(a, "ppc")
	var plain: ToHit = FireOptions.declare(s, a, [{"weapon": wi, "target_id": t.id}])[0]["to_hit"]
	var ct: ToHit = FireOptions.declare(s, a, [{"weapon": wi, "target_id": t.id, "aim": Location.CT}])[0]["to_hit"]
	var hd: ToHit = FireOptions.declare(s, a, [{"weapon": wi, "target_id": t.id, "aim": Location.HEAD}])[0]["to_hit"]
	check_eq(ct.target(), plain.target(), "body aim: same number, -4 kept")
	check_eq(hd.target(), plain.target() + 4 + 3, "head: no -4, +3")
	check_eq(_mod(hd, "target immobile"), 999)
	check_eq(hd.aim_loc, Location.HEAD)


func test_aim_roll_picks_location() -> void:
	var v: Array = _setup()
	var s: GameState = v[0]
	var a: Unit = v[1]
	var t: Unit = v[2]
	t.shutdown = true
	var wi := _wi(a, "ppc")
	var th: ToHit = FireOptions.declare(s, a, [{"weapon": wi, "target_id": t.id, "aim": Location.LA}])[0]["to_hit"]
	var events := []
	var emit := func(type: Variant, d: Dictionary) -> void: events.append([type, d])
	var la := t.armor[Location.LA]
	WeaponFire.resolve(s, LoadedDice.new([6, 6, 5]), emit, a, a.weapons[wi], t, th)
	check_eq(t.armor[Location.LA], la - 10, "4+ on the aim roll: left arm")
	var fired: Dictionary = events.filter(func(e: Array) -> bool: return e[0] == GameEvent.WEAPON_FIRED)[0][1]
	check(fired["aim_hit"])
	check(Explainer.text(GameEvent.new(GameEvent.WEAPON_FIRED, fired), s, ExplainLevel.FULL).contains("lands on the left arm"))
	# Aim roll 2: the location is rolled normally (2d6 = 7: center torso).
	var ct := t.armor[Location.CT]
	WeaponFire.resolve(s, LoadedDice.new([6, 6, 2, 3, 4]), emit, a, a.weapons[wi], t, th)
	check_eq(t.armor[Location.CT], ct - 10, "missed the aim: rolled location")
