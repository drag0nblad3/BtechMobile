extends TestCase
## Every preset is a legal, affordable selection of official unit definitions.


func test_all_starters_are_valid() -> void:
	var db := designs()
	var entries := StarterFormations.all()
	check(entries.size() >= 30, "at least thirty introductory lances and stars")
	var seen := {}
	var lances := 0
	var stars := 0
	for f: Dictionary in entries:
		check(not seen.has(f["id"]), "unique formation IDs")
		seen[f["id"]] = true
		var kind := String(f["kind"])
		var tier := int(f.get("recommended_bv", 0))
		check(tier in ForceBuilder.BUDGETS, "supported tier for %s" % f["id"])
		lances += 1 if kind == "lance" else 0
		stars += 1 if kind == "star" else 0
		var fb := ForceBuilder.new(db)
		var p := StarterFormations.plan(fb, 0, f)
		check(bool(p.get("ok", false)), "%s: %s" % [f["id"], p.get("reason", "")])
		if p.get("ok", false):
			var cost := int(p["cost"])
			check(cost <= tier, "%s fits advertised %d BV, costs %d" % [f["id"], tier, cost])
			check(float(cost) >= float(tier) * 0.75,
				"%s is a meaningful %d BV game (%d cost)" % [f["id"], tier, cost])
			var applied := StarterFormations.apply(fb, 0, f)
			check(applied["ok"], "preset applies")
			check_eq(fb.rosters[0].size(), 5 if kind == "star" else 4)
			check(fb.bv(0) <= fb.budget, "within the recommended budget")
			check(fb.budget in ForceBuilder.BUDGETS, "uses an existing BV tier")
	check(lances >= 15 and stars >= 10, "both types represented")
	for tier in ForceBuilder.BUDGETS:
		check(entries.any(func(f: Dictionary) -> bool:
			return int(f["recommended_bv"]) == tier), "formation at %d BV" % tier)


func test_replaces_only_target_and_upgrades_budget_if_needed() -> void:
	var db := designs()
	var fb := ForceBuilder.new(db, 3000)
	check(fb.add(1, "locust_lct1v"))
	var unchanged: Array = fb.rosters[1].duplicate()
	var form: Dictionary = StarterFormations.all().filter(
		func(f: Dictionary) -> bool: return f["id"] == "clan_recon")[0]
	var preview := StarterFormations.plan(fb, 0, form)
	check(preview["ok"], "star is legal")
	check(bool(preview["raises_budget"]), "star needs a budget increase")
	check_eq(fb.budget, 3000, "preview does not mutate budget")
	check_eq(fb.rosters[0].size(), 0, "preview does not modify roster")
	var result := StarterFormations.apply(fb, 0, form)
	check(result["ok"], "star loads")
	check_eq(fb.rosters[0].size(), 5, "full Clan Star")
	check_eq(fb.rosters[1], unchanged, "Blue force stays untouched")
	check(fb.budget >= int(result["cost"]), "budget accommodates new Star")


func test_invalid_formation_never_clears_existing_roster() -> void:
	var fb := ForceBuilder.new(designs(), 3000)
	fb.add(0, "locust_lct1v")
	var previous: Array = fb.rosters[0].duplicate()
	var bad := {"id": "invalid", "kind": "lance",
		"units": ["locust_lct1v", "wasp_wsp1a", "unknown_mech", "commando_com2d"]}
	var result := StarterFormations.apply(fb, 0, bad)
	check(not result["ok"], "invalid selection rejected")
	check_eq(fb.rosters[0], previous, "roster preserved after failure")
	check_eq(fb.budget, 3000, "budget preserved after failure")


func test_advanced_pilots_cannot_create_illegal_max_tier() -> void:
	var fb := ForceBuilder.new(designs(), 12000)
	fb.skills[0] = Vector2i(3, 4)
	fb.add(0, "locust_lct1v")
	var previous: Array = fb.rosters[0].duplicate()
	var form: Dictionary = StarterFormations.all().filter(
		func(f: Dictionary) -> bool: return f["id"] == "clan_heavy_strike")[0]
	var result := StarterFormations.apply(fb, 0, form)
	check(not result["ok"], "veteran 12k Star exceeds 12k cap")
	check_eq(fb.rosters[0], previous, "failed high-BV template preserves roster")
	check_eq(fb.budget, 12000, "failed high-BV template preserves cap")


func test_presets_preserve_opposition_at_large_sizes() -> void:
	var fb := ForceBuilder.new(designs(), 8000)
	fb.add(0, "locust_lct1v")
	var before: Array = fb.rosters[0].duplicate()
	var form: Dictionary = StarterFormations.all().filter(
		func(f: Dictionary) -> bool: return f["id"] == "clan_assault_star")[0]
	var plan := StarterFormations.plan(fb, 1, form)
	check(plan["ok"], "10k star is viable")
	check_eq(int(plan["budget"]), 10000)
	check(bool(plan["raises_budget"]), "increases shared cap")
	var result := StarterFormations.apply(fb, 1, form)
	check(result["ok"], "10k star loads")
	check_eq(fb.rosters[0], before, "first force untouched")
	check_eq(fb.budget, 10000)
	check_eq(fb.rosters[1].size(), 5)


func test_advanced_tiers_exist_in_order() -> void:
	check_eq(ForceBuilder.BUDGETS, [2000, 3000, 4500, 6000, 8000, 10000, 12000])
