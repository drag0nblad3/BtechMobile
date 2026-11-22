extends TestCase
## Exact-variant checks and their integration with the force builder.


func _sample() -> EraAvailability:
	return EraAvailability.new({"units": {
		"atlas_as7d": {"intro_year": 2755, "factions": {
			"federated_suns": ["sw_renaissance", "clan_invasion"],
			"clan_wolf": []}},
		"atlas_as7k": {"intro_year": 3049, "factions": {
			"federated_suns": ["clan_invasion"]}}
	}})


func test_era_boundaries_and_factions() -> void:
	check_eq(EraAvailability.era_id(3049), "sw_renaissance")
	check_eq(EraAvailability.era_id(3050), "clan_invasion")
	check_eq(EraAvailability.era_id(3151), "ilclan")
	check_eq(EraAvailability.era_id(2397), "")
	check_eq(EraAvailability.era_id(3154), "")
	check_eq(EraAvailability.FACTIONS.size(), 71, "complete published MUL faction list")


func test_intro_year_faction_matrix_and_unknown_are_distinct() -> void:
	var a := _sample()
	check_eq(a.check("atlas_as7k", 3025, "federated_suns")["status"], "unavailable")
	check_eq(a.check("atlas_as7d", 3025, "federated_suns")["status"], "available")
	check_eq(a.check("atlas_as7d", 3025, "clan_wolf")["status"], "unavailable")
	check_eq(a.check("atlas_as7d", 3025, "draconis_combine")["status"], "unverified")
	check_eq(a.check("timber_wolf_a", 3050, "clan_wolf")["status"], "unverified")
	check_eq(a.check("atlas_as7k", 3049, "federated_suns")["status"], "unavailable")


func test_strict_advisory_and_existing_rosters() -> void:
	var fb := ForceBuilder.new(designs(), 12000)
	fb.availability = _sample()
	fb.era_year = 3025
	fb.factions[0] = "federated_suns"
	fb.factions[1] = "clan_wolf"
	fb.availability_mode = EraAvailability.Mode.STRICT
	check(fb.add(0, "atlas_as7d"), "verified unit allowed")
	check(not fb.add(0, "atlas_as7k"), "future variant blocked")
	check(fb.cant_add(0, "atlas_as7k").contains("3049"), "gives reason")
	check(not fb.add(1, "atlas_as7d"), "wrong faction blocked")
	check(not fb.add(1, "hunchback_hbk4g"), "unverified variant blocked")
	fb.availability_mode = EraAvailability.Mode.ADVISORY
	check(fb.add(1, "hunchback_hbk4g"), "advisory admits unverified")
	check(fb.ready_to_fight(), "advisory permits combat")
	fb.availability_mode = EraAvailability.Mode.STRICT
	check(not fb.ready_to_fight(), "strict rechecks existing roster")
	check(fb.first_restriction_issue() != "", "explain why cannot deploy")
	check_eq(fb.rosters[1].size(), 1, "policy never removes units")
	fb.availability_mode = EraAvailability.Mode.OFF
	check(fb.ready_to_fight(), "default play remains unrestricted")


func test_verified_bundle_examples() -> void:
	var a := EraAvailability.new()
	check_eq(a.check("locust_lct1v", 3025, "federated_suns")["status"], "available")
	check_eq(a.check("jenner_jr7d", 2750, "draconis_combine")["status"], "unavailable")
	check_eq(a.check("timber_wolf_prime", 3050, "clan_wolf")["status"], "available")
	check_eq(a.check("atlas_as7d", 3025, "clan_wolf")["status"], "unavailable")
	check_eq(a.check("atlas_as7d", 3025, "clan_jade_falcon")["status"], "unverified")


func test_starter_templates_follow_historical_policy_without_mutation() -> void:
	var fb := ForceBuilder.new(designs(), 6000)
	fb.availability = _sample()
	fb.era_year = 3025
	fb.factions[0] = "federated_suns"
	fb.availability_mode = EraAvailability.Mode.STRICT
	check(fb.add(0, "atlas_as7d"))
	var old: Array = fb.rosters[0].duplicate()
	var old_budget: int = fb.budget
	var template: Dictionary = StarterFormations.all()[0]
	var preview: Dictionary = StarterFormations.plan(fb, 0, template)
	check(not preview["ok"], "unverified units block strict formation preflight")
	check_eq(fb.rosters[0], old, "preview preserves roster")
	check_eq(fb.budget, old_budget, "preview preserves budget")
	var attempted: Dictionary = StarterFormations.apply(fb, 0, template)
	check(not attempted["ok"], "strict template apply also fails")
	check_eq(fb.rosters[0], old, "failure preserves roster")
	fb.availability_mode = EraAvailability.Mode.OFF
	check(StarterFormations.plan(fb, 0, template)["ok"], "off keeps existing starters")


func test_faction_lifetimes_enforce_history_without_unit_records() -> void:
	var available := _sample()
	check_eq(available.check("atlas_as7d", 3025, "federated_commonwealth")["status"],
		"unavailable", "Federated Commonwealth does not yet exist in 3025")
	check_eq(available.check("atlas_as7d", 3152, "comstar")["status"],
		"unavailable", "ComStar has dissolved by ilClan")
	check_eq(available.check("atlas_as7d", 3152, "ilclan_wolf")["status"],
		"unverified", "a historically active faction still needs an exact-variant record")
	check_eq(available.check("atlas_as7d", 3025, "invented_faction")["status"],
		"unverified", "unrecognized faction is unknown, not valid")

func test_changing_year_invalidates_assembled_force_without_removing_it() -> void:
	var fb := ForceBuilder.new(designs(), 12000)
	fb.availability = _sample()
	fb.availability_mode = EraAvailability.Mode.STRICT
	fb.era_year = 3025
	fb.factions[0] = "federated_suns"
	check(fb.add(0, "atlas_as7d"))
	var saved: Array = fb.rosters[0].duplicate()
	fb.era_year = 2700
	check(fb.first_restriction_issue().contains("2755"),
		"an existing unit can become anachronistic with a changed date")
	check_eq(fb.rosters[0], saved, "changing era never erases units")
