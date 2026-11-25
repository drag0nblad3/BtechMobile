extends TestCase
## Map campaign: fog of war and scouting, the Factory and Seaports, and the
## defender reinforcing a threatened location.


func _campaign(seed_n := 7) -> MapCampaign:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	return MapCampaign.create(designs(), rng)


func _loc(mc: MapCampaign, benefit: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for loc in mc.region.locations:
		if loc["benefit"] == benefit:
			out.append(loc)
	return out


func test_fog_and_scouting() -> void:
	var mc := _campaign()
	var mine := mc.lances_of(0)[0]
	for l in mc.lances_of(0):
		l.zone = mine.zone
	var foe := mc.lances_of(1)[0]
	for x in mc.region.width:
		for y in mc.region.height:
			if mc.region.distance(mine.zone, Vector2i(x, y)) == 2:
				foe.zone = Vector2i(x, y)
	check(not MapFog.shows(mc, foe), "two zones off: unseen")
	check(MapFog.shows(mc, mine), "your own lances")
	mine.order = MapLance.SCOUT
	MapFog.scout(mc)
	check(MapFog.shows(mc, foe), "a Scout sees two zones out")
	var again := MapCampaignCodec.unpack(JSON.parse_string(JSON.stringify(MapCampaignCodec.pack(mc))))
	check_eq(again.scouted.size(), mc.scouted.size(), "saved")


func test_factory_builds_once() -> void:
	var mc := _campaign()
	var factory := _loc(mc, "factory")[0]
	var before := mc.player.mechs.size()
	check(MapFactory.produce(mc, designs()).is_empty(), "the defender's factory")
	factory["owner"] = 0
	check_eq(MapFactory.produce(mc, designs()).size(), 1)
	check_eq(mc.player.mechs.size(), before + 1, "a free 'Mech")
	var lance := mc.lances_of(0).back() as MapLance
	check_eq(lance.zone, factory["zone"], "a new lance at the factory")
	check(MapFactory.produce(mc, designs()).is_empty(), "once per campaign")


func test_seaports_carry_a_lance() -> void:
	var mc := _campaign()
	var ports := _loc(mc, "seaport")
	check_eq(ports.size(), 2)
	for p in ports:
		check(mc.lances.filter(func(l: MapLance) -> bool: return l.zone == p["zone"]).is_empty(), "no garrison")
	var mine := mc.lances_of(0)[0]
	mine.zone = ports[0]["zone"]
	check(MapOrders.give(mc, mine, MapLance.MOVE, ports[1]["zone"]) != "", "the other port isn't yours")
	for p in ports:
		p["owner"] = 0
	check_eq(MapOrders.give(mc, mine, MapLance.MOVE, ports[1]["zone"]), "", "both held: sail")
	MapTurn.start(mc, LoadedDice.new())
	check_eq(mine.zone, ports[1]["zone"], "across in one turn")


func test_bot_reinforces() -> void:
	var mc := _campaign()
	var reserve: MapLance = mc.lances_of(1).back()
	var target: Dictionary = {}
	for loc in mc.region.locations:
		var d := mc.region.distance(reserve.zone, loc["zone"])
		if d >= 2 and d <= 3 and loc.get("benefit") != "seaport":
			target = loc
	check(not target.is_empty(), "a location in reach")
	var near := mc.region.neighbors(target["zone"])
	mc.lances_of(0)[0].zone = near[0]
	mc.lances_of(0)[1].zone = near[1]
	var before := mc.region.distance(reserve.zone, target["zone"])
	MapBot.orders(mc)
	check(mc.region.distance(reserve.target, target["zone"]) < before, "heads for the threatened place")
