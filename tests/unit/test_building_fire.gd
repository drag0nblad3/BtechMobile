extends TestCase
## Shooting buildings directly: thresholds, Destroy Checks, auto-hits.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _setup(type := "light") -> Array:
	events.clear()
	var rows := []
	for r in 6:
		rows.append("c0 c0 c0 c0 c0")
	var m := MapLoader.from_dict({"rows": rows,
			"buildings": [{"hex": "0303", "type": type, "height": 2}]}, terrain())
	var s := GameState.new(m)
	var a := mech("hunchback_hbk4g", 0, hex_at(2, 5), 0, 1)
	var e := mech("locust_lct1v", 1, hex_at(0, 0), 3, 2)
	s.add_unit(a)
	s.add_unit(e)
	return [s, a]


func _weapon(s: GameState, a: Unit, c: Vector2i, id: String) -> Dictionary:
	return BuildingFire.options(s, a, c).filter(func(o: Dictionary) -> bool: return o["weapon"].def.id == id)[0]


func test_threshold_and_destroy_check() -> void:
	var r := _setup("medium")
	var s: GameState = r[0]
	var a: Unit = r[1]
	var c := hex_at(2, 2)
	var ac20 := _weapon(s, a, c, "ac20")
	var th: ToHit = ac20["to_hit"]
	check(th.possible(), th.impossible)
	check_eq(th.target(), 0, "gunnery 4 - 4 building")
	BuildingFire.resolve(s, LoadedDice.new(), _emit, a, ac20["weapon"], c, th)
	check(s.map.get_tile(c).building != null, "nothing happens until the attacker is done")
	var dice := LoadedDice.new()
	dice.queue_2d6(9)  # medium: destroyed on 9+
	BuildingDamage.end_phase(s, dice, _emit)
	check(s.map.get_tile(c).building == null, "20 damage >= threshold 10, check passed")
	check_eq(s.map.get_tile(c).terrain.id, "rubble")
	check(Explainer.text(events[0], s, ExplainLevel.LIGHT).contains("building at 0303"), "names the building")


func test_under_threshold_or_failed_check_is_forgotten() -> void:
	var r := _setup("heavy")
	var s: GameState = r[0]
	BuildingDamage.add(s, 1, hex_at(2, 2), 13)
	BuildingDamage.end_phase(s, LoadedDice.new(), _emit)
	check(s.map.get_tile(hex_at(2, 2)).building != null, "13 is under the heavy threshold of 14")
	check(s.building_hits.is_empty(), "damage forgotten")
	BuildingDamage.add(s, 1, hex_at(2, 2), 14)
	var dice := LoadedDice.new()
	dice.queue_2d6(9)  # heavy needs 10
	BuildingDamage.end_phase(s, dice, _emit)
	check(s.map.get_tile(hex_at(2, 2)).building != null, "check failed: it stands")
	check_eq(BuildingRules.destroy_mod(20), 0)
	check_eq(BuildingRules.destroy_mod(21), 1)
	check_eq(BuildingRules.destroy_mod(31), 2)


func test_adjacent_auto_hit_and_full_clusters() -> void:
	var r := _setup("light")
	var s: GameState = r[0]
	var g := mech("griffin_grf1n", 0, hex_at(2, 3), 0, 3)
	s.add_unit(g)
	var lrm := _weapon(s, g, hex_at(2, 2), "lrm10")
	check(lrm["to_hit"].auto_hit != "", "next door: can't miss, even inside minimum range")
	check_eq(lrm["to_hit"].target(), 2)
	BuildingFire.resolve(s, LoadedDice.new([1]), _emit, g, lrm["weapon"], hex_at(2, 2), lrm["to_hit"])
	check_eq(int(s.building_hits[g.id][hex_at(2, 2)]), 10, "every missile hits")


func test_civilian_falls_to_any_hit() -> void:
	var r := _setup("civilian")
	var s: GameState = r[0]
	BuildingDamage.add(s, 1, hex_at(2, 2), 2)
	BuildingDamage.end_phase(s, LoadedDice.new(), _emit)
	var tile := s.map.get_tile(hex_at(2, 2))
	check(tile.building == null, "flattened")
	check(tile.terrain.id != "rubble", "small civilian buildings leave no rubble")


func test_declared_through_controller() -> void:
	var r := _setup()
	var s: GameState = r[0]
	var a: Unit = r[1]
	var decl := FireOptions.declare(s, a, [{"weapon": 0, "hex": hex_at(2, 2)}, {"weapon": 1, "hex": hex_at(4, 4)}])
	check_eq(decl.size(), 1, "only the real building")
	check(decl[0].has("target_hex"), "stored as a building shot")
	check(Advisor.volley(s, a, [{"weapon": 0, "hex": hex_at(2, 2)}], ExplainLevel.LIGHT).begins_with("Expected"), "advice works")
