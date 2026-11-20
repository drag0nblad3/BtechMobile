extends TestCase
## Fire and smoke (book pp. 123-124, 136).

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


## Column 1, rows 0-4; 0102 burns, 0103 is a medium building (level 1).
func _state() -> GameState:
	events.clear()
	return GameState.new(MapLoader.from_dict({"rows": ["c0 c0 c0", "c0 c0 c0", "c0 c0 c0", "c0 c0 c0", "c0 c0 c0"],
			"fires": ["0202"], "buildings": [{"hex": "0204", "type": "medium", "height": 1}]}, terrain()))


func test_moving_through_and_standing_in_fire() -> void:
	var s := _state()
	var burning := Hex.from_label("0202")
	check(s.map.get_tile(burning).on_fire, "loaded from the map")
	var u := mech("hunchback_hbk4g", 0, burning + Vector2i(0, 2), 0, 1)
	s.add_unit(u)
	var to := MoveOptions.key(burning + Vector2i(0, -1), 0)
	check(MoveExecutor.run(s, LoadedDice.new(), _emit, u, to, MoveMode.Kind.WALK, -1))
	check_eq(u.outside_heat, 2, "2 heat for walking through the fire")
	var j := mech("griffin_grf1n", 0, burning + Vector2i(1, 1), 0, 2)
	s.add_unit(j)
	var path: Array[Vector3i] = [MoveOptions.key(burning, 0)]
	check_eq(Fire.move_heat(s.map, path, j.coord, true), 0, "jumping over doesn't count")
	u.coord = burning
	check_eq(Fire.stand_heat(s.map, u), 5, "5 in the Heat Phase")


func test_smoke_hides_targets() -> void:
	var s := _state()
	var burning := Hex.from_label("0202")
	var a := mech("hunchback_hbk4g", 0, burning + Vector2i(0, 3), 0, 1)
	var t := mech("hunchback_hbk4g", 1, burning, 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	var th := ToHitCalc.weapon(s, a, a.weapons[0], t)
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "target in smoke"), th.summary())
	t.coord = burning + Vector2i(0, -1)
	var los := LineOfSight.check(s.map, a, t)
	check_eq(los["woods"], 1, "smoke in between counts like light woods")


func test_flamer_sets_building_alight_and_collapse_puts_it_out() -> void:
	var s := _state()
	var c := Hex.from_label("0204")
	var a := mech("firestarter_fs9h", 0, c + Vector2i(0, 1), 0, 1)
	s.add_unit(a)
	var fl: MountedWeapon = a.weapons.filter(func(w: MountedWeapon) -> bool: return w.def.id == "flamer")[0]
	var th := BuildingFire.to_hit(s, a, fl, c)
	BuildingFire.resolve(s, LoadedDice.new(), _emit, a, fl, c, th)
	check_eq(Fire.heat_to_light(s.map.get_tile(c)), 2, "medium: 2 heat per level")
	Fire.end_phase(s, _emit)
	check(s.map.get_tile(c).on_fire, "2 flamer heat lights it")
	BuildingRules.collapse(s, LoadedDice.new(), _emit, s.map.get_tile(c))
	check(not s.map.get_tile(c).on_fire, "the fire dies with the building")
