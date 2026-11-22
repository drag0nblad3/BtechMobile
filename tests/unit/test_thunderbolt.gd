extends TestCase
## Thunderbolt missiles: one big missile, one location, AMS may stop it.


func _unit(eq: Dictionary, uid := 1, side := 0, at := Vector2i.ZERO, facing := 2) -> Unit:
	var d := UnitDef.from_dict({"id": "t%d" % uid, "name": "Test", "tonnage": 60, "walk_mp": 4,
			"armor": {"HD": 9, "CT": 30, "LT": 15, "RT": 15, "LA": 10, "RA": 10, "LL": 15, "RL": 15},
			"equipment": eq}, weapons())
	return Unit.new(uid, d, side, at, facing)


var _state: GameState


func _fire(target_eq: Dictionary, dice: LoadedDice) -> Array:
	var s := GameState.new(open_map(10, 3))
	_state = s
	var a := _unit({"RT": ["thunderbolt10", "ammo:thunderbolt10"]}, 1, 0, hex_at(0, 1), 2)
	var t := _unit(target_eq, 2, 1, hex_at(7, 1), 5)
	s.add_unit(a)
	s.add_unit(t)
	var ev := []
	WeaponFire.resolve(s, dice, func(ty: StringName, e: Dictionary) -> void: ev.append([ty, e]), a, a.weapons[0], t,
			ToHitCalc.weapon(s, a, a.weapons[0], t))
	return ev


func _dmg(ev: Array) -> Array:
	return ev.filter(func(e: Array) -> bool: return e[0] == GameEvent.DAMAGE).map(func(e: Array) -> int: return e[1]["amount"])


func test_one_hit_full_damage() -> void:
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.queue_2d6(7)
	check_eq(_dmg(_fire({"RA": ["medium_laser"]}, dice)), [10])
	check(weapons().get_def("thunderbolt10").indirect)
	check_eq(AmmoBin.new(weapons().get_def("thunderbolt20"), Location.RT).explosion_damage(), 60, "3 missiles x 20")


func test_ams_can_shoot_it_down() -> void:
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.d6_queue.append(5)  # AMS: 4-6 destroys it
	var ev := _fire({"CT": ["ams", "ammo:ams"]}, dice)
	check(_dmg(ev).is_empty())
	var shot: Dictionary = ev.filter(func(e: Array) -> bool: return e[0] == GameEvent.WEAPON_FIRED)[0][1]
	check(shot["pod_shot_down"])
	check(WeaponText.fired(_state, shot, ExplainLevel.FULL, {}).contains("Thunderbolt missile"), str(shot))
