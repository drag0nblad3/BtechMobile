extends TestCase
## A plan-local occupancy index must not alter movement legality or ordering.


func test_index_matches_live_stacking_queries() -> void:
	var s := GameState.new(open_map(5, 5))
	var mover := mech("griffin_grf1n", 0, hex_at(2, 2), 0, 1)
	var friend := mech("jenner_jr7d", 0, hex_at(2, 1), 0, 2)
	var enemy := mech("wolverine_wvr6r", 1, hex_at(1, 2), 0, 3)
	var wreck := mech("griffin_grf1n", 1, hex_at(3, 2), 0, 4)
	wreck.destroyed = true
	var hidden := mech("jenner_jr7d", 1, hex_at(2, 3), 0, 5)
	var support := asset("savior_repair_vehicle", 0, hex_at(2, 1), 0, 6)
	for u: Unit in [mover, friend, enemy, wreck, support]:
		s.add_unit(u)
	s.hidden.append(hidden)
	for moving: Unit in [mover, support]:
		var indexed := AssetStacking.occupancy(s, moving)
		for c: Vector2i in s.map.coords():
			check_eq(AssetStacking.others(s, moving, c, indexed), AssetStacking.others(s, moving, c))
			check_eq(AssetStacking.can_end(s, moving, c, indexed), AssetStacking.can_end(s, moving, c))
			check_eq(AssetStacking.can_pass(s, moving, c, indexed), AssetStacking.can_pass(s, moving, c))
			for facing in 6:
				var k := MoveOptions.key(c, facing)
				check_eq(MovePlanner._successors(s, moving, k, MoveMode.Kind.WALK, indexed),
						MovePlanner._successors(s, moving, k, MoveMode.Kind.WALK))
	enemy.coord = hex_at(0, 0)
	var fresh := AssetStacking.occupancy(s, mover)
	check(AssetStacking.others(s, mover, enemy.coord, fresh).has(enemy), "new plan sees new position")
