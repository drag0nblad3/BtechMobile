extends TestCase
## Asset movement and stacking (book pp. 141-143).

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func _state(rows: Array, units: Array) -> GameState:
	var s := GameState.new(make_map(rows))
	for u: Unit in units:
		s.add_unit(u)
	return s


func _reach(s: GameState, u: Unit, mode := MoveMode.Kind.RUN) -> Dictionary:
	return MovePlanner.plan(s, u, mode).reachable_hexes()


func test_terrain_restrictions() -> void:
	var rows := ["c0 L0 H0 r0 u0 w0d1"]
	var tank := asset("test_tank", 0, hex_at(0, 0), 2)
	var s := _state(rows, [tank])
	check(AssetMoveCost.may_enter(tank.asset.card, s.map.get_tile(hex_at(1, 0))), "tracked: light woods")
	check(not AssetMoveCost.may_enter(tank.asset.card, s.map.get_tile(hex_at(2, 0))), "tracked: no heavy woods")
	var truck := asset("test_wheeled", 0, hex_at(0, 0))
	for col in [1, 2, 3, 4]:
		check(not AssetMoveCost.may_enter(truck.asset.card, s.map.get_tile(hex_at(col, 0))), "wheeled kept out of col %d" % col)
	var hover := asset("test_hover", 0, hex_at(0, 0))
	check(not AssetMoveCost.may_enter(hover.asset.card, s.map.get_tile(hex_at(1, 0))), "hover: no woods")
	check(AssetMoveCost.may_enter(hover.asset.card, s.map.get_tile(hex_at(5, 0))), "hover: water")
	check(not AssetMoveCost.may_enter(tank.asset.card, s.map.get_tile(hex_at(5, 0))), "tank: no depth 1")
	var inf := asset("test_foot", 0, hex_at(0, 0))
	check(AssetMoveCost.may_enter(inf.asset.card, s.map.get_tile(hex_at(2, 0))), "foot: heavy woods")
	check(not AssetMoveCost.may_enter(inf.asset.card, s.map.get_tile(hex_at(5, 0))), "foot: no water")


func test_hover_treats_rough_as_clear() -> void:
	var hover := asset("test_hover", 0, hex_at(0, 0), 2)
	var s := _state(["c0 r0"], [hover])
	check_eq(AssetMoveCost.enter_cost(s, hover, hex_at(0, 0), hex_at(1, 0)), 1, "rough costs 1")
	var tank := asset("test_tank", 0, hex_at(0, 0), 2)
	check_eq(AssetMoveCost.enter_cost(s, tank, hex_at(0, 0), hex_at(1, 0)), 2, "tank pays rough")


func test_levels_cost_two_one_at_a_time() -> void:
	var tank := asset("test_tank", 0, hex_at(0, 0), 2)
	var s := _state(["c0 c1 c3"], [tank])
	check_eq(AssetMoveCost.enter_cost(s, tank, hex_at(0, 0), hex_at(1, 0)), 3, "1 + 2 per level")
	check_eq(AssetMoveCost.enter_cost(s, tank, hex_at(1, 0), hex_at(2, 0)), MoveCost.PROHIBITED, "two levels: no")
	check_eq(AssetMoveCost.enter_cost(s, tank, hex_at(0, 0), hex_at(1, 0), true), MoveCost.PROHIBITED, "backing: no level changes")


func test_backward_halves_mp() -> void:
	var tank := asset("test_tank", 0, hex_at(2, 2), 0)
	var s := _state(["c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0"], [tank])
	var fwd := MovePlanner.plan(s, tank, MoveMode.Kind.RUN)
	check_eq(fwd.budget, 4, "4 MP forward")
	check(not fwd.reachable_hexes().has(hex_at(2, 4)), "no backing up without declaring it")
	var back := MovePlanner.plan(s, tank, MoveMode.Kind.WALK)
	check_eq(back.budget, 2, "declared backward: half")
	check(back.reachable_hexes().has(hex_at(2, 4)), "two hexes back")


func test_infantry_turns_free() -> void:
	var inf := asset("test_jump", 0, hex_at(1, 1), 0)
	var foot := asset("test_foot", 0, hex_at(1, 1), 0)
	var s := _state(["c0 c0 c0", "c0 c0 c0", "c0 c0 c0"], [foot])
	var r := _reach(s, foot)
	check_eq(r.size(), 7, "1 MP, any direction, no facing cost")
	check(inf.def.jump_mp == 3, "jump infantry jump")


func test_pavement_bonus() -> void:
	var truck := asset("test_wheeled", 0, hex_at(0, 0), 3)
	var s := _state(["p0", "p0", "p0", "p0", "p0", "p0", "p0", "c0"], [truck])
	var opts := MovePlanner.plan(s, truck, MoveMode.Kind.RUN)
	check(opts.reachable_hexes().has(hex_at(0, 6)), "six road hexes on 5 MP")
	check(not opts.reachable_hexes().has(hex_at(0, 7)), "leaving the road loses the bonus")
	check_eq(opts.budget, 6, "5 MP + 1 on pavement")


func test_stacking() -> void:
	var tank := asset("test_tank", 0, hex_at(1, 0), 2)
	var m := mech("griffin_grf1n", 0, hex_at(0, 0), 2, 1)
	var e_inf := asset("test_foot", 1, hex_at(2, 0), 0, 30)
	var s := _state(["c0 c0 c0 c0"], [tank, m, e_inf])
	check(not AssetStacking.can_end(s, m, hex_at(1, 0)), "vehicles count as 'Mechs")
	check(AssetStacking.can_end(s, m, hex_at(2, 0)), "a 'Mech may share with one enemy infantry")
	check(AssetStacking.can_pass(s, m, hex_at(2, 0)), "Assets don't hinder enemy 'Mechs")
	check(not AssetStacking.can_pass(s, tank, hex_at(2, 0)), "a vehicle can't drive through enemies")
	var f1 := asset("test_foot", 0, hex_at(3, 0), 0, 40)
	var f2 := asset("test_foot", 0, hex_at(3, 0), 0, 41)
	s.add_unit(f1)
	check(AssetStacking.can_end(s, f2, hex_at(3, 0)), "two friendly infantry")
	s.add_unit(f2)
	var f3 := asset("test_foot", 0, hex_at(0, 0), 0, 42)
	check(not AssetStacking.can_end(s, f3, hex_at(3, 0)), "not three")
	check(not AssetStacking.can_end(s, m, hex_at(3, 0)), "a 'Mech can't join two friendly infantry")
	check(s.unit_at(hex_at(2, 0)) == e_inf, "infantry alone")


func test_move_runs_without_rolls() -> void:
	var tank := asset("test_tank", 0, hex_at(0, 0), 3)
	var s := _state(["c0", "r0", "c0", "c0"], [tank])
	var target := MoveOptions.key(hex_at(0, 2), 3)
	check(MoveExecutor.run(s, LoadedDice.new(), _emit, tank, target, MoveMode.Kind.RUN, -1), "moved")
	check_eq(tank.coord, hex_at(0, 2), "arrived")
	check(events.filter(func(e: Array) -> bool: return e[0] == GameEvent.PSR).is_empty(), "no piloting rolls")


func test_emplacement_stays() -> void:
	var b := asset("test_bunker", 0, hex_at(1, 1))
	var s := _state(["c0 c0 c0", "c0 c0 c0"], [b])
	check_eq(_reach(s, b).size(), 1, "immobile")
