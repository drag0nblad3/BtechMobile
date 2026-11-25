extends TestCase
## Regional geography and GM campaign options.


func _campaign() -> MapCampaign:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	return MapCampaign.create(designs(), rng)


func test_geo_and_seed() -> void:
	var mc := _campaign()
	var r := mc.region
	var start := Vector2i(0, 0)
	var end := Vector2i(r.width - 1, r.height - 1)
	var route := MapGeography.route(r, start, end)
	check_eq(route.size(), r.distance(start, end) + 1)
	for i in range(1, route.size()):
		check_eq(r.distance(route[i - 1], route[i]), 1)
	var seed := MapGeography.battle_seed(r, start)
	r.locations[0]["owner"] = 0
	check_eq(MapGeography.battle_seed(r, start), seed)
	var saved := MapCampaignCodec.unpack(JSON.parse_string(JSON.stringify(MapCampaignCodec.pack(mc))))
	check_eq(MapGeography.battle_seed(saved.region, start), seed)


func test_reassignment() -> void:
	var mc := _campaign()
	var a := mc.lances_of(0)[0]
	var b := mc.lances_of(0)[1]
	var aid := a.mech_ids[0]
	var bid := b.mech_ids[0]
	var am := mc.player.mech(aid)
	var bm := mc.player.mech(bid)
	var old := am.pilot_id
	check(MapOperations.swap_pilots(mc, am, bm))
	check_eq(bm.pilot_id, old)
	check(MapOperations.swap_mechs(mc, a, aid, b, bid))
	check(a.mech_ids.has(bid) and b.mech_ids.has(aid))
	b.zone = mc.region.neighbors(a.zone)[0]
	check(not MapOperations.swap_mechs(mc, a, bid, b, aid))


func test_intel_and_linked_region() -> void:
	var mc := _campaign()
	var z := mc.lances_of(0)[0].zone
	check(mc.intel.has(MapOperations.key(z)))
	var m := mc.player.mechs[0]
	m.condition = {"armor": [0]}
	var old := mc.player
	mc.winner = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 72
	check(MapOperations.next_region(mc, designs(), rng))
	check_eq(mc.operation, 2)
	check(mc.player == old and m.damaged())
	check_eq(mc.winner, -1)
	var saved := MapCampaignCodec.unpack(JSON.parse_string(JSON.stringify(MapCampaignCodec.pack(mc))))
	check_eq(saved.operation, 2)
	check_eq(saved.rules["width"], mc.rules["width"])
