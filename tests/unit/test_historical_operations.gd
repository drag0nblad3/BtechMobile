extends TestCase
## Data-driven starting forces, save persistence and unscripted outcomes.

func test_operations_have_real_designs_and_persist() -> void:
	var db := designs()
	check_eq(HistoricalOperations.all().size(), 3)
	for op: Dictionary in HistoricalOperations.all():
		check_eq(HistoricalOperations.problem(op, db), "", op["id"])
		var mc := HistoricalOperations.create(op, db)
		if mc == null:
			continue
		check_eq(mc.lances_of(0).size(), 3)
		check_eq(mc.lances_of(1).size(), 3)
		check_eq(mc.player.mechs.size(), 12)
		check_eq(mc.enemy.mechs.size(), 12)
		check_eq(mc.winner, -1)
		var restored := MapCampaignCodec.unpack(MapCampaignCodec.pack(mc))
		check_eq(restored.player.pilots[0].name, mc.player.pilots[0].name)
		check_eq(restored.region.geography_seed, mc.region.geography_seed)
		check_eq(restored.rules["historical_operation"]["id"], op["id"])
		for loc in restored.region.locations:
			loc["owner"] = 0
		check_eq(MapTurn.winner(restored), 0, "alternate victory remains possible")
		for loc in restored.region.locations:
			loc["owner"] = 1
		restored.turn = int(restored.rules["turn_limit"])
		check_eq(MapTurn.winner(restored), 1, "defeat remains possible")


func test_substitutions_not_hidden() -> void:
	var op := HistoricalOperations.find("benet")
	check_eq(HistoricalOperations.substitutions(op).size(), 7)
	check(HistoricalOperations.substitutions(HistoricalOperations.find("misery")).size() == 1)
