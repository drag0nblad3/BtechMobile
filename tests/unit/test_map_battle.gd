extends TestCase
## Map campaign battles: building a meeting's battle and writing it back.


func _meeting() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var mc := MapCampaign.create(designs(), rng)
	var mine := mc.lances_of(0)[0]
	var foe := mc.lances_of(1)[1]
	mine.zone = foe.zone
	MapOrders.give(mc, mine, MapLance.ATTACK)
	var battles := MapTurn.start(mc, LoadedDice.new())
	return [mc, battles[0], mine, foe]


func test_build_and_write_back() -> void:
	var m := _meeting()
	var mc: MapCampaign = m[0]
	var b: Dictionary = m[1]
	var built := MapBattle.build(mc, b, designs(), 5)
	check(not built.is_empty(), "a battle")
	var state: GameState = built["state"]
	check_eq(state.units_of_side(0).size() + state.units_of_side(1).size() + state.hidden.size(), 8, "two lances")
	check_eq(int(state.initiative_bonus[1]) >= 1, true, "the garrison defends: +1 Initiative")
	check_eq(int(state.initiative_bonus[0]), 0)
	for u in state.all_units():
		if u.side == 1:
			Damage.destroy_unit(u, "engine destroyed")
	var report := MapBattle.finish(mc, b, state, built["rosters"], 0)
	check(report[0].contains("won"), report[0])
	check(mc.battles.is_empty(), "fought")
	var foe: MapLance = m[3]
	check(mc.fit_mechs(foe).is_empty(), "the defenders are down")
	MapTurn.finish(mc, designs())
	var loc := mc.region.location_at(foe.zone)
	check_eq(int(loc["owner"]), 0, "the location falls")


func test_battlefield_follows_terrain() -> void:
	var m := _meeting()
	var mc: MapCampaign = m[0]
	var z := Vector2i(0, 5)
	mc.region.terrain[z.y * mc.region.width + z.x] = "woods"
	var map := MapBattle.battlefield(mc, z, 3)
	var woods := 0
	for c in map.tiles:
		if map.tiles[c].terrain.id.ends_with("woods"):
			woods += 1
	check(woods > 10, "a woodland battlefield: %d woods hexes" % woods)


## A day's two distinct meetings must settle individually and advance once.
func test_store_waits_for_final_meeting() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var mc := MapCampaign.create(designs(), rng)
	var players := mc.lances_of(0)
	var foes := mc.lances_of(1)
	for i in 2:
		players[i].zone = foes[i].zone
		MapOrders.give(mc, players[i], MapLance.ATTACK)
	MapTurn.start(mc, LoadedDice.new())
	check_eq(mc.battles.size(), 2, "two controlled meetings")
	if mc.battles.size() != 2:
		return
	var path := "user://test_map_campaign_two_meetings.json"
	MapCampaignStore.delete(path)
	for i in 2:
		var meeting := mc.battles[0]
		var built := MapBattle.build(mc, meeting, designs(), 20 + i)
		check(not built.is_empty(), "meeting %d builds" % i)
		if built.is_empty():
			MapCampaignStore.delete(path)
			return
		var state: GameState = built["state"]
		for u in state.all_units():
			if u.side == 1:
				Damage.destroy_unit(u, "engine destroyed")
		check(MapCampaignStore.save(mc, {"index": 0, "rosters": built["rosters"]}, path))
		check(not MapCampaignStore.finish(state, 0, [], path).is_empty(), "meeting writes back")
		check(MapCampaignStore.pending(path).is_empty(), "pending battle cleared")
		mc = MapCampaignStore.load_campaign(path)
		check(mc != null, "campaign reloads")
		if mc == null:
			MapCampaignStore.delete(path)
			return
		check_eq(mc.battles.size(), 1 - i, "only the completed meeting is removed")
		check_eq(mc.turn, 1 if i == 0 else 2, "advance only after final meeting")
		check_eq(MapCampaignStore.finish(state, 0, [], path), "", "duplicate finish is harmless")
		if mc.battles.size() != 1 - i:
			break
	MapCampaignStore.delete(path)
