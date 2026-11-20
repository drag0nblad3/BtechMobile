extends TestCase


func test_distance() -> void:
	check_eq(Hex.distance(Vector2i(0, 0), Vector2i(3, -1)), 3)
	check_eq(Hex.distance(Vector2i(2, 2), Vector2i(2, 2)), 0)


func test_neighbors_are_adjacent_and_reversible() -> void:
	var c := Vector2i(4, 2)
	for f in 6:
		var n := Hex.neighbor(c, f)
		check_eq(Hex.distance(c, n), 1, "facing %d" % f)
		check_eq(Hex.direction_to(n, c), Hex.rotate(f, 3), "reverse of %d" % f)


func test_turn_cost() -> void:
	check_eq(Hex.turn_cost(0, 3), 3)
	check_eq(Hex.turn_cost(5, 1), 2)
	check_eq(Hex.turn_cost(2, 2), 0)


func test_offset_round_trip_and_labels() -> void:
	for col in 6:
		for row in 6:
			var o := Vector2i(col, row)
			check_eq(Hex.to_offset(Hex.from_offset(o)), o)
	check_eq(Hex.label(Hex.from_offset(Vector2i(7, 4))), "0805")


func test_odd_columns_sit_lower() -> void:
	# On a mapsheet, 0201 (col 2) is the SE neighbor of 0101.
	var a := Hex.from_offset(Vector2i(0, 0))
	var b := Hex.from_offset(Vector2i(1, 0))
	check_eq(Hex.direction_to(a, b), 2)


func test_line() -> void:
	var l := Hex.line(Vector2i(0, 0), Vector2i(3, 0))
	check_eq(l.size(), 4)
	check_eq(l[3], Vector2i(3, 0))
