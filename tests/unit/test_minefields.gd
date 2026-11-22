extends TestCase
## Minefields (Minefields, pp. 156, 191, 193).


func _emit() -> Callable:
	return func(_t: Variant, _d: Dictionary) -> void: pass


func _setup() -> Array:
	var s := GameState.new(open_map(10, 4))
	var u := mech("atlas_as7d", 0, hex_at(1, 1), 2, 1)
	s.add_unit(u)
	return [s, u]


func _legs(u: Unit) -> int:
	return u.armor[Location.LL] + u.armor[Location.RL]


func test_lay_merges_with_own_field() -> void:
	var v := _setup()
	var s: GameState = v[0]
	Minefields.lay(s, _emit(), hex_at(3, 1), 1, 1)
	Minefields.lay(s, _emit(), hex_at(3, 1), 1, 1)
	check_eq(s.minefields.size(), 1)
	check_eq(int(s.minefields[0]["density"]), 2, "Light + Light = Medium")
	check_eq(int(s.minefields[0]["groups"]), 4)
	Minefields.lay(s, _emit(), hex_at(3, 1), 1, 3)
	check_eq(int(s.minefields[0]["groups"]), 6, "never past 6 groups")
	Minefields.lay(s, _emit(), hex_at(3, 1), 0, 1)
	check_eq(s.minefields.size(), 2, "each side keeps its own field")


func test_walking_in_sets_it_off() -> void:
	var v := _setup()
	var s: GameState = v[0]
	var u: Unit = v[1]
	var c := hex_at(2, 1)
	Minefields.lay(s, _emit(), c, 1, 1)  # Light: 9+, 2 groups
	var before := _legs(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(9)
	var path: Array[Vector3i] = [Vector3i(c.x, c.y, 2)]
	Minefields.after_move(s, dice, _emit(), u, path, u.coord, false)
	check_eq(before - _legs(u), 10, "two 5-point groups on the legs")
	check_eq(int(s.minefields[0]["groups"]), 1, "the field loses a group")
	var dice2 := LoadedDice.new()
	dice2.queue_2d6(8)
	Minefields.after_move(s, dice2, _emit(), u, path, u.coord, false)
	check_eq(int(s.minefields[0]["groups"]), 1, "a miss leaves it alone")


func test_jumping_over_is_safe() -> void:
	var v := _setup()
	var s: GameState = v[0]
	var u: Unit = v[1]
	Minefields.lay(s, _emit(), hex_at(2, 1), 1, 3)
	u.coord = hex_at(3, 1)
	var a := hex_at(2, 1)
	var b := hex_at(3, 1)
	var path: Array[Vector3i] = [Vector3i(a.x, a.y, 2), Vector3i(b.x, b.y, 2)]
	var dice := LoadedDice.new()
	Minefields.after_move(s, dice, _emit(), u, path, hex_at(1, 1), true)
	check_eq(int(s.minefields[0]["groups"]), 6, "no roll: it only lands in the far hex")


func test_artillery_clears_mines() -> void:
	var v := _setup()
	var s: GameState = v[0]
	Minefields.lay(s, _emit(), hex_at(4, 1), 1, 2)
	Minefields.lay(s, _emit(), hex_at(4, 1), 0, 1)
	var dice := LoadedDice.new()
	dice.queue_2d6(4)
	dice.queue_2d6(5)
	Minefields.clear(s, dice, _emit(), hex_at(4, 1))
	check(s.minefields.is_empty(), "the second side's 5 clears both fields")
