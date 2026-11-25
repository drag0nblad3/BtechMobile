extends TestCase
## Map-based campaign (Campaign Operations pp. 142-155): the region, orders,
## the Scenario Type table, captures, repairs and winning.


func _campaign(seed_n := 7) -> MapCampaign:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	return MapCampaign.create(designs(), rng)


func test_setup() -> void:
	var mc := _campaign()
	check_eq(mc.region.terrain.size(), 48)
	check_eq(mc.region.locations.size(), 12)
	check_eq(mc.region.total_points(), 25)
	check_eq(mc.region.points(1), 25, "the defender holds everything")
	check_eq(mc.lances_of(0).size(), 3, "a company of three lances")
	check_eq(mc.lances_of(1).size(), 11, "a lance per garrisoned location plus a reserve")
	for loc in mc.region.locations:
		check(loc["zone"].y < mc.region.height - 1, "nothing on the landing row")
	var again := MapCampaignCodec.unpack(JSON.parse_string(JSON.stringify(MapCampaignCodec.pack(mc))))
	check_eq(again.region.locations[0]["zone"], mc.region.locations[0]["zone"], "saved")
	check_eq(again.lances.size(), 14)
	check_eq(again.fit_mechs(again.lances[0]).size(), 4)


func test_orders() -> void:
	var mc := _campaign()
	var l := mc.lances_of(0)[0]
	var far := l.zone + Vector2i(0, -3)
	check(MapOrders.give(mc, l, MapLance.MOVE, far) != "", "Move goes one zone")
	check(MapOrders.give(mc, l, MapLance.FAST_MOVE, l.zone + Vector2i(0, -2)) == "", "Fast Move two")
	var from := l.zone
	MapTurn.start(mc, LoadedDice.new())
	check_eq(mc.region.distance(from, l.zone), 2, "moved two zones")
	MapTurn.finish(mc, designs())
	check(l.fast_moved)
	check(MapOrders.give(mc, l, MapLance.MOVE, mc.region.neighbors(l.zone)[0]) != "", "no Move after a Fast Move")


func test_scenario_table() -> void:
	var a := MapLance.new()
	var b := MapLance.new()
	var rules := MapCampaign.load_rules()
	a.order = MapLance.ATTACK
	b.order = MapLance.MOVE
	var s := ScenarioTable.roll(a, b, LoadedDice.new([5]), rules)
	check_eq(int(s["mod"]), 3, "Attack against a move: +3")
	check_eq(s["scenario"], "breakthrough", "5 + 3 = 8")
	check(ScenarioTable.attacker(a, b, LoadedDice.new()) == a)
	b.order = MapLance.SCOUT
	s = ScenarioTable.roll(a, b, LoadedDice.new([2]), rules)
	check_eq(s["column"], "scout")
	check_eq(s["scenario"], "breakthrough", "2 - 3 is 1 at least")
	a.order = MapLance.SCOUT
	b.order = MapLance.DEFEND
	check(ScenarioTable.attacker(a, b, LoadedDice.new()) == a, "scouting into a defender")


func test_meeting_capture_and_repair() -> void:
	var mc := _campaign()
	var mine := mc.lances_of(0)[0]
	var loc: Dictionary = mc.region.locations[1]
	mine.zone = mc.region.step_toward(loc["zone"], Vector2i(0, mc.region.height - 1))
	var foe: MapLance = null
	for l in mc.lances_of(1):
		if l.zone == loc["zone"]:
			foe = l
	MapOrders.give(mc, mine, MapLance.ATTACK, loc["zone"])
	var battles := MapTurn.start(mc, LoadedDice.new())
	check_eq(battles.size(), 1, "one battle")
	check_eq(battles[0]["attacker"], mine.id)
	for id in foe.mech_ids:  # the defenders are wiped out
		mc.enemy.mech(id).written_off = true
	var hurt := mc.player.mech(mine.mech_ids[0])
	hurt.condition = {"armor": [0]}
	mc.battles.clear()
	MapTurn.finish(mc, designs())
	check_eq(int(loc["owner"]), 0, "the location changes hands")
	check(mc.lance(foe.id) == null, "a wiped-out lance leaves the map")
	if loc["benefit"] == "repair" or loc["benefit"] == "fortress":
		check(hurt.condition.is_empty(), "free repair")
	MapOrders.give(mc, mine, MapLance.REPAIR)
	mc.player.pilot(hurt.pilot_id).dead = true
	MapTurn.start(mc, LoadedDice.new())
	check(mc.player.pilot(hurt.pilot_id).can_fight(), "a Green recruit takes the seat")


func test_bot_and_winning() -> void:
	var mc := _campaign()
	MapBot.orders(mc)
	var defenders := mc.lances_of(1).filter(func(l: MapLance) -> bool: return l.order == MapLance.DEFEND)
	check_eq(defenders.size(), 10, "garrisons hold")
	check_eq(MapTurn.winner(mc), -1)
	for loc in mc.region.locations:
		loc["owner"] = 0
	check_eq(MapTurn.winner(mc), 0, "80% of the points")
	for loc in mc.region.locations:
		loc["owner"] = 1
	mc.turn = 20
	check_eq(MapTurn.winner(mc), 1, "the defender outlasts the turn limit")

func test_persistent_geography() -> void:
	var mc := _campaign()
	var z := Vector2i(2, 2)
	var seed_value := MapGeography.battle_seed(mc.region, z)
	var again := MapCampaignCodec.unpack(JSON.parse_string(JSON.stringify(MapCampaignCodec.pack(mc))))
	check_eq(MapGeography.battle_seed(again.region, z), seed_value)
	check_eq(again.region.terrain, mc.region.terrain)
	for route in MapGeography.roads(mc.region):
		for i in range(1, route.size()):
			check_eq(mc.region.distance(route[i - 1], route[i]), 1, "connected road")
	var a := MapBattle.battlefield(mc, z, 1)
	var b := MapBattle.battlefield(mc, z, 99)
	check_eq(a.width, b.width)
	for c: Vector2i in a.coords():
		check_eq(a.get_tile(c).terrain.id, b.get_tile(c).terrain.id)
		check_eq(a.get_tile(c).level, b.get_tile(c).level)

func test_hq_transfers_and_restrictions() -> void:
	var mc := _campaign()
	var a := mc.lances_of(0)[0]
	var b := mc.lances_of(0)[1]
	var m := a.mech_ids[0]
	var n := b.mech_ids[0]
	var pilot_m := mc.player.mech(m).pilot_id
	var pilot_n := mc.player.mech(n).pilot_id
	check(MapHeadquarters.swap_pilots(mc, a, b, m, n))
	check_eq(mc.player.mech(m).pilot_id, pilot_n)
	check_eq(mc.player.mech(n).pilot_id, pilot_m)
	check(MapHeadquarters.swap_mechs(mc, a, b, m, n))
	check(a.mech_ids.has(n) and b.mech_ids.has(m))
	b.zone = mc.region.neighbors(a.zone)[0]
	check(not MapHeadquarters.swap_mechs(mc, a, b, n, m), "remote transfer rejected")
	b.zone = a.zone
	b.order = MapLance.MOVE
	check(not MapHeadquarters.swap_pilots(mc, a, b, n, m), "orders already issued")


func test_stale_intelligence() -> void:
	var mc := _campaign()
	var p := mc.lances_of(0)[0]
	var enemy := mc.lances_of(1)[0]
	enemy.zone = p.zone
	MapIntelligence.observe(mc)
	var z := p.zone
	var key := MapIntelligence.key(z)
	var observed: Dictionary = mc.intel[key].duplicate()
	for l in mc.lances_of(0):
		l.zone = Vector2i(0, 0)
	enemy.zone = Vector2i(1, 0)
	MapIntelligence.observe(mc)
	check_eq(mc.intel[key], observed, "unseen report does not leak updated enemy position")
	check(MapIntelligence.report(mc, z).begins_with("Last known"))
	var restored := MapCampaignCodec.unpack(JSON.parse_string(JSON.stringify(MapCampaignCodec.pack(mc))))
	check_eq(int(restored.intel[key]["lances"]), int(observed["lances"]))


func test_linked_region_retains_company() -> void:
	var mc := _campaign()
	mc.rules["operations"] = 2
	mc.rules["width"] = 10
	mc.rules["height"] = 8
	var m := mc.player.mech(mc.lances_of(0)[0].mech_ids[0])
	var pilot := mc.player.pilot(m.pilot_id)
	m.condition = {"armor": [0]}
	pilot.wounds = 1
	pilot.kills = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = 543
	check(not MapOperations.advance(mc, designs(), rng), "requires victory")
	mc.winner = 0
	check(MapOperations.advance(mc, designs(), rng))
	check_eq(mc.operation, 2)
	check_eq(mc.region.width, 10)
	check_eq(mc.turn, 1)
	check_eq(mc.winner, -1)
	check_eq(mc.player.mech(m.id).condition, {"armor": [0]})
	check_eq(mc.player.pilot(pilot.id).wounds, 1)
	check_eq(mc.player.pilot(pilot.id).kills, 3)
	check(not MapOperations.advance(mc, designs(), rng), "no extra regions")
	var restored := MapCampaignCodec.unpack(JSON.parse_string(JSON.stringify(MapCampaignCodec.pack(mc))))
	check_eq(restored.operation, 2)
	check_eq(int(restored.rules["width"]), 10)

func test_historical_pool_only_verified() -> void:
	var db := designs()
	var availability := EraAvailability.new()
	var pool := MapCampaignOptions.pool(db, 3025, "federated_suns")
	for def: UnitDef in pool:
		check_eq(availability.check(def.id, 3025, "federated_suns")["status"], "available")
	check(MapCampaignOptions.pool(db, 3025, "invalid_faction").is_empty())
