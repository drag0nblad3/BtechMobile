extends TestCase
## Turn order: unequal numbers (book p. 41).


func _o(counts: Dictionary) -> Array[int]:
	var order: Array[int] = [1, 0]  # side 1 lost initiative
	return UnequalNumbers.order(counts, order)


func test_equal_sides_alternate() -> void:
	check_eq(_o({0: 2, 1: 2}), [1, 0, 1, 0] as Array[int])


func test_bigger_side_doubles_first() -> void:
	# 4 against 2: the bigger side moves two at a time.
	check_eq(_o({0: 4, 1: 2}), [1, 0, 0, 1, 0, 0] as Array[int])
	# 3 against 2: one double turn, then singles.
	check_eq(_o({0: 3, 1: 2}), [1, 0, 0, 1, 0] as Array[int])
	# Winner has fewer: it still acts after the loser's group each turn.
	check_eq(_o({0: 1, 1: 3}), [1, 1, 1, 0] as Array[int])


func test_book_examples() -> void:
	var groups := []
	for t in 10:
		groups.append(UnequalNumbers.group_size(18, 10, t))
	check_eq(groups, [2, 2, 2, 2, 2, 2, 2, 2, 1, 1], "18 vs 10: eight doubles")
	groups.clear()
	for t in 5:
		groups.append(UnequalNumbers.group_size(14, 5, t))
	check_eq(groups, [3, 3, 3, 3, 2], "14 vs 5")


func test_controller_uses_it() -> void:
	var s := GameState.new(open_map(10, 10))
	s.add_unit(mech("locust_lct1v", 0, hex_at(1, 1), 3, 1))
	s.add_unit(mech("locust_lct1v", 0, hex_at(2, 1), 3, 2))
	s.add_unit(mech("locust_lct1v", 0, hex_at(3, 1), 3, 3))
	s.add_unit(mech("locust_lct1v", 0, hex_at(4, 1), 3, 4))
	s.add_unit(mech("atlas_as7d", 1, hex_at(1, 8), 0, 5))
	s.add_unit(mech("atlas_as7d", 1, hex_at(2, 8), 0, 6))
	var gc := GameController.new(s, 1)
	gc.start_turn()
	check_eq(gc.state.side_order.size(), 6, "one activation per 'Mech")
	var zeros := gc.state.side_order.count(0)
	check_eq(zeros, 4)
