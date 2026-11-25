extends TestCase
## Learning Special Pilot Abilities with Support Points, and the company's
## formation (Campaign Operations pp. 60-70, 163-164).

var db: UnitDb


func _company() -> Campaign:
	db = designs()
	var c := Campaign.create(CampaignRules.load_file(), ChaosRules.load_file())
	c.sp = 1000
	return c


func test_skill_rating_limits() -> void:
	var r := ChaosRules.load_file()
	var c := _company()
	var p := c.add_pilot("Test", 5, 6)
	check_eq(SpaShop.rating(p, r), "green")
	check(SpaShop.learn(c, p, Spa.SNIPER, r) != "", "Green: no abilities")
	p.gunnery = 4
	p.piloting = 5
	check_eq(SpaShop.rating(p, r), "regular")
	check(SpaShop.learn(c, p, Spa.SNIPER, r) != "", "Sniper is 3 points: too much for a Regular")
	check_eq(SpaShop.learn(c, p, Spa.JUMPING_JACK, r), "")
	check_eq(c.sp, 900, "100 SP")
	check(SpaShop.learn(c, p, Spa.HOT_DOG, r) != "", "a Regular gets one")
	p.gunnery = 3
	p.piloting = 4
	check(SpaShop.learn(c, p, Spa.HOT_DOG, r).contains("month"), "one every three months")
	c.month += 3
	check_eq(SpaShop.learn(c, p, Spa.HOT_DOG, r), "", "a Veteran gets two (2 + 2 points)")
	check(p.to_pilot().abilities.has(Spa.HOT_DOG), "the battle MechWarrior has it")


func test_offers_choices() -> void:
	var c := _company()
	var p := c.add_pilot("Test", 3, 4)
	var offers := SpaShop.offers(p, db.get_def("hunchback_hbk4g"))
	var entries := offers.map(func(o: Dictionary) -> String: return o["entry"])
	check(entries.has("weapon_specialist:ac20"), "the 'Mech's own weapons")
	check(entries.has("range_master:long") and entries.has("terrain_master:frogman"))
	p.abilities.append("terrain_master:frogman")
	entries = SpaShop.offers(p, null).map(func(o: Dictionary) -> String: return o["entry"])
	check(not entries.has("terrain_master:frogman") and entries.has("terrain_master:mountaineer"))
	check(p.to_pilot().abilities.has("terrain_master:frogman"))


func test_company_formation() -> void:
	var c := _company()
	var opts := CampaignFormation.options(c, db)
	check(not opts.is_empty(), "the starting lance fits a formation")
	CampaignFormation.cycle(c, db)
	check_eq(c.formation, opts[0])
	check_eq(Campaign.from_dict(c.to_dict()).formation, opts[0], "saved")
	for i in opts.size():
		CampaignFormation.cycle(c, db)
	check_eq(c.formation, "", "and back to none")
