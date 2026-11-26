extends TestCase
## Opening boards offer at least one affordable track without changing funds.


func test_seeded_opening_boards_and_support_conversion() -> void:
	var rules := ChaosRules.load_file()
	var rng := RandomNumberGenerator.new()
	for seed_value in 128:
		var company := Campaign.create(CampaignRules.load_file(), rules)
		check_eq(company.wp, 1000)
		check_eq(SupportShop.convert(company, rules, rules.sp("max_wp_per_month")), "")
		rng.seed = seed_value
		company.offers = ContractBoard.offer(rules, rng)
		ContractBoard.ensure_opening_choice(company, rules)
		check_eq(company.wp, 900, "Board never credits funds")
		check_eq(company.offers.size(), 3)
		var index := ContractBoard.affordable_index(company, rules)
		check(index >= 0, "At least one debt-free offer for seed %d" % seed_value)
		if index >= 0:
			Warchest.take(company, company.offers[index], rules)
			check(not company.on_debt and company.wp >= 0)


func test_affordable_board_is_preserved() -> void:
	var rules := ChaosRules.load_file()
	var company := Campaign.create(CampaignRules.load_file(), rules)
	var cheap := Contract.new()
	cheap.objectives.assign(["advance_attack", "bullet_time"])
	cheap.offered.assign(["bad_weather", "bad_intel"])
	company.offers.assign([_expensive(), cheap, _expensive()])
	check_eq(ContractBoard.ensure_opening_choice(company, rules), -1)
	check_eq(company.offers[1], cheap)
	check_eq(ContractBoard.affordable_index(company, rules), 1)


func _expensive() -> Contract:
	var k := Contract.new()
	k.mission_id = "focal_point"
	k.enemy_percent = 100
	k.objectives.assign(["bring_the_pain", "being_difficult", "annihilate"])
	k.offered.assign(["elites", "heavy_fog"])
	return k


func test_legacy_opening_board_recovers_without_granting_money() -> void:
	var rules := ChaosRules.load_file()
	var company := Campaign.create(CampaignRules.load_file(), rules)
	company.wp = 1000
	company.offers.assign([_expensive(), _expensive(), _expensive()])
	check_eq(ContractBoard.affordable_index(company, rules), -1)
	var index := ContractBoard.ensure_opening_choice(company, rules)
	check(index >= 0)
	if index < 0:
		return
	check_eq(company.wp, 1000)
	check_eq(company.offers.size(), 3)
	var k := company.offers[index]
	check(k.cost(rules) <= company.wp)
	check_eq(k.objectives.size(), 2)
	check_eq(k.offered.size(), 2)
	check_eq(ContractBoard.ensure_opening_choice(company, rules), -1)
	Warchest.take(company, k, rules)
	check(not company.on_debt and company.wp >= 0)


func test_later_contracts_and_voluntary_overspending_unchanged() -> void:
	var rules := ChaosRules.load_file()
	var company := Campaign.create(CampaignRules.load_file(), rules)
	company.wp = 100
	company.offers.assign([_expensive()])
	check_eq(ContractBoard.ensure_opening_choice(company, rules), -1, "No free funds if player spends their budget")
	company.wp = 1000
	company.battles = 1
	check_eq(ContractBoard.ensure_opening_choice(company, rules), -1)
	check_eq(Warchest.cant_take(company, company.offers[0], rules), "")
	Warchest.take(company, company.offers[0], rules)
	check(company.on_debt)
