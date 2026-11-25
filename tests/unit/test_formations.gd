extends TestCase
## Formation Types and their bonus abilities (Campaign Operations pp. 60-66).

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _side(ids: Array) -> GameState:
	var s := GameState.new(open_map(10, 10))
	for i in ids.size():
		s.add_unit(mech(ids[i], 0, hex_at(i, 5), 0, i + 1))
	s.add_unit(mech("jenner_jr7d", 1, hex_at(0, 0), 3, 9))
	return s


func test_types_from_roles_weights_and_speed() -> void:
	var battle := _side(["battlemaster_blr1g", "battlemaster_blr1g", "battlemaster_blr1g", "battlemaster_blr1g"])
	check(FormationTypes.qualifying(Formation.members(battle, 0)).has("battle"), "all Brawlers: ideal Battle Lance")
	var fire := _side(["archer_arc2r", "archer_arc2r", "catapult_cplt_c1"])
	var ft := FormationTypes.qualifying(Formation.members(fire, 0))
	check(ft.has("fire") and ft.has("fire_support"), str(ft))
	check(not ft.has("striker"), "too slow to strike")
	var two := _side(["archer_arc2r", "archer_arc2r"])
	check(FormationTypes.qualifying(Formation.members(two, 0)).is_empty(), "two 'Mechs are no formation")


func test_fire_lance_snipers() -> void:
	var s := _side(["archer_arc2r", "archer_arc2r", "catapult_cplt_c1", "catapult_cplt_c1"])
	check(not Formation.setup(s, 0, "fire").is_empty())
	var snipers := Formation.members(s, 0).filter(func(u: Unit) -> bool: return Spa.has(u, Spa.SNIPER))
	check_eq(snipers.size(), 2, "two units get Sniper")
	check(not Spa.has(s.unit_by_id(9), Spa.SNIPER), "not the enemy")


func test_light_recon_and_losing_the_bonus() -> void:
	var s := _side(["dart_drt3s", "falcon_flc4n", "firestarter_fs9h"])
	check_eq(Formation.auto(s, 0), "light_recon")
	for u in Formation.members(s, 0):
		check(Spa.has(u, Spa.EAGLES_EYES) and Spa.has(u, Spa.FORWARD_OBSERVER), "every Light Recon unit")
	s.unit_by_id(1).destroyed = true
	Formation.check(s, _emit)
	check(not Spa.has(s.unit_by_id(2), Spa.EAGLES_EYES), "down to two: bonuses gone")
	check_eq(events[-1].type, GameEvent.FORMATION)


func test_battle_lance_shares_luck() -> void:
	var s := _side(["battlemaster_blr1g", "battlemaster_blr1g", "battlemaster_blr1g"])
	check_eq(int(Formation.setup(s, 0, "battle")["luck"]), 6)
	var u := s.unit_by_id(1)
	for i in 4:
		check(Lucky.psr(LoadedDice.new(), u, s) >= 0, "reroll %d" % (i + 1))
	check_eq(Lucky.psr(LoadedDice.new(), u, s), -1, "4 rerolls a unit at most")
	check_eq(int(Formation.of(s, u)["luck"]), 2)
	check(Lucky.psr(LoadedDice.new(), s.unit_by_id(2), s) >= 0, "another unit uses what's left")
	check_eq(Lucky.psr(LoadedDice.new(), u, null), -1, "no state, no shared luck")
