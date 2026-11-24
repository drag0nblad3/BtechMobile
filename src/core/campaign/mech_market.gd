class_name MechMarket
extends RefCounted
## Buying and selling 'Mechs for Support Points (Campaign Operations
## p. 163): tonnage x 10 SP for an Introductory Rules 'Mech, x 20 for a
## Standard Rules one, double for Clan; it comes without a MechWarrior.
## Selling pays half price (p. 173). Each month a few official Inner
## Sphere designs are for sale (our pick; the book leaves it to the GM).


static func price(def: UnitDef, rules: ChaosRules) -> int:
	var per := rules.sp("purchase_intro_per_ton" if IntroTech.is_intro(def, rules) else "purchase_standard_per_ton")
	return def.tonnage * per * (rules.sp("clan_multiplier") if def.is_clan() else 1)


## Half price, nothing for a write-off. TODO(rules): damage doesn't lower it.
static func sell_price(def: UnitDef, m: CampaignMech, rules: ChaosRules) -> int:
	if m.written_off:
		return 0
	return roundi(price(def, rules) * float(rules.support().get("sell_share", 0.5)))


## Fills this month's market if it's empty.
static func stock(c: Campaign, db: UnitDb, rules: ChaosRules, rng: RandomNumberGenerator) -> void:
	if not c.market.is_empty():
		return
	var pool := EnemyForce.designs(db)
	for i in mini(rules.sp("market_size"), pool.size()):
		var def: UnitDef = pool[rng.randi_range(0, pool.size() - 1)]
		if not c.market.has(def.id):
			c.market.append(def.id)


static func buy(c: Campaign, design: String, db: UnitDb, rules: ChaosRules) -> String:
	var def := db.get_def(design)
	if def == null or not c.market.has(design):
		return "Not for sale this month."
	var why := SupportShop.pay(c, price(def, rules))
	if why == "":
		c.market.erase(design)
		c.add_mech(design)
	return why


## Sells (or, for a write-off, scraps) `m`; its MechWarrior is freed.
static func sell(c: Campaign, m: CampaignMech, db: UnitDb, rules: ChaosRules) -> String:
	var why := SupportShop.closed(c)
	if why != "":
		return why
	c.sp += sell_price(db.get_def(m.design), m, rules)
	c.mechs.erase(m)
	return ""
