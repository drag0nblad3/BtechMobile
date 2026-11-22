extends TestCase
## Force builder catalog (DesignFilter): technology filter, OmniMech groups.


func test_filter_and_groups() -> void:
	var db := designs()
	var all := DesignFilter.groups(db, DesignFilter.Mode.ALL)
	var clan := DesignFilter.groups(db, DesignFilter.Mode.CLAN)
	var inner := DesignFilter.groups(db, DesignFilter.Mode.INNER_SPHERE)
	check_eq(all.size(), clan.size() + inner.size())
	var chassis := {}
	for d: UnitDef in db.by_id.values():
		if d.is_clan():
			chassis[d.chassis if d.omni else d.id] = true
	check_eq(clan.size(), chassis.size(), "one entry per Clan chassis")
	for g: Array in clan:
		check(g.all(func(d: UnitDef) -> bool: return d.is_clan()))
		if g[0].omni:
			check_eq(g[0].config, "Prime", "%s lists the Prime first" % g[0].chassis)
	for g: Array in inner:
		check(g[0].omni or g.size() == 1, "one entry per Inner Sphere design, configs grouped for OmniMechs")
		check(not g[0].is_clan())
	var tw: Array = clan.filter(func(g: Array) -> bool: return g[0].chassis == "timber_wolf")[0]
	check_eq(tw.map(func(d: UnitDef) -> String: return d.config), ["Prime", "A", "B", "E", "Pryde"])
	check(clan[0][0].tonnage <= clan[-1][0].tonnage, "light to heavy")
	check_eq(DesignFilter.next(DesignFilter.Mode.CLAN), DesignFilter.Mode.ALL)
