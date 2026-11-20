extends TestCase
## Shooting buildings directly.


func _setup() -> Array:
	var rows := []
	for r in 6:
		rows.append("c0 c0 c0 c0 c0")
	var m := MapLoader.from_dict({"rows": rows,
			"buildings": [{"hex": "0303", "type": "light", "height": 2}]}, terrain())
	var s := GameState.new(m)
	var a := mech("hunchback_hbk4g", 0, hex_at(2, 5), 0, 1)
	var e := mech("locust_lct1v", 1, hex_at(0, 0), 3, 2)
	s.add_unit(a)
	s.add_unit(e)
	return [s, a]


func test_to_hit_and_damage() -> void:
	var r := _setup()
	var s: GameState = r[0]
	var a: Unit = r[1]
	var c := hex_at(2, 2)
	var opts := BuildingFire.options(s, a, c)
	var ac20: Dictionary = opts.filter(func(o: Dictionary) -> bool: return o["weapon"].def.id == "ac20")[0]
	var th: ToHit = ac20["to_hit"]
	check(th.possible(), th.impossible)
	check_eq(th.target(), 0, "gunnery 4 - 4 building")
	var events: Array[GameEvent] = []
	var emit := func(t: StringName, d: Dictionary) -> void: events.append(GameEvent.new(t, d))
	BuildingFire.resolve(s, LoadedDice.new(), emit, a, ac20["weapon"], c, th)
	check(s.map.get_tile(c).building == null, "20 damage flattens a 15 CF building")
	check_eq(s.map.get_tile(c).terrain.id, "rubble")
	var fired: GameEvent = events[0]
	check(Explainer.text(fired, s, ExplainLevel.LIGHT).contains("building at 0303"), "names the building")


func test_declared_through_controller() -> void:
	var r := _setup()
	var s: GameState = r[0]
	var a: Unit = r[1]
	var decl := FireOptions.declare(s, a, [{"weapon": 0, "hex": hex_at(2, 2)}, {"weapon": 1, "hex": hex_at(4, 4)}])
	check_eq(decl.size(), 1, "only the real building")
	check(decl[0].has("target_hex"), "stored as a building shot")
	check(Advisor.volley(s, a, [{"weapon": 0, "hex": hex_at(2, 2)}], ExplainLevel.LIGHT).begins_with("Expected"), "advice works")
