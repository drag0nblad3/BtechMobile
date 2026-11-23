extends TestCase
## Battle armor stealth and mimetic armor (BaStealth), one-shot squad launchers.


func _squad(def_id: String) -> Unit:
	var db := UnitDb.new()
	db.weapons = WeaponDb.load_file()
	db.add_battle_armor(UnitDb.BA_DIR)
	return Unit.new(1, db.get_def(def_id), 1, hex_at(0, 0), 0)


func _mod(t: Unit, br: int) -> int:
	var th := ToHit.new()
	BaStealth.add_mods(th, t, br)
	var n := 0
	for m: Dictionary in th.mods:
		n += int(m["value"])
	return n


func test_stealth_by_range() -> void:
	var imp := _squad("hauberk_battle_armor_sqd4")
	check_eq([_mod(imp, WeaponDef.Bracket.SHORT), _mod(imp, WeaponDef.Bracket.MEDIUM), _mod(imp, WeaponDef.Bracket.LONG)], [1, 2, 3], "improved")
	var basic := _squad("kage_light_battle_armor_dest_sqd4")
	check_eq([_mod(basic, WeaponDef.Bracket.SHORT), _mod(basic, WeaponDef.Bracket.LONG)], [0, 2], "basic")
	check_eq(_mod(_squad("amazon_battle_armor_mrr_sqd4"), WeaponDef.Bracket.LONG), 0, "advanced armor: no modifier")


func test_mimetic_fades_as_it_moves() -> void:
	var m := _squad("purifier_adaptive_battle_armor_laser_sqd4")
	check_eq(_mod(m, WeaponDef.Bracket.LONG), 3, "standing still")
	m.hexes_moved = 2
	check_eq(_mod(m, WeaponDef.Bracket.SHORT), 1)
	m.hexes_moved = 4
	check_eq(_mod(m, WeaponDef.Bracket.SHORT), 0)


func test_one_shot_launchers_fire_once() -> void:
	var sq := _squad("tengu_heavy_battle_armor_rl_sqd4")
	var rl := gun(sq, "ba_rl4")
	check_eq(WeaponFire.take_shots(sq, rl), 1, "fires")
	check_eq(WeaponFire.take_shots(sq, rl), 0, "spent")
	check(not sq.can_fire(rl), "can't fire again")
