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
