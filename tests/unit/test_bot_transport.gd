extends TestCase
## The computer's use of APCs (BotTransport).


func _gc(units: Array, rows := 20) -> GameController:
	var r := []
	for i in rows:
		r.append("c0 c0")
	var s := GameState.new(make_map(r))
	for u: Unit in units:
		s.add_unit(u)
	var gc := GameController.new(s, 1)
	gc.state.phase = Phase.Kind.MOVEMENT
	gc.state.side_order.assign([0, 0, 0, 0])
	gc.state.order_index = 0
	return gc


func test_infantry_boards_when_enemy_far() -> void:
	var apc := asset("test_apc", 0, hex_at(0, 0), 3, 1)
	var inf := asset("test_foot", 0, hex_at(0, 0), 0, 2)
	var e := mech("griffin_grf1n", 1, hex_at(0, 19), 0, 3)
	var gc := _gc([apc, inf, e])
	apc.has_moved = true
	check(Bot.act(gc, 0), "acted")
	check_eq(inf.asset.carried_by, apc.id, "rides the APC")


func test_infantry_stays_out_when_enemy_near() -> void:
	var apc := asset("test_apc", 0, hex_at(0, 0), 3, 1)
	var inf := asset("test_foot", 0, hex_at(0, 0), 0, 2)
	var e := mech("griffin_grf1n", 1, hex_at(0, 5), 0, 3)
	var gc := _gc([apc, inf, e])
	check(BotTransport.ride(gc.state, inf) == null, "fights on foot")


func test_apc_drives_to_pick_up() -> void:
	var apc := asset("test_apc", 0, hex_at(0, 0), 3, 1)
	var inf := asset("test_foot", 0, hex_at(0, 3), 0, 2)
	var e := mech("griffin_grf1n", 1, hex_at(0, 19), 0, 3)
	var gc := _gc([apc, inf, e])
	var m := BotTransport.pickup(gc.state, apc)
	check(not m.is_empty(), "plans a pickup")
	check_eq(MoveOptions.coord_of(m["key"]), inf.coord, "to the infantry's hex")


func test_riders_get_out_near_enemy() -> void:
	var apc := asset("test_apc", 0, hex_at(0, 10), 3, 1)
	var inf := asset("test_foot", 0, hex_at(0, 10), 0, 2)
	var e := mech("griffin_grf1n", 1, hex_at(0, 14), 0, 3)
	var gc := _gc([apc, inf, e])
	AssetTransport.board(gc.state, func(_t: StringName, _d: Dictionary) -> void: pass, inf, apc)
	apc.has_moved = true
	check(BotTransport.after_move(gc, apc) != "", "announces")
	check_eq(inf.asset.carried_by, -1, "on foot again")
