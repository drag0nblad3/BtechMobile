extends TestCase
## Battlefield Support Assets: cards, damage, Destroy Checks and
## Degradation (book pp. 140-148).

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func _state(units: Array, cols := 6, rows := 6) -> GameState:
	var s := GameState.new(open_map(cols, rows))
	for u: Unit in units:
		s.add_unit(u)
	events.clear()
	return s


func _of(type: StringName) -> Array:
	return events.filter(func(e: Array) -> bool: return e[0] == type).map(func(e: Array): return e[1])


func test_book_card_loads() -> void:
	var u := asset("savior_repair_vehicle", 0, hex_at(1, 1))
	var c := u.asset.card
	check_eq(c.mp, 4, "4t")
	check_eq(c.motive, "t", "tracked")
	check_eq(c.tmm, 1, "TMM +1")
	check_eq(c.long_range, 3, "1/2/3")
	check_eq(u.pilot.gunnery, 6, "Skill 6 is the base")
	check_eq(u.weapons.size(), 1, "3x1: one grouping")
	check_eq(u.weapons[0].def.damage, 3, "3 damage")
	check_eq(u.def.bv, 260, "13 BSP x 20 BV (p. 157)")
	u.set_asset_improved(true)
	check_eq(u.pilot.gunnery, 5, "improved Skill")
	check_eq(u.asset.bv(), 300, "15 BSP improved")
	check(c.has("APC") and c.special("APC") == 2, "APC2")


func test_groupings_mount_one_attack_each() -> void:
	var u := asset("test_tank", 0, hex_at(1, 1))
	check_eq(u.weapons.size(), 2, "5x2: two attacks")
	check(u.walk_mp() == 4 and u.run_mp() == 4, "same MP every turn")


func test_damage_bonus() -> void:
	check_eq(DestroyCheck.damage_bonus(10), 0, "1-10 +0")
	check_eq(DestroyCheck.damage_bonus(11), 1, "11-20 +1")
	check_eq(DestroyCheck.damage_bonus(20), 1, "20 +1")
	check_eq(DestroyCheck.damage_bonus(21), 2, "21-30 +2")
	check_eq(DestroyCheck.damage_bonus(35), 3, "book example: 35 damage +3")


func test_below_threshold_no_check() -> void:
	var t := asset("test_tank", 1, hex_at(2, 2))
	var s := _state([t])
	AssetDamage.take(_emit, t, 7, 5, "test")
	DestroyCheck.run(s, LoadedDice.new(), _emit)
	check(_of(GameEvent.DESTROY_CHECK).is_empty(), "7 < Threshold 8: no check")
	check_eq(t.asset.damage, 0, "damage wiped in the End Phase")
	check_eq(t.asset.check, 9, "no Degradation")


func test_check_survived_degrades() -> void:
	var t := asset("test_tank", 1, hex_at(2, 2))
	var s := _state([t])
	AssetDamage.take(_emit, t, 5, 5, "a")
	AssetDamage.take(_emit, t, 6, 5, "b")  # 11 total: +1
	var dice := LoadedDice.new()
	dice.queue_2d6(7)  # 7 + 1 = 8 < 9
	DestroyCheck.run(s, dice, _emit)
	var ev: Dictionary = _of(GameEvent.DESTROY_CHECK)[0]
	check_eq(ev["bonus"], 1, "11 damage: +1")
	check(not t.destroyed, "8 misses 9")
	check_eq(t.asset.check, 8, "Degradation: 9 -> 8")
	check_eq(t.asset.damage, 0, "damage erased")


func test_check_destroys() -> void:
	var t := asset("test_tank", 1, hex_at(2, 2))
	var s := _state([t])
	AssetDamage.take(_emit, t, 30, 5, "PPCs")  # +2
	var dice := LoadedDice.new()
	dice.queue_2d6(7)
	DestroyCheck.run(s, dice, _emit)
	check(t.destroyed, "7 + 2 = 9 meets 9")
	check(not _of(GameEvent.UNIT_DESTROYED).is_empty(), "announced")


func test_degraded_to_two_auto_fails() -> void:
	var t := asset("test_foot", 1, hex_at(2, 2))
	var s := _state([t])
	t.asset.check = 3
	AssetDamage.take(_emit, t, 1, 5, "a")
	var dice := LoadedDice.new()
	dice.queue_2d6(2)
	DestroyCheck.run(s, dice, _emit)
	check(not t.destroyed, "survives")
	check_eq(t.asset.check, 2, "down to 2")
	AssetDamage.take(_emit, t, 1, 5, "b")
	dice.queue_2d6(2)
	DestroyCheck.run(s, dice, _emit)
	check(t.destroyed, "next check fails whatever the roll")


func test_ai_weapons_degrade_infantry_twice() -> void:
	var inf := asset("test_foot", 1, hex_at(2, 2))
	var s := _state([inf])
	var mg := weapons().get_def("machine_gun")
	check(mg.attack_types().has("AI"), "machine gun is AI")
	AssetDamage.weapon_hit(_emit, inf, mg, inf, 2, FiringArc.FRONT)
	var dice := LoadedDice.new()
	dice.queue_2d6(2)
	DestroyCheck.run(s, dice, _emit)
	check_eq(inf.asset.check, 4, "6 - 2 Degradation")
	var tank := asset("test_tank", 1, hex_at(3, 3))
	s.add_unit(tank)
	AssetDamage.weapon_hit(_emit, tank, mg, tank, 8, FiringArc.FRONT)
	dice.queue_2d6(2)
	DestroyCheck.run(s, dice, _emit)
	check_eq(tank.asset.check, 8, "vehicles take the usual 1")


func test_rear_doubles_but_not_infantry() -> void:
	var t := asset("test_tank", 1, hex_at(2, 2))
	var inf := asset("test_foot", 1, hex_at(3, 3))
	check_eq(AssetDamage.take(_emit, t, 5, 1, "x", [], FiringArc.REAR), 10, "rear doubled")
	check_eq(AssetDamage.take(_emit, inf, 5, 1, "x", [], FiringArc.REAR), 5, "infantry: no rear")


func test_armor_specials_halve() -> void:
	var truck := asset("test_wheeled", 1, hex_at(2, 2))  # BRA
	check_eq(AssetDamage.take(_emit, truck, 5, 1, "AC/5", ["DB"]), 3, "BRA halves DB, rounding up")
	check_eq(AssetDamage.take(_emit, truck, 5, 1, "laser", ["DE"]), 5, "not lasers")
	var bunker := asset("test_bunker", 1, hex_at(3, 3))  # RFA
	check_eq(AssetDamage.take(_emit, bunker, 9, 1, "pulse", ["P"]), 5, "RFA halves pulse")
	var inf := asset("test_foot", 1, hex_at(4, 4))
	check_eq(AssetDamage.take(_emit, inf, 5, 1, "artillery", ["AE"]), 10, "AE doubled vs infantry")


func test_flamer_heat_is_damage() -> void:
	var t := asset("test_tank", 1, hex_at(2, 2))
	var fl := weapons().get_def("flamer")
	AssetDamage.weapon_hit(_emit, t, fl, t, 2, FiringArc.FRONT)
	check_eq(t.asset.damage, 2 + 2 * fl.heat_points, "2 damage + 2 per heat point")
	check_eq(t.outside_heat, 0, "no heat scale")


func test_weapon_fire_hits_card_not_locations() -> void:
	var m := mech("atlas_as7d", 0, hex_at(1, 1), 3, 1)
	var t := asset("test_tank", 1, hex_at(1, 3), 0, 2)
	var s := _state([m, t])
	var w := gun(m, "medium_laser")
	var th := ToHitCalc.weapon(s, m, w, t)
	check(th.possible(), th.impossible)
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	WeaponFire.resolve(s, dice, _emit, m, w, t, th)
	check_eq(t.asset.damage, 5, "5 on the card")
	var dmg: Dictionary = _of(GameEvent.DAMAGE)[0]
	check(dmg["asset"], "Asset damage event")


func test_end_phase_runs_checks() -> void:
	var t := asset("test_foot", 1, hex_at(2, 2))
	var s := _state([t])
	AssetDamage.take(_emit, t, 3, 7, "small laser")
	var dice := LoadedDice.new()
	dice.queue_2d6(6)
	EndPhase.run(s, dice, _emit)
	check(t.destroyed, "Threshold 1: a small laser triggers it; 6 meets 6")


func test_heat_phase_turns_fire_heat_to_damage() -> void:
	var t := asset("test_tank", 1, hex_at(2, 2))
	var s := _state([t])
	t.outside_heat = 2
	HeatPhase.run(s, LoadedDice.new(), _emit)
	check_eq(t.asset.damage, 4, "2 heat from a fire hex: 4 damage")
	check_eq(t.heat, 0, "no heat")


func test_explanations_at_every_level() -> void:
	var t := asset("test_tank", 1, hex_at(2, 2))
	var s := _state([t])
	AssetDamage.take(_emit, t, 12, -1, "PPC", [], FiringArc.REAR)
	var dice := LoadedDice.new()
	dice.queue_2d6(3)
	DestroyCheck.run(s, dice, _emit)
	for lvl in [ExplainLevel.FULL, ExplainLevel.LIGHT, ExplainLevel.OFF]:
		for e: Array in events:
			var txt := Explainer.text(GameEvent.new(e[0], e[1]), s, lvl)
			check(e[0] != GameEvent.DESTROY_CHECK or txt.contains("survives"), "check text: " + txt)
			check(e[0] != GameEvent.DAMAGE or txt.contains("24"), "damage text: " + txt)
