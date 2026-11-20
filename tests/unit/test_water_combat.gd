extends TestCase
## Fighting in water (book pp. 62, 66-67, 77, 127).


## Column 1 holds the given water/land tokens top to bottom; the rest is dry.
func _state(tokens: Array) -> GameState:
	var rows := []
	for t in tokens:
		rows.append("c0 %s c0" % t)
	return GameState.new(make_map(rows))


func _pair(s: GameState, a_row: int, t_row: int) -> Array:
	var a := mech("hunchback_hbk4g", 0, hex_at(1, a_row), 0, 1)
	var t := mech("hunchback_hbk4g", 1, hex_at(1, t_row), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [a, t]


func _weapon(u: Unit, id: String) -> MountedWeapon:
	for w in u.weapons:
		if w.def.id == id:
			return w
	return null


func test_no_shots_across_the_water_line() -> void:
	var s := _state(["c0", "w0d2", "c0", "c0"])
	var r := _pair(s, 3, 1)
	var th := ToHitCalc.weapon(s, r[0], _weapon(r[0], "medium_laser"), r[1])
	check(th.impossible.contains("water line"), th.impossible)
	th = ToHitCalc.weapon(s, r[1], _weapon(r[1], "medium_laser"), r[0])
	check(th.impossible.contains("energy") or th.impossible.contains("water line"), th.impossible)


func test_underwater_energy_weapons_lose_a_bracket() -> void:
	var s := _state(["c0", "w0d2", "w0d2", "w0d2", "w0d2", "w0d2"])
	var r := _pair(s, 4, 2)
	var a: Unit = r[0]
	var th := ToHitCalc.weapon(s, a, _weapon(a, "medium_laser"), r[1])
	check(th.possible(), th.impossible)
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "medium range under water"), th.summary())
	check(ToHitCalc.weapon(s, a, _weapon(a, "ac20"), r[1]).impossible.contains("energy"), "no autocannons under water")
	var far := mech("hunchback_hbk4g", 1, hex_at(1, 0), 3, 3)
	s.map.get_tile(hex_at(1, 0)).depth = 2
	s.map.get_tile(hex_at(1, 0)).terrain = s.map.get_tile(hex_at(1, 1)).terrain
	s.add_unit(far)
	# 4 hexes is medium range for a medium laser: long under water
	var th2 := ToHitCalc.weapon(s, a, _weapon(a, "medium_laser"), far)
	check(th2.mods.any(func(m: Dictionary) -> bool: return m["label"] == "long range under water"), th2.summary())
	far.coord = hex_at(1, 1)  # 3 hexes: long range for a small laser (1/2/3)
	check(ToHitCalc.weapon(s, a, _weapon(a, "small_laser"), far).impossible.contains("long range"), "long range is out under water")


func test_from_underwater_at_a_wading_target_hits_legs() -> void:
	var s := _state(["c0", "w0d1", "w0d2", "w0d2"])
	var r := _pair(s, 3, 1)
	var a: Unit = r[0]
	var t: Unit = r[1]
	var th := ToHitCalc.weapon(s, a, _weapon(a, "medium_laser"), t)
	check(th.possible() and th.legs_only, th.impossible)
	check(not th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "partial cover"), "no partial cover")
	var before := t.armor[Location.LL] + t.armor[Location.RL]
	var dice := LoadedDice.new()
	dice.queue_2d6(12)  # hit
	WeaponFire.resolve(s, dice, func(_t, _d): pass, a, _weapon(a, "medium_laser"), t, th)
	check(t.armor[Location.LL] + t.armor[Location.RL] < before, "a leg took the hit")
	# A wading 'Mech's arm weapons can't reach down to an underwater target.
	var th2 := ToHitCalc.weapon(s, t, _weapon(t, "medium_laser"), a)
	check(th2.impossible.contains("under water"), th2.impossible)


func test_physical_attacks_in_water() -> void:
	var s := _state(["c0", "w0d1", "w0d1", "c0"])
	var r := _pair(s, 2, 1)
	var a: Unit = r[0]
	var t: Unit = r[1]
	t.prone = true  # prone in depth 1: fully submerged
	check_eq(WaterCombat.zone(s.map, t), WaterCombat.Zone.UNDER)
	check(PhysicalOptions._punch(s, a, t, Location.RA)["to_hit"].impossible.contains("under water"))
	check_eq(WaterCombat.physical_blocked(s.map, a, t, "kick"), "", "a kick from the water reaches it")
	check_eq(WaterCombat.physical_damage(s.map, t, Location.CT, 9), 4, "half, rounded down")
	t.prone = false
	check_eq(WaterCombat.physical_damage(s.map, t, Location.CT, 9), 9, "wading: torso above water")
	check_eq(WaterCombat.physical_damage(s.map, t, Location.LL, 9), 4, "legs under")
