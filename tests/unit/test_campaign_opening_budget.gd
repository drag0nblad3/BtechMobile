extends TestCase
## Opening funds are a GM choice, not a change to Chaos Campaign debt rules.


func test_maximum_possible_opening_track_and_support_reserve() -> void:
	var rules := ChaosRules.load_file()
	var company := Campaign.create(CampaignRules.load_file(), rules)
	var max_track := 0
	# Enumerate every legal 2/3 objective and two-option combination.
	for attack: Dictionary in rules.objectives():
		if attack["check"] not in ContractBoard.ENEMY_CHECKS:
			continue
		for keep: Dictionary in rules.objectives():
			if keep["check"] in ContractBoard.ENEMY_CHECKS:
				continue
			for extra: Dictionary in rules.objectives():
				if extra["id"] in [attack["id"], keep["id"]]:
					continue
				for a: Dictionary in rules.options():
					for b: Dictionary in rules.options():
						if a["id"] == b["id"]:
							continue
						var k := Contract.new()
						k.objectives.assign([attack["id"], keep["id"], extra["id"]])
						k.offered.assign([a["id"], b["id"]])
						max_track = maxi(max_track, k.cost(rules))
	check(max_track > 0)
	check(company.wp >= max_track + rules.sp("max_wp_per_month"), "Every opener affordable even after one month's support conversion")
	check_eq(SupportShop.convert(company, rules, rules.sp("max_wp_per_month")), "")
	var rng := RandomNumberGenerator.new()
	for seed_value in 128:
		rng.seed = seed_value
		for k in ContractBoard.offer(rules, rng):
			check(k.cost(rules) <= company.wp, "No forced debt on a fresh board")


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
