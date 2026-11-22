extends TestCase
## Every preset is a legal, affordable selection of official unit definitions.


func test_all_starters_are_valid() -> void:
	var db := designs()
	var entries := StarterFormations.all()
	check(entries.size() >= 6, "multiple introductory lances and stars")
	var seen := {}
	var lances := 0
	var stars := 0
	for f: Dictionary in entries:
		check(not seen.has(f["id"]), "unique formation IDs")
		seen[f["id"]] = true
		var kind := String(f["kind"])
		lances += 1 if kind == "lance" else 0
		stars += 1 if kind == "star" else 0
		var fb := ForceBuilder.new(db)
		var p := StarterFormations.plan(fb, 0, f)
		check(bool(p.get("ok", false)), "%s: %s" % [f["id"], p.get("reason", "")])
		if p.get("ok", false):
			var applied := StarterFormations.apply(fb, 0, f)
			check(applied["ok"], "preset applies")
			check_eq(fb.rosters[0].size(), 5 if kind == "star" else 4)
			check(fb.bv(0) <= fb.budget, "within the recommended budget")
			check(fb.budget in ForceBuilder.BUDGETS, "uses an existing BV tier")
	check(lances >= 3 and stars >= 2, "both types represented")


func test_replaces_only_target_and_upgrades_budget_if_needed() -> void:
	var db := designs()
	var fb := ForceBuilder.new(db, 3000)
	check(fb.add(1, "locust_lct1v"))
	var unchanged := fb.rosters[1].duplicate()
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
	var previous := fb.rosters[0].duplicate()
	var bad := {"id": "invalid", "kind": "lance",
		"units": ["locust_lct1v", "wasp_wsp1a", "unknown_mech", "commando_com2d"]}
	var result := StarterFormations.apply(fb, 0, bad)
	check(not result["ok"], "invalid selection rejected")
	check_eq(fb.rosters[0], previous, "roster preserved after failure")
	check_eq(fb.budget, 3000, "budget preserved after failure")
