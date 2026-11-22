extends TestCase
## Asset attacks and attacks on Assets (book pp. 144-145).

func _state(rows: Array, units: Array) -> GameState:
	var s := GameState.new(make_map(rows))
	for u: Unit in units:
		s.add_unit(u)
	return s


func _mod(th: ToHit, label: String) -> int:
	for m in th.mods:
		if m["label"] == label:
			return int(m["value"])
	return -99


func test_asset_attack_uses_skill_no_movement() -> void:
	var tank := asset("test_tank", 0, hex_at(0, 0), 2, 1)
	var m := mech("griffin_grf1n", 1, hex_at(4, 0), 5, 2)
	var s := _state(["c0 c0 c0 c0 c0"], [tank, m])
	tank.move_mode = MoveMode.Kind.RUN
	tank.hexes_moved = 4
	var th := ToHitCalc.weapon(s, tank, tank.weapons[0], m)
	check(th.possible(), th.impossible)
	check_eq(_mod(th, "Skill"), 5, "base Skill 5")
	check_eq(_mod(th, "medium range"), 2, "4 hexes: medium on 3/6/9")
	check_eq(th.target(), 7, "no attacker movement modifier")


func test_no_turret_front_only() -> void:
	var hover := asset("test_hover", 0, hex_at(2, 1), 0, 1)
	var m := mech("griffin_grf1n", 1, hex_at(2, 3), 0, 2)
	var s := _state(["c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0"], [hover, m])
	check(not ToHitCalc.weapon(s, hover, hover.weapons[0], m).possible(), "behind: no turret")
	var tank := asset("test_tank", 0, hex_at(2, 1), 0, 3)
	s.add_unit(tank)
	check(ToHitCalc.weapon(s, tank, tank.weapons[0], m).possible(), "turreted: 360 degrees")


func test_target_tmm_or_terrain() -> void:
	var m := mech("griffin_grf1n", 0, hex_at(0, 0), 2, 1)
	var hover := asset("test_hover", 1, hex_at(3, 0), 0, 2)
	var s := _state(["c0 c0 c0 c0 H0"], [m, hover])
	var w := gun(m, "ppc")
	var th := ToHitCalc.weapon(s, m, w, hover)
	check_eq(_mod(th, "target TMM"), 3, "fixed TMM +3, though it never moved")
	var jump := asset("test_jump", 1, hex_at(4, 0), 0, 3)
	s.add_unit(jump)
	th = ToHitCalc.weapon(s, m, w, jump)
	check_eq(_mod(th, "target in cover"), 2, "heavy woods +2 ties TMM +2: only one counts")
	check_eq(_mod(th, "target TMM"), -99, "not both")


func test_emplacement_immobile() -> void:
	var m := mech("griffin_grf1n", 0, hex_at(0, 0), 2, 1)
	var b := asset("test_bunker", 1, hex_at(3, 0), 0, 2)
	var s := _state(["c0 c0 c0 c0"], [m, b])
	check_eq(_mod(ToHitCalc.weapon(s, m, gun(m, "ppc"), b), "target immobile"), -4, "-4")


func test_infantry_fires_into_own_hex() -> void:
	var inf := asset("test_foot", 0, hex_at(1, 0), 0, 1)
	var m := mech("griffin_grf1n", 1, hex_at(1, 0), 0, 2)
	var s := _state(["c0 c0 c0"], [inf, m])
	check(ToHitCalc.weapon(s, inf, inf.weapons[0], m).possible(), "infantry: own hex")
	check(not ToHitCalc.weapon(s, m, gun(m, "medium_laser"), inf).possible(), "a 'Mech can't fire into its own hex")


func test_one_target_per_turn() -> void:
	var tank := asset("test_tank", 0, hex_at(0, 0), 2, 1)
	var a := mech("griffin_grf1n", 1, hex_at(2, 0), 5, 2)
	var b := mech("griffin_grf1n", 1, hex_at(3, 0), 5, 3)
	var s := _state(["c0 c0 c0 c0"], [tank, a, b])
	var decl := FireOptions.declare(s, tank, [{"weapon": 0, "target_id": 2}, {"weapon": 1, "target_id": 3}])
	check_eq(decl.size(), 1, "second target dropped")


func test_physical_attacks_on_assets() -> void:
	var m := mech("griffin_grf1n", 0, hex_at(0, 0), 2, 1)
	var t := asset("test_tank", 1, hex_at(1, 0), 0, 2)
	var s := _state(["c0 c0"], [m, t])
	var kinds := {}
	for o in PhysicalOptions.for_target(s, m, t):
		if o["to_hit"].possible():
			kinds[o["kind"]] = true
	check(kinds.has("kick"), "kick a tank")
	check(not kinds.has("push"), "no pushing Assets")
	check(not kinds.has("punch"), "a one-level target at your feet: no punch")
	check(not Charge.option(s, m, t, "charge")["to_hit"].possible(), "no charging Assets")
	check(PhysicalOptions.for_target(s, t, m).is_empty(), "Assets don't punch back")
