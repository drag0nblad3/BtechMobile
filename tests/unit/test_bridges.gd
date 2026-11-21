extends TestCase
## Bridges (Bridges): road-cost decks over water, passing underneath,
## support limits, shooting and collapse.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _kinds() -> Array:
	return events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.BUILDING) \
			.map(func(e: GameEvent) -> String: return e.data["kind"])


## 3 x 5 map, a river across row 2 and a bridge over it at column 1 (0203).
func _state(type := "medium", extra := {}) -> GameState:
	var bridges := [{"hexes": ["0203"], "type": type}]
	if not extra.is_empty():
		bridges = [extra]
	var m := MapLoader.from_dict({"rows": ["c0 c0 c0", "c0 c0 c0", "w0d1 w0d1 w0d1", "c0 c0 c0", "c0 c0 c0"],
			"bridges": bridges}, terrain())
	events.clear()
	return GameState.new(m)


func test_loads_with_default_class_and_level() -> void:
	var b := _state().map.get_tile(hex_at(1, 2)).bridge
	check(b != null, "bridge placed")
	check_eq(b.type.id, "medium")
	check_eq(b.level, 0, "deck at the water surface by default")
	check_eq(b.span, [hex_at(1, 2)])


func test_deck_costs_one_mp_and_skips_the_water() -> void:
	var s := _state()
	check_eq(MoveCost.enter_cost(s.map, hex_at(1, 3), hex_at(1, 2), MoveMode.Kind.WALK), 1, "deck = road")
	check_eq(MoveCost.enter_cost(s.map, hex_at(1, 2), hex_at(1, 1), MoveMode.Kind.WALK), 1, "and off again")
	check_eq(MoveCost.enter_cost(s.map, hex_at(0, 3), hex_at(0, 2), MoveMode.Kind.WALK), 3, "the river beside it")
	var u := mech("griffin_grf1n", 0, hex_at(1, 4), 0, 1)
	s.add_unit(u)
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.RUN)
	check_eq(opts.cost.get(MoveOptions.key(hex_at(1, 1), 0), -1), 3, "three hexes for three MP")
	check(MoveExecutor.run(s, LoadedDice.new(), _emit, u, MoveOptions.key(hex_at(1, 2), 0), MoveMode.Kind.RUN, -1))
	check(u.on_bridge, "stands on the deck")
	check_eq(Roofs.floor_of(s.map, u), 0, "at deck level, not the river bed")
	check_eq(WaterCombat.zone(s.map, u), WaterCombat.Zone.DRY, "out of the water")
	check(not u.psr_pending.any(func(p: Dictionary) -> bool: return String(p.get("reason", "")).contains("water")),
			"no roll for running into water")


func test_passing_underneath() -> void:
	var s := _state()
	var river := s.map.get_tile(hex_at(0, 2))
	var under := s.map.get_tile(hex_at(1, 2))
	check(not Bridges.onto_deck(river, under), "from the water you go under")
	check(Bridges.fits_under(under), "a 'Mech in depth 1 fits under a deck at the surface")
	var u := mech("griffin_grf1n", 0, hex_at(0, 2), 2, 1)
	s.add_unit(u)
	check(MoveExecutor.run(s, LoadedDice.new(), _emit, u, MoveOptions.key(hex_at(1, 2), 2), MoveMode.Kind.WALK, -1))
	check(not u.on_bridge, "underneath")
	check_eq(WaterCombat.zone(s.map, u), WaterCombat.Zone.WADING)
	var low := _state("medium", {"hexes": ["0102"], "level": 0})  # deck flat on dry ground
	check(not Bridges.fits_under(low.map.get_tile(hex_at(0, 1))), "no room under a deck at ground level")


func test_heavy_mech_brings_down_a_light_bridge() -> void:
	var s := _state("light")
	var u := mech("atlas_as7d", 0, hex_at(1, 3), 0, 1)
	s.add_unit(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(5)  # 5 + 6 (three classes over) >= 7
	check(MoveExecutor.run(s, dice, _emit, u, MoveOptions.key(hex_at(1, 2), 0), MoveMode.Kind.WALK, -1))
	check(_kinds().has("bridge_heavy") and _kinds().has("bridge_collapsed"), str(_kinds()))
	check(s.map.get_tile(hex_at(1, 2)).bridge == null, "gone")
	check(not u.on_bridge and u.prone, "fell into the river")


func test_collapse_hits_mech_underneath_and_drops_the_span() -> void:
	var s := _state("medium", {"hexes": ["0103", "0203", "0303"], "type": "medium"})
	var u := mech("griffin_grf1n", 0, hex_at(1, 2), 0, 1)
	s.add_unit(u)
	Bridges.collapse(s, LoadedDice.new(), _emit, s.map.get_tile(hex_at(0, 2)))
	check(s.map.get_tile(hex_at(1, 2)).bridge != null, "one of three gone: the rest stands")
	Bridges.collapse(s, LoadedDice.new(), _emit, s.map.get_tile(hex_at(2, 2)))
	check(s.map.get_tile(hex_at(1, 2)).bridge == null, "two of three gone: it all comes down")
	var hit := events.filter(func(e: GameEvent) -> bool:
		return e.type == GameEvent.BUILDING and e.data["kind"] == "bridge_collapsed" and int(e.data["unit_id"]) == 1)
	check(hit.size() == 1 and int(hit[0].data["damage"]) == 5, "half the medium threshold on the 'Mech below")


func test_shoot_a_bridge_down() -> void:
	var s := _state("light")
	var a := mech("griffin_grf1n", 0, hex_at(1, 4), 0, 1)
	s.add_unit(a)
	var w := a.weapons[0]
	var th := BuildingFire.to_hit(s, a, w, hex_at(1, 2))
	check(th.impossible == "", th.impossible)
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "building"), "a bridge can't dodge: -4")
	BuildingDamage.add(s, a.id, hex_at(1, 2), 9)
	var dice := LoadedDice.new()
	dice.queue_2d6(8)  # light bridge: destroyed on 7+
	BuildingDamage.end_phase(s, dice, _emit)
	check(s.map.get_tile(hex_at(1, 2)).bridge == null, "shot down at the end of the phase")
	check_eq(WoodsFire.noun(s.map.get_tile(hex_at(1, 1))), "clear")


func test_explained_on_the_hex_line() -> void:
	var t := TerrainText.describe(_state().map.get_tile(hex_at(1, 2)), ExplainLevel.FULL)
	check(t.contains("Medium bridge") and t.contains("deck at level 0"), t)
