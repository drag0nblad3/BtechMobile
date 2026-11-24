extends TestCase
## Move danger preview: expected incoming damage at a hex, compared with staying put.


func _setup() -> Array:
	var s := GameState.new(open_map(30, 3))
	var u := mech("hunchback_hbk4g", 0, hex_at(10, 1), 2, 1)
	var e := mech("hunchback_hbk4g", 1, hex_at(16, 1), 5, 2)
	s.add_unit(u)
	s.add_unit(e)
	return [s, u, e]


func test_moving_and_distance_lower_danger() -> void:
	var a := _setup()
	var s: GameState = a[0]
	var u: Unit = a[1]
	var stay := Threat.incoming(s, u, u.coord, u.facing, -1, 0)
	check(stay > 0.0, "enemy in range can hurt you")
	var walked := Threat.incoming(s, u, u.coord, u.facing, MoveMode.Kind.WALK, 3)
	check(walked < stay, "moving 3 hexes makes you harder to hit: %.1f < %.1f" % [walked, stay])
	check_eq(Threat.incoming(s, u, hex_at(0, 1), u.facing, MoveMode.Kind.RUN, 10), 0.0, "out of every range")
	check_eq([u.coord, u.move_mode, u.hexes_moved], [hex_at(10, 1), -1, 0], "unit put back")


func test_text_levels() -> void:
	var a := _setup()
	var s: GameState = a[0]
	var u: Unit = a[1]
	check_eq(Threat.text(s, u, u.coord, u.facing, -1, 0, ExplainLevel.OFF), "", "off")
	check(Threat.text(s, u, u.coord, u.facing, -1, 0, ExplainLevel.LIGHT).begins_with("Danger here"), "light")
	var far := Threat.text(s, u, hex_at(0, 1), u.facing, MoveMode.Kind.RUN, 10, ExplainLevel.FULL)
	check(far.begins_with("No enemy weapon"), far)
	var near := Threat.text(s, u, hex_at(13, 1), u.facing, MoveMode.Kind.WALK, 3, ExplainLevel.FULL)
	check(near.contains("staying put"), near)
