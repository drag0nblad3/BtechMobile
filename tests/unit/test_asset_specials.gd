extends TestCase
## Asset Specials: APC/Mechanized transport, Swarm, AMS, ECM, Probe (book pp. 148-151).

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func _gc(units: Array, rows := ["c0 c0 c0 c0", "c0 c0 c0 c0", "c0 c0 c0 c0"]) -> GameController:
	var s := GameState.new(make_map(rows))
	for u: Unit in units:
		s.add_unit(u)
	var gc := GameController.new(s, 1)
	gc.event.connect(func(e: GameEvent) -> void: events.append([e.type, e.data]))
	return gc


func _side_moves(gc: GameController, side: int) -> void:
	gc.state.phase = Phase.Kind.MOVEMENT
	gc.state.side_order.assign([side, side, side, side])
	gc.state.order_index = 0


func test_card_specials_become_equipment() -> void:
	var apc := asset("test_apc", 0, hex_at(0, 0))
	check_eq(apc.def.ecm_loc, Location.CT, "ECM Special: an ECM suite")
	check_eq(ActiveProbe.range_of(apc.def), 4, "PRB: probe range 4")
	check(Ecm.working(apc), "ECM works")


func test_board_ride_and_deploy() -> void:
	var apc := asset("test_apc", 0, hex_at(1, 1), 3, 1)
	var inf := asset("test_foot", 0, hex_at(1, 1), 0, 2)
	var e := mech("griffin_grf1n", 1, hex_at(1, 0), 3, 3)
	var gc := _gc([apc, inf, e])
	_side_moves(gc, 0)
	check(gc.board(inf, apc), "boards as its move")
	check_eq(inf.asset.carried_by, apc.id, "aboard")
	check(not gc.pending_units().has(inf), "riders don't act")
	check(gc.state.unit_at(hex_at(1, 1)) == apc, "riders don't occupy the hex")
	check(gc.submit_move(apc, MoveOptions.key(hex_at(1, 2), 3), MoveMode.Kind.RUN), "APC drives")
	check_eq(inf.coord, hex_at(1, 2), "rider goes along")
	check(gc.deploy(inf), "gets out after the APC moved")
	check_eq(inf.asset.carried_by, -1, "on foot")
	check(not ToHitCalc.weapon(gc.state, inf, inf.weapons[0], e).possible(), "can't fire the turn it deploys")
	var th := ToHitCalc.weapon(gc.state, e, gun(e, "ppc"), inf)
	check(th.mods.all(func(m: Dictionary) -> bool: return m["label"] != "target TMM"), "TMM 0 that turn")


func test_capacity_and_battle_armor_cost() -> void:
	var apc := asset("test_apc", 0, hex_at(1, 1), 0, 1)
	var ba := asset("test_elementals", 0, hex_at(1, 1), 0, 2)
	var inf := asset("test_foot", 0, hex_at(1, 1), 0, 3)
	var gc := _gc([apc, ba, inf])
	check_eq(AssetTransport.board_problem(gc.state, ba, apc), "", "battle armor fits APC2")
	AssetTransport.board(gc.state, _emit, ba, apc)
	check(AssetTransport.board_problem(gc.state, inf, apc) != "", "battle armor took both points")


func test_destroyed_apc_kills_riders() -> void:
	var apc := asset("test_apc", 0, hex_at(1, 1), 0, 1)
	var inf := asset("test_foot", 0, hex_at(1, 1), 0, 2)
	var gc := _gc([apc, inf])
	AssetTransport.board(gc.state, _emit, inf, apc)
	Damage.destroy_unit(apc, "test")
	AssetTransport.check_losses(gc.state, _emit)
	check(inf.destroyed, "lost with its transport")


func test_mechanized_rides_omnimech() -> void:
	var omni := mech("timber_wolf_prime", 0, hex_at(1, 1), 0, 1)
	var ba := asset("test_elementals", 0, hex_at(1, 1), 0, 2)
	var gc := _gc([omni, ba])
	check_eq(AssetTransport.capacity(omni, ba), 2, "OmniMech counts as APC2")
	AssetTransport.board(gc.state, _emit, ba, omni)
	Damage.destroy_unit(omni, "test")
	AssetTransport.check_losses(gc.state, _emit)
	check(not ba.destroyed, "mechanized battle armor jumps clear")
	check_eq(ba.asset.carried_by, -1, "set down")
	var normal := mech("griffin_grf1n", 0, hex_at(2, 2), 0, 3)
	check_eq(AssetTransport.capacity(normal, ba), 0, "not on a standard 'Mech")


func test_swarm_adds_groupings() -> void:
	var inf := asset("test_foot", 0, hex_at(1, 1), 0, 1)
	var ba := asset("test_elementals", 0, hex_at(1, 1), 0, 2)
	var m := mech("griffin_grf1n", 1, hex_at(1, 1), 0, 3)
	var gc := _gc([inf, ba, m])
	check_eq(AssetSpecials.swarm_groupings(inf, m), 1, "conventional: +1")
	check_eq(AssetSpecials.swarm_groupings(ba, m), 2, "battle armor: +2")
	var decl := FireOptions.declare(gc.state, ba, [{"weapon": 0, "target_id": 3}, {"weapon": 1, "target_id": 3}])
	check_eq(decl.size(), 4, "two groupings plus two swarm groupings")
	var e_inf := asset("test_foot", 1, hex_at(1, 1), 0, 4)
	check_eq(AssetSpecials.swarm_groupings(inf, e_inf), 0, "conventional infantry can't swarm infantry")
	check_eq(AssetSpecials.swarm_groupings(ba, e_inf), 2, "battle armor can")
	var far := mech("griffin_grf1n", 1, hex_at(2, 1), 0, 5)
	check_eq(AssetSpecials.swarm_groupings(ba, far), 0, "only in its own hex")


func test_ams_special_cuts_cluster_roll() -> void:
	var m := mech("griffin_grf1n", 0, hex_at(0, 0), 3, 1)
	var apc := asset("test_apc", 1, hex_at(0, 2), 0, 2)
	var gc := _gc([m, apc])
	var w := gun(m, "lrm10")
	var th := ToHitCalc.weapon(gc.state, m, w, apc)
	var dice := LoadedDice.new()
	dice.queue_2d6(12)  # hit
	dice.queue_2d6(11)  # cluster roll, -4 = 7
	WeaponFire.resolve(gc.state, dice, _emit, m, w, apc, th)
	var shot: Dictionary = events.filter(func(e: Array) -> bool: return e[0] == GameEvent.WEAPON_FIRED)[0][1]
	check(shot.get("ams", false), "AMS engaged")
	check_eq(apc.asset.damage, 6, "LRM 10 on a 7: 6 missiles")
