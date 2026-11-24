extends TestCase
## Chaos Campaign (Campaign Operations pp. 156-173): contracts, Warchest
## costs and payouts, debt, objectives and options.


func _battle() -> GameState:
	var fb := ForceBuilder.new(designs(), 20000)
	for id in ["wolverine_wvr6r", "griffin_grf1n", "shadow_hawk_shd2h", "phoenix_hawk_pxh1"]:
		fb.add(0, id)
	for id in ["commando_com2d", "wasp_wsp1a", "griffin_grf1n", "wolverine_wvr6r"]:
		fb.add(1, id)
	return fb.build(make_map(["c0 c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0 c0",
		"c0 c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0 c0"]))


func test_contract_cost_is_three_quarters_of_its_rewards() -> void:
	var r := ChaosRules.load_file()
	var k := Contract.new()
	k.objectives.assign(["advance_attack", "bullet_time"])  # 300 + 100
	k.offered.assign(["elites"])  # pick inside 125-300
	var total := 400 + int(r.option("elites")["wp"])
	check_eq(k.max_reward(r), total)
	check_eq(k.cost(r), int(round(total * 0.75)))
	k.chosen.assign(["elites"])
	check_eq(k.payout(r, [] as Array[String]), 0, "no objective, no option bonus")
	check_eq(k.payout(r, ["bullet_time"] as Array[String]), 100 + int(r.option("elites")["wp"]))


func test_board_offers_mixed_objectives() -> void:
	var r := ChaosRules.load_file()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var board := ContractBoard.offer(r, rng)
	check_eq(board.size(), 3)
	for k in board:
		check(StandardMissions.info(k.mission_id).size() > 0, "a standard mission")
		check(k.objectives.size() >= 2 and k.offered.size() == 2, "objectives and options")
		check(r.objective(k.objectives[0])["check"] in ContractBoard.ENEMY_CHECKS, "one is about the enemy")
		check(not r.objective(k.objectives[1])["check"] in ContractBoard.ENEMY_CHECKS, "one is about your force")


func test_debt_only_once_in_a_row() -> void:
	var r := ChaosRules.load_file()
	var c := Campaign.create(CampaignRules.load_file(), r)
	var k := Contract.new()
	k.objectives.assign(["bring_the_pain", "being_difficult"])  # 1000 max -> costs 750
	c.wp = 100
	check_eq(Warchest.cant_take(c, k, r), "", "first time, debt is allowed")
	Warchest.take(c, k, r)
	check(c.on_debt and c.wp < 0, "in debt")
	c.contract = null
	check(Warchest.cant_take(c, k, r) != "", "not twice in a row")


func test_objectives_and_settlement() -> void:
	var r := ChaosRules.load_file()
	var s := _battle()
	var enemy := s.units_of_side(1)
	Damage.destroy_unit(enemy[0], "engine destroyed")
	Damage.destroy_unit(enemy[1], "engine destroyed")
	check(ChaosObjective.met(r.objective("advance_attack"), s, 0), "half the enemy down")
	check(not ChaosObjective.met(r.objective("hammer"), s, 0), "not two-thirds")
	check(ChaosObjective.met(r.objective("frugal"), s, 0), "no losses")
	Damage.destroy_location(s.units_of_side(0)[0], Location.HEAD)
	check(not ChaosObjective.met(r.objective("bullet_time"), s, 0), "a MechWarrior died")
	check(ChaosObjective.met(r.objective("fight_another_day"), s, 0), "one of four lost")
	check(not ChaosObjective.met(r.objective("frugal"), s, 0), "25% is more than 10%")
	var c := Campaign.create(CampaignRules.load_file(), r)
	var k := Contract.new()
	k.objectives.assign(["advance_attack", "bullet_time"])
	k.offered.assign(["a_cut_above"])
	k.chosen.assign(["a_cut_above"])
	Warchest.take(c, k, r)
	var before := c.wp
	var lines := Warchest.settle(c, r, s, 0)
	check_eq(c.wp, before + 300 + int(r.option("a_cut_above")["wp"]), "objective + option")
	check(c.contract == null and c.last_met == 1, "contract closed")
	check(lines.size() == 4, "a line per objective and option, plus the total")


func test_options_change_the_enemy() -> void:
	var r := ChaosRules.load_file()
	var fb := ForceBuilder.new(designs(), 20000)
	fb.add(0, "wolverine_wvr6r")
	fb.add(1, "griffin_grf1n")
	fb.add(1, "wasp_wsp1a")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var chosen: Array[String] = ["bad_intel", "heavy_fog", "a_cut_above"]
	ChaosOptions.before(fb, chosen, Dice.new(5), rng)
	check_eq(fb.mech_ids(1).size(), 3, "Bad Intel adds a 'Mech")
	check(fb.conditions.low_visibility, "Heavy Fog")
	var s := fb.build(make_map(["c0 c0 c0 c0", "c0 c0 c0 c0", "c0 c0 c0 c0", "c0 c0 c0 c0"]))
	ChaosOptions.after(s, chosen, r)
	var vet := r.skill("veteran")
	var last: Unit = s.units_of_side(1).back()
	check_eq(last.pilot.gunnery, vet.x - 1, "veteran, then A Cut Above")
	check_eq(s.units_of_side(1)[0].pilot.piloting, fb.skills[1].y - 1)


func test_enemy_force_matches_bv() -> void:
	var fb := ForceBuilder.new(designs(), 20000)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var ids := EnemyForce.pick(fb, 4000, rng)
	check_eq(ids.size(), 4)
	var bv := 0
	for id in ids:
		bv += fb.unit_bv(1, designs().get_def(id))
		check(not designs().get_def(id).is_clan(), "Inner Sphere")
	check(absi(bv - 4000) < 600, "close to the target (%d)" % bv)
