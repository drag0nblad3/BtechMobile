class_name MarketPanel
extends RefCounted
## The 'Mech market on the campaign screen: this month's designs for sale
## and a Sell button (tap twice) on each company 'Mech. `act` runs a
## MechMarket call and redraws, like SupportPanel.

static var armed := ""  ## Mech id waiting for the second tap on Sell.


static func market(list: VBoxContainer, c: Campaign, db: UnitDb, rules: ChaosRules, act: Callable, redraw: Callable = Callable()) -> void:
	UiKit.label(list, "'Mechs for sale this month", 26).modulate = Color(0.75, 0.85, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if c.market.is_empty():
		MechMarket.stock(c, db, rules, rng)
		CampaignStore.save(c)
	var row := SupportPanel.flow(list)
	for i in UnitFavorites.indices(c.market, func(id: String) -> String: return id):
		var def := db.get_def(c.market[i])
		if def == null:
			continue
		var item := HBoxContainer.new()
		row.add_child(item)
		UnitFavorites.button(item, def.id, redraw)
		var b := SupportPanel.small_button(item, "Buy %s %s (%d t, %s) · %d SP" % [def.name, def.model, def.tonnage,
				"Introductory" if IntroTech.is_intro(def, rules) else "Standard", MechMarket.price(def, rules)],
				act.bind(MechMarket.buy.bind(c, def.id, db, rules)))
		b.name = "Buy%d" % i
	if c.market.is_empty():
		UiSkin.label(UiKit.label(list, "Sold out until next month.", UiKit.SMALL), "muted")


static func sell_button(row: Control, c: Campaign, m: CampaignMech, db: UnitDb, rules: ChaosRules, act: Callable) -> void:
	var def := db.get_def(m.design)
	if def == null:
		return
	var value := MechMarket.sell_price(def, m, rules)
	var text := ("Scrap" if m.written_off else "Sell · %d SP" % value)
	if armed == m.id:
		text = "Tap again to " + text.to_lower()
	SupportPanel.small_button(row, text, act.bind(_sell.bind(c, m, db, rules))).name = "Sell_" + m.id


static func _sell(c: Campaign, m: CampaignMech, db: UnitDb, rules: ChaosRules) -> String:
	if armed != m.id:
		armed = m.id
		return ""
	armed = ""
	return MechMarket.sell(c, m, db, rules)
