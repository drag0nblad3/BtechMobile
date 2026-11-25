extends TestCase
## Special Pilot Abilities, batch 3 (Campaign Operations pp. 73-81):
## Range Master, Cluster Hitter, Human TRO, Tactical Genius, Terrain Master.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _labels(th: ToHit) -> Array:
	return th.mods.map(func(m: Dictionary) -> String: return m["label"])


func test_range_master_swaps_with_short() -> void:
	var s := GameState.new(open_map(12, 3))
	var a := mech("hunchback_hbk4g", 0, hex_at(0, 1), 2, 1)
	var t := mech("jenner_jr7d", 1, hex_at(5, 1), 5, 2)
	s.add_unit(a)
	s.add_unit(t)
	var laser := gun(a, "medium_laser")
	var medium := ToHitCalc.weapon(s, a, laser, t).target()
	t.coord = hex_at(2, 1)
	var short := ToHitCalc.weapon(s, a, laser, t).target()
	Spa.grant(a.pilot, Spa.RANGE_MASTER, 1, "medium")
	check_eq(ToHitCalc.weapon(s, a, laser, t).target(), short + 2, "short range takes the +2")
	t.coord = hex_at(5, 1)
	check_eq(ToHitCalc.weapon(s, a, laser, t).target(), medium - 2, "medium range costs nothing")


func test_cluster_hitter_adds_one() -> void:
	var cat := mech("catapult_cplt_c1", 0, hex_at(0, 0), 0, 1)
	var lrm: MountedWeapon = null
	for w in cat.weapons:
		if w.def.indirect:
			lrm = w
	var plain := WeaponModes.cluster(lrm, 1, LoadedDice.new([4, 4]))
	var hitter := WeaponModes.cluster(lrm, 1, LoadedDice.new([4, 4]), false, false, false, false, 0, 1)
	check_eq(int(hitter["bonus"]), int(plain["bonus"]) + 1, "+1 on the cluster roll")
	check(int(hitter["n"]) > int(plain["n"]), "more missiles hit on 8 + 1")


func test_human_tro_adds_to_crit_roll() -> void:
	var s := GameState.new(open_map(5, 3))
	var a := mech("hunchback_hbk4g", 0, hex_at(0, 1), 2, 1)
	var t := mech("jenner_jr7d", 1, hex_at(2, 1), 5, 2)
	s.add_unit(a)
	s.add_unit(t)
	check_eq(HumanTro.mod(s, a.id), 0)
	Spa.grant(a.pilot, Spa.HUMAN_TRO)
	check_eq(HumanTro.mod(s, a.id), 1)
	var steps: Array[Dictionary] = [{"loc": Location.CT, "breached": true, "destroyed": false}]
	CriticalHits.after_damage(s, LoadedDice.new([3, 4]), _emit, t, steps, false, HumanTro.mod(s, a.id))
	var ev := events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.CRIT_CHECK)
	check_eq(int(ev[0].data["roll"]), 8, "7 + 1")
	check_eq(int(ev[0].data["crits"]), 1, "now a critical hit")


func test_tactical_genius_rerolls_a_loss() -> void:
	var s := GameState.new(open_map(5, 3))
	var a := mech("hunchback_hbk4g", 0, hex_at(0, 1), 2, 1)
	var t := mech("jenner_jr7d", 1, hex_at(2, 1), 5, 2)
	s.add_unit(a)
	s.add_unit(t)
	var r := {"rolls": {0: 5, 1: 9}, "order": [0, 1], "bonus": {}}
	TacticalGenius.apply(s, LoadedDice.new([6, 6]), r)
	check(not r.has("genius"), "no genius, no reroll")
	Spa.grant(t.pilot, Spa.TACTICAL_GENIUS)
	TacticalGenius.apply(s, LoadedDice.new([6, 6]), r)
	check(not r.has("genius"), "the winner keeps its roll")
	Spa.grant(a.pilot, Spa.TACTICAL_GENIUS)
	TacticalGenius.apply(s, LoadedDice.new([6, 6]), r)
	check_eq(int(r["rolls"][0]), 12)
	check_eq(r["order"], [1, 0], "the reroll won")
	check_eq(r["genius"], [0])


func test_terrain_masters_pay_less() -> void:
	var s := GameState.new(make_map(["c0", "L0", "H0", "r0", "u0", "c1", "w0d2"]))
	var u := mech("hunchback_hbk4g", 0, hex_at(0, 0), 3, 1)
	s.add_unit(u)
	var before: Array[int] = []
	for i in range(1, 6):
		before.append(MovePlanner.enter_cost(s, u, hex_at(0, i - 1), hex_at(0, i), MoveMode.Kind.WALK, 2))
	Spa.grant(u.pilot, Spa.TERRAIN_MASTER, 1, TerrainMaster.FOREST_RANGER)
	Spa.grant(u.pilot, Spa.TERRAIN_MASTER, 1, TerrainMaster.MOUNTAINEER)
	var climbing := MovePlanner.enter_cost(s, u, hex_at(0, 0), hex_at(0, 6), MoveMode.Kind.WALK, 2)
	Spa.grant(u.pilot, Spa.TERRAIN_MASTER, 1, TerrainMaster.FROGMAN)
	check_eq(MovePlanner.enter_cost(s, u, hex_at(0, 0), hex_at(0, 6), MoveMode.Kind.WALK, 2), climbing - 1, "deep water")
	var water := MovePlanner.enter_cost(s, u, hex_at(0, 0), hex_at(0, 6), MoveMode.Kind.WALK, 2)
	check(water > 0, "deep water costs MP")
	var names := ["light woods", "heavy woods", "rough", "rubble", "climbing out of rubble"]
	for i in range(1, 6):
		var mp := MovePlanner.enter_cost(s, u, hex_at(0, i - 1), hex_at(0, i), MoveMode.Kind.WALK, 2)
		check_eq(mp, before[i - 1] - 1, names[i - 1])
	check_eq(MovePlanner.enter_cost(s, u, hex_at(0, 0), hex_at(0, 1), MoveMode.Kind.WALK, 2), 1, "light woods like clear")


func test_mountaineer_rubble_roll_and_forest_ranger_cover() -> void:
	var s := GameState.new(make_map(["c0", "u0", "L0"]))
	var u := mech("hunchback_hbk4g", 0, hex_at(0, 0), 3, 1)
	s.add_unit(u)
	var path: Array[Vector3i] = [MoveOptions.key(hex_at(0, 1), 3)]
	var from := MoveOptions.key(hex_at(0, 0), 3)
	check_eq(int(MovePsr.action_rolls(s, u, path, from, MoveMode.Kind.WALK)[0]["mod"]), 0)
	Spa.grant(u.pilot, Spa.TERRAIN_MASTER, 1, TerrainMaster.MOUNTAINEER)
	check_eq(int(MovePsr.action_rolls(s, u, path, from, MoveMode.Kind.WALK)[0]["mod"]), -1, "Mountaineer -1")
	var e := mech("jenner_jr7d", 1, hex_at(0, 0), 3, 2)
	u.coord = hex_at(0, 2)
	s.add_unit(e)
	Spa.grant(u.pilot, Spa.TERRAIN_MASTER, 1, TerrainMaster.FOREST_RANGER)
	u.move_mode = MoveMode.Kind.RUN
	check(not _labels(ToHitCalc.weapon(s, e, e.weapons[0], u)).has("Forest Ranger"), "running: no cover")
	u.move_mode = MoveMode.Kind.WALK
	check(_labels(ToHitCalc.weapon(s, e, e.weapons[0], u)).has("Forest Ranger"), "walked in woods: +1")
