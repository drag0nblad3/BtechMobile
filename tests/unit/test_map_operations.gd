extends TestCase
## Retained regression coverage from the alternate campaign command branch.


func test_archive_and_geography() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var mc := MapCampaign.create(designs(), rng)
	var z := mc.lances_of(0)[0].zone
	var route := MapGeography.route(mc.region, Vector2i.ZERO, z)
	check_eq(route.size(), mc.region.distance(Vector2i.ZERO, z) + 1)
	var seed := MapGeography.battle_seed(mc.region, z)
	mc.region.locations[0]["owner"] = 0
	check_eq(MapGeography.battle_seed(mc.region, z), seed)
	var lines: Array[String] = ["Victory", "Armor damage"]
	MapCampaignHistory.record(mc, z, 0, lines)
	var saved := MapCampaignCodec.unpack(JSON.parse_string(JSON.stringify(MapCampaignCodec.pack(mc))))
	check_eq(MapGeography.battle_seed(saved.region, z), seed)
	check_eq(saved.reports.size(), 1)
	check_eq(saved.reports[0]["lines"], Array(lines))


func test_advance_retains_lance_identity() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 72
	var mc := MapCampaign.create(designs(), rng)
	mc.rules["operations"] = 2
	var alpha := mc.lances_of(0)[0]
	var bravo := mc.lances_of(0)[1]
	var m := alpha.mech_ids[0]
	var n := bravo.mech_ids[0]
	check(MapHeadquarters.swap_mechs(mc, alpha, bravo, m, n))
	var before := alpha.mech_ids.duplicate()
	mc.winner = 0
	check(MapOperations.advance(mc, designs(), rng))
	check_eq(mc.lance(alpha.id).mech_ids, before, "regional deployment preserves formation")
	check(mc.intel.has(MapIntelligence.key(alpha.zone)), "landing observation refreshed")
