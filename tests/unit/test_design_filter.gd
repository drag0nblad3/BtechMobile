extends TestCase
## Force builder catalog (DesignFilter): technology filter, OmniMech groups.


func test_filter_and_groups() -> void:
	var db := UnitDb.load_dir()
	var all := DesignFilter.groups(db, DesignFilter.Mode.ALL)
	var clan := DesignFilter.groups(db, DesignFilter.Mode.CLAN)
	var inner := DesignFilter.groups(db, DesignFilter.Mode.INNER_SPHERE)
	check_eq(all.size(), clan.size() + inner.size())
	check_eq(clan.size(), 26, "one entry per Clan chassis")
	for g: Array in clan:
		check(g.all(func(d: UnitDef) -> bool: return d.is_clan()))
		if g[0].omni:
			check_eq(g[0].config, "Prime", "%s lists the Prime first" % g[0].chassis)
	for g: Array in inner:
		check_eq(g.size(), 1)
		check(not g[0].is_clan())
	var tw: Array = clan.filter(func(g: Array) -> bool: return g[0].chassis == "timber_wolf")[0]
	check_eq(tw.map(func(d: UnitDef) -> String: return d.config), ["Prime", "A", "B"])
	check(clan[0][0].tonnage <= clan[-1][0].tonnage, "light to heavy")
	check_eq(DesignFilter.next(DesignFilter.Mode.CLAN), DesignFilter.Mode.ALL)


func test_tips() -> void:
	var db := UnitDb.load_dir()
	check(DesignFilter.tech_tip(db.get_def("timber_wolf_prime")).contains("OmniMech"))
	check(DesignFilter.tech_tip(db.get_def("timber_wolf_prime")).contains("Clan"))
	check_eq(DesignFilter.tech_tip(db.get_def("atlas_as7d")), "")
