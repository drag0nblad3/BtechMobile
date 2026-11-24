extends TestCase
## Salvage (Campaign Operations p. 173) and buying and selling 'Mechs for
## Support Points (p. 163).


func _battle() -> GameState:
	var fb := ForceBuilder.new(designs(), 20000)
	for id in ["wolverine_wvr6r", "griffin_grf1n"]:
		fb.add(0, id)
	for id in ["commando_com2d", "wasp_wsp1a", "atlas_as7d"]:
		fb.add(1, id)
	return fb.build(make_map(["c0 c0 c0 c0", "c0 c0 c0 c0", "c0 c0 c0 c0", "c0 c0 c0 c0"]))


func test_salvage_needs_an_objective() -> void:
	var s := _battle()
	var enemy := s.units_of_side(1)
	Damage.destroy_unit(enemy[0], "engine destroyed")
	Damage.destroy_location(enemy[1], Location.CT)
	s.mission.crippled[enemy[2].id] = "test"
	var found := Salvage.wrecks(s, 0)
	check_eq(found.size(), 2, "a blown-out center torso is beyond salvage")
	var c := Campaign.create(CampaignRules.load_file(), ChaosRules.load_file())
	var before := c.mechs.size()
	c.last_met = 0
	check_eq(Salvage.claim(c, s, 0).size(), 1, "one line saying why not")
	check_eq(c.mechs.size(), before)
	c.last_met = 1
	Salvage.claim(c, s, 0)
	check_eq(c.mechs.size(), before + 2)
	var m := c.mechs[-2]
	check(m.salvage and m.pilot_id == "" and not m.can_deploy(), "no MechWarrior yet")
	check(bool(m.condition.get("destroyed", false)), "knocked out until its structure is fixed")


func test_prices() -> void:
	var r := ChaosRules.load_file()
	var db := designs()
	check_eq(MechMarket.price(db.get_def("atlas_as7d"), r), 1000, "100 t x 10, Introductory")
	check_eq(MechMarket.price(db.get_def("akuma_aku1x"), r), db.get_def("akuma_aku1x").tonnage * 20, "Standard")
	check_eq(MechMarket.price(db.get_def("archer_c_2"), r), 70 * 20 * 2, "Clan double")
	var m := CampaignMech.new()
	check_eq(MechMarket.sell_price(db.get_def("atlas_as7d"), m, r), 500, "half price")
	m.written_off = true
	check_eq(MechMarket.sell_price(db.get_def("atlas_as7d"), m, r), 0)


func test_buy_and_sell() -> void:
	var r := ChaosRules.load_file()
	var db := designs()
	var c := Campaign.create(CampaignRules.load_file(), r)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	MechMarket.stock(c, db, r, rng)
	check(c.market.size() > 0 and c.market.size() <= 4)
	var id := c.market[0]
	var cost := MechMarket.price(db.get_def(id), r)
	c.sp = cost - 1
	check(MechMarket.buy(c, id, db, r) != "", "short of SP")
	c.sp = cost
	check_eq(MechMarket.buy(c, id, db, r), "")
	check_eq(c.sp, 0)
	check(not c.market.has(id), "sold out")
	var bought := c.mechs[-1]
	check_eq(bought.design, id)
	var first := c.mechs[0]
	var pilot := first.pilot_id
	check_eq(MechMarket.sell(c, first, db, r), "")
	check_eq(c.sp, MechMarket.sell_price(db.get_def(first.design), first, r))
	check(c.free_pilots().has(c.pilot(pilot)), "its MechWarrior is free")
	check_eq(SupportShop.assign(c, bought, c.pilot(pilot), db.get_def(id)), "")
	SupportShop.new_month(c)
	check(c.market.is_empty(), "a new month, new stock")
