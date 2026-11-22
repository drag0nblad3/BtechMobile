class_name AssetSheetView
extends RefCounted
## The live Asset card for a vehicle or infantry unit, as rich text (book
## p. 140): movement, TMM, attack, Skill, Destroy Check after Degradation,
## Threshold, damage taken this turn and Specials.


static func text(u: Unit) -> String:
	var c := u.asset.card
	var a := u.asset
	var t := "[b]%s[/b]  %s %s%s\n" % [Names.unit(u), c.motive_name(), c.kind.replace("_", " "),
			" · Clan" if u.def.is_clan() else ""]
	t += "MP %s · TMM %+d\n" % ["immobile" if c.immobile() else "%d%s" % [c.mp, c.motive], c.tmm]
	t += "Attack %d×%d at %d/%d/%d hexes · Skill %d%s\n" % [c.damage, c.groupings, c.short_range,
			c.medium_range, c.long_range, a.skill(), " (improved)" if a.improved else ""]
	var worn := c.check - a.check
	t += "Destroy Check %d+%s · Threshold %d\n" % [a.check,
			" [color=#e0a040](worn down %d)[/color]" % worn if worn > 0 else "", c.threshold]
	if a.damage > 0:
		t += "Damage this turn: [color=#e05040]%d[/color]%s\n" % [a.damage,
				" (Destroy Check at the End Phase)" if a.damage >= c.threshold else ""]
	if not c.specials.is_empty():
		var sp: Array[String] = []
		for k: String in c.specials:
			sp.append(k if int(c.specials[k]) <= 1 else "%s%d" % [k, c.specials[k]])
		t += "Specials: %s\n" % ", ".join(sp)
	t += "BV %d (%d BSP)" % [a.bv(), c.bsp_improved if a.improved and c.bsp_improved > 0 else c.bsp]
	return t
