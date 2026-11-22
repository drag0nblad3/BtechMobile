extends TestCase
## Special Narc and iNarc pods (NarcPods, pp. 193-194).

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _def(id: String, eq: Dictionary) -> UnitDef:
	return UnitDef.from_dict({"id": id, "name": id, "tonnage": 50, "walk_mp": 4,
			"armor": {"CT": 20, "LT": 20, "RT": 20, "LA": 16, "RA": 16, "LL": 20, "RL": 20, "HD": 9},
			"equipment": eq}, weapons())


## An iNarc shooter loaded with `pod` pods, a friend with an Artemis LRM, and a target.
func _setup(pod: String) -> Array:
	var s := GameState.new(open_map(16, 4))
	s.turn = 1
	var n := Unit.new(1, _def("n", {"RA": ["inarc_beacon"], "RT": ["ammo:inarc_beacon:" + pod]}), 0, hex_at(1, 2), 2)
	var t := Unit.new(3, _def("t", {"LA": ["lrm10+artemis"], "LT": ["ammo:lrm10", "c3_slave"]}), 1, hex_at(6, 2), 5)
	for u in [n, t]:
		s.add_unit(u)
	return [s, n, t]


func _shoot(v: Array) -> void:
	var n: Unit = v[1]
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.queue_2d6(7)
	WeaponFire.resolve(v[0], dice, _emit, n, n.weapons[0], v[2], ToHitCalc.weapon(v[0], n, n.weapons[0], v[2]))


func test_explosive_pod_does_damage() -> void:
	var v := _setup("explosive")
	check_eq(v[1].weapons[0].mode, NarcPods.EXPLOSIVE, "the only pods it has")
	var t: Unit = v[2]
	var before := t.armor[Location.CT]
	_shoot(v)
	check_eq(before - t.armor[Location.CT], 6, "6 damage from an iNarc explosive pod")
	check(t.narc_pods.is_empty(), "nothing sticks")


func test_haywire_pod() -> void:
	var v := _setup("haywire")
	var t: Unit = v[2]
	_shoot(v)
	check_eq(t.narc_pods[0]["kind"], NarcPods.HAYWIRE)
	check(not NarcPods.has(v[0], t, NarcPods.HAYWIRE), "works from the next turn")
	v[0].turn = 2
	var th := ToHitCalc.weapon(v[0], t, t.weapons[0], v[1])
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "haywire pod" and m["value"] == 1), "+1 to its shots")


func test_ecm_pod() -> void:
	var v := _setup("ecm")
	var t: Unit = v[2]
	_shoot(v)
	v[0].turn = 2
	check(Ecm.jammed(v[0], t), "acts as if inside hostile ECM")
	var th := ToHitCalc.weapon(v[0], t, t.weapons[0], v[1])
	check(Ecm.artemis_blocked(v[0], t, v[1], th) != "", "its Artemis loses the bonus")


func test_nemesis_pod_pulls_missiles() -> void:
	var v := _setup("nemesis")
	var s: GameState = v[0]
	var n: Unit = v[1]
	var t: Unit = v[2]
	var friend := Unit.new(4, _def("f", {}), 1, hex_at(3, 2), 5)  # between t and n
	s.add_unit(friend)
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.queue_2d6(7)
	WeaponFire.resolve(s, dice, _emit, n, n.weapons[0], friend, ToHitCalc.weapon(s, n, n.weapons[0], friend))
	s.turn = 2
	check(NarcPods.decoy(s, LoadedDice.new(), t, t.weapons[0], n) == friend, "its friend in the way draws the Artemis LRMs")
	t.weapons[0].artemis = false
	check(NarcPods.decoy(s, LoadedDice.new(), t, t.weapons[0], n) == null, "plain missiles aren't drawn")

