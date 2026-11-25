extends TestCase
## Map campaign movement: lances that cross paths meet, and DropShip Moves
## (Campaign Operations p. 148).


func _campaign() -> MapCampaign:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mc := MapCampaign.create(designs(), rng)
	for l in mc.lances_of(1):  # clear the board: one enemy lance in play
		l.zone = Vector2i(0, 0)
	return mc


func test_swapping_lances_meet() -> void:
	var mc := _campaign()
	var mine := mc.lances_of(0)[0]
	var foe := mc.lances_of(1)[0]
	mine.zone = Vector2i(3, 3)
	foe.zone = mc.region.neighbors(mine.zone)[0]
	var foe_from := foe.zone
	MapOrders.give(mc, mine, MapLance.MOVE, foe.zone)
	MapOrders.give(mc, foe, MapLance.MOVE, mine.zone)
	MapTurn.start(mc, LoadedDice.new())
	check_eq(mine.zone, foe_from, "they meet where the defender stood")
	check_eq(foe.zone, foe_from)
	check(mc.battles.any(func(b: Dictionary) -> bool: return b["zone"] == foe_from), "and fight")


func test_fast_move_stops_at_an_enemy() -> void:
	var mc := _campaign()
	var mine := mc.lances_of(0)[0]
	var foe := mc.lances_of(1)[0]
	mine.zone = Vector2i(3, 5)
	var far := Vector2i(3, 3)
	foe.zone = mc.region.step_toward(mine.zone, far)
	MapOrders.give(mc, mine, MapLance.FAST_MOVE, far)
	MapTurn.start(mc, LoadedDice.new())
	check_eq(mine.zone, foe.zone, "stopped in the enemy's zone")
	check_eq(mc.battles.size(), 1)


func test_dropship_takes_two_days() -> void:
	var mc := _campaign()
	var l := mc.lances_of(0)[0]
	var target := Vector2i(1, 2)
	check(MapOrders.why_not(mc, mc.lances_of(1)[0], MapLance.DROPSHIP, target) != "", "the defender has none")
	check_eq(MapOrders.give(mc, l, MapLance.DROPSHIP, target), "")
	MapTurn.start(mc, LoadedDice.new())
	check(not l.on_map(), "in the air")
	MapTurn.finish(mc, designs())
	check_eq(l.order, MapLance.DROPSHIP, "keeps flying")
	check(MapOrders.give(mc, l, MapLance.MOVE, Vector2i(1, 1)) != "", "no new orders in the air")
	var again := MapCampaignCodec.unpack(JSON.parse_string(JSON.stringify(MapCampaignCodec.pack(mc))))
	check_eq(again.lance(l.id).transit, 1, "saved in the air")
	MapTurn.start(mc, LoadedDice.new())
	check_eq(l.zone, target, "lands on the second day")
	l.zone = Vector2i(1, 2)
	check(MapDrop.why_not(mc, l) != "", "loads only at the landing zone or a DropPort")


func test_dropport_flight_takes_one_day() -> void:
	var mc := _campaign()
	var l := mc.lances_of(0)[0]
	var port: Dictionary = mc.region.locations.filter(func(x: Dictionary) -> bool: return x["benefit"] == "dropport")[0]
	port["owner"] = 0
	MapOrders.give(mc, l, MapLance.DROPSHIP, port["zone"])
	MapTurn.start(mc, LoadedDice.new())
	check_eq(l.zone, port["zone"], "to a held DropPort in one day")
