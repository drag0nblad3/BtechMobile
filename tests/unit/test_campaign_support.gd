extends TestCase
## Optional Support Points (Campaign Operations pp. 161-164): converting
## WP, repairs, rearming, healing, training and hiring between contracts.


func _company() -> Campaign:
	var c := Campaign.create(CampaignRules.load_file(), ChaosRules.load_file())
	c.wp = 500
	return c


func test_conversion_is_capped_per_month() -> void:
	var r := ChaosRules.load_file()
	var c := _company()
	check_eq(c.size_mod, 1, "one lance")
	check_eq(SupportShop.convert(c, r, 300), "")
	check_eq(c.sp, 100, "100 WP x 1 lance x D rating 1.0")
	check_eq(c.wp, 400)
	check(SupportShop.convert(c, r, 10) != "", "the month's 100 WP is used up")
	SupportShop.new_month(c)
	check_eq(SupportShop.convert(c, r, 50), "")
	check_eq(c.sp, 150)


func test_intro_tech() -> void:
	var r := ChaosRules.load_file()
	var db := designs()
	check(IntroTech.is_intro(db.get_def("atlas_as7d"), r), "AS7-D is Introductory")
	check(not IntroTech.is_intro(db.get_def("akuma_aku1x"), r), "Standard Rules gear")
	check(not IntroTech.is_intro(db.get_def("archer_c_2"), r), "Clan")
	check_eq(MechRepair.cost(db.get_def("atlas_as7d"), MechRepair.AMMO, r), 5)
	check_eq(MechRepair.cost(db.get_def("archer_c_2"), MechRepair.AMMO, r), 20, "Standard x2 for Clan")
	check_eq(MechRepair.cost(db.get_def("archer_c_2"), MechRepair.ARMOR, r), 140, "70 t x2 for Clan")


func test_repairs_restore_the_record_sheet() -> void:
	var r := ChaosRules.load_file()
	var db := designs()
	var c := _company()
	var m := c.mechs[0]
	var def := db.get_def(m.design)
	var u := m.to_unit(db, 1, 0, Pilot.new(4, 5))
	Damage.apply(u, Location.LT, 40)
	u.ammo[0].shots -= 2
	m.condition = MechCondition.lasting(u)
	for job in MechRepair.JOBS:
		check(MechRepair.needs(m, def, job), job)
	c.sp = 1000
	check_eq(SupportShop.repair(c, m, def, MechRepair.ARMOR, r), "")
	check_eq(c.sp, 1000 - def.tonnage)
	check(not MechRepair.needs(m, def, MechRepair.ARMOR) and MechRepair.needs(m, def, MechRepair.STRUCTURE), "armor only")
	check_eq(SupportShop.repair(c, m, def, MechRepair.STRUCTURE, r), "")
	check_eq(SupportShop.repair(c, m, def, MechRepair.AMMO, r), "")
	check(m.condition.is_empty(), "as good as new")
	check(SupportShop.repair(c, m, def, MechRepair.ARMOR, r) != "", "nothing left to fix")


func test_no_spending_in_debt_or_short() -> void:
	var r := ChaosRules.load_file()
	var c := _company()
	c.pilots[0].wounds = 2
	c.sp = 10
	check(SupportShop.heal(c, c.pilots[0], r) != "", "30 SP a wound")
	c.sp = 100
	c.wp = -50
	check(SupportShop.heal(c, c.pilots[0], r) != "", "in Warchest debt")
	c.wp = 0
	check_eq(SupportShop.heal(c, c.pilots[0], r), "")
	check(SupportShop.heal(c, c.pilots[0], r) != "", "one wound a month")
	check_eq(c.pilots[0].wounds, 1)


func test_training_costs_triple_when_idle() -> void:
	var r := ChaosRules.load_file()
	var c := _company()
	var p := c.pilots[0]
	c.sp = 2000
	p.fought_last = true
	check_eq(SupportShop.train_cost(p, "gunnery", r), 200)
	check_eq(SupportShop.train(c, p, "gunnery", r), "")
	check_eq(p.gunnery, 3)
	check(SupportShop.train(c, p, "gunnery", r) != "", "one point per break")
	p.fought_last = false
	check_eq(SupportShop.train_cost(p, "piloting", r), 450)
	check_eq(SupportShop.train(c, p, "piloting", r), "")
	check_eq(c.sp, 2000 - 200 - 450)


func test_hire_and_seat_a_new_mechwarrior() -> void:
	var r := ChaosRules.load_file()
	var db := designs()
	var c := _company()
	var m := c.mechs[0]
	c.pilot(m.pilot_id).dead = true
	m.condition = {"destroyed": true, "destroyed_reason": "MechWarrior killed"}
	check(not m.can_deploy(), "no pilot")
	c.sp = 300
	check_eq(SupportShop.hire_cost("veteran", r), 300)
	check_eq(SupportShop.hire(c, "regular", r), "")
	check_eq(c.sp, 100)
	var p := c.free_pilots()[0]
	check_eq(Vector2i(p.gunnery, p.piloting), Vector2i(4, 5), "Regular")
	check_eq(SupportShop.assign(c, m, p, db.get_def(m.design)), "")
	check(m.can_deploy() and c.ready_mechs().has(m), "back in action")
	check(c.free_pilots().is_empty())


func test_support_fields_survive_save() -> void:
	var c := _company()
	c.sp = 77
	c.month = 4
	c.converted = 60
	c.done.append("heal:p1")
	var back := Campaign.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())))
	check_eq([back.sp, back.month, back.converted, back.size_mod], [77, 4, 60, 1])
	check(back.done.has("heal:p1"))
