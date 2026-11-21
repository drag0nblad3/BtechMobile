extends TestCase
## Physical attacks on buildings (p. 135): always hit, count toward the
## Destroy Check.


func _setup(height: int) -> Array:
	var s := GameState.new(open_map(6, 6))
	var c := hex_at(2, 1)
	var tile := s.map.get_tile(c)
	tile.building = Building.new(BuildingType.from_dict({"id": "t", "name": "Test",
			"threshold": 10, "destroy_tn": 8}), height)
	var a := mech("atlas_as7d", 0, hex_at(2, 2), 0, 1)
	s.add_unit(a)
	return [s, a, c]


func test_options_and_levels() -> void:
	var v: Array = _setup(2)
	var opts := BuildingMelee.options(v[0], v[1], v[2])
	var by := {}
	for o in opts:
		by["%s:%d" % [o["kind"], o["limb"]]] = o
	check(by["punch:%d" % Location.LA]["to_hit"].possible(), "punch a 2-level building")
	check_eq(by["punch:%d" % Location.LA]["to_hit"].target(), 2, "always hits")
	check(by["kick:%d" % Location.RL]["to_hit"].possible(), "kick it")
	check_eq(by["kick:%d" % Location.RL]["damage"], 20)
	var low: Array = _setup(1)
	var lo := BuildingMelee.options(low[0], low[1], low[2])
	check(not lo[0]["to_hit"].possible(), "too low to punch: " + lo[0]["to_hit"].impossible)
	check(PhysicalOptions.any_possible(v[0], v[1]), "a building next door counts")


func test_kick_damages_building() -> void:
	var v: Array = _setup(2)
	var s: GameState = v[0]
	var a: Unit = v[1]
	var c: Vector2i = v[2]
	var decl := BuildingMelee.declare(s, a, c, [{"kind": "kick", "limb": Location.RL, "hex": c},
			{"kind": "punch", "limb": Location.LA, "hex": c}])
	check_eq(decl.size(), 1, "a kick is the only attack")
	s.declared_physical.append_array(decl)
	var events := []
	var emit := func(t: Variant, d: Dictionary) -> void: events.append([t, d])
	var dice := LoadedDice.new()
	dice.queue_2d6(12)  # destroy check fails for the building
	PhysicalPhase.resolve(s, dice, emit)
	var phys: Array = events.filter(func(e: Array) -> bool: return e[0] == GameEvent.PHYSICAL)
	check_eq(phys.size(), 1)
	check(phys[0][1]["hit"])
	check(Explainer.text(GameEvent.new(GameEvent.PHYSICAL, phys[0][1]), s, ExplainLevel.FULL).contains("kicks the building"))
	check(a.psr_pending.is_empty(), "no piloting roll for kicking a building")
	var checks := events.filter(func(e: Array) -> bool: return e[0] == GameEvent.BUILDING)
	check(checks.size() > 0, "20 damage over the threshold: Destroy Check")


func test_two_punches() -> void:
	var v: Array = _setup(2)
	var c: Vector2i = v[2]
	var decl := BuildingMelee.declare(v[0], v[1], c, [{"kind": "punch", "limb": Location.LA, "hex": c},
			{"kind": "punch", "limb": Location.RA, "hex": c}])
	check_eq(decl.size(), 2)
