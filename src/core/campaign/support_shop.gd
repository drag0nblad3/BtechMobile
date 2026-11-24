class_name SupportShop
extends RefCounted
## Spending between contracts with the optional Support Points rule
## (Campaign Operations pp. 161-164): turning WP into SP, repairs and
## rearming (MechRepair), healing, skill training and hiring. Every
## action returns "" when done or the reason it can't be done.


## SP gained for each WP: Base Force Size Modifier x Technology Rating Modifier.
static func rate(c: Campaign, rules: ChaosRules) -> float:
	var mods: Dictionary = rules.support().get("rating_modifier", {})
	return c.size_mod * float(mods.get(String(rules.support().get("equipment_rating", "D")), 1.0))


## WP that can still be turned into SP this month.
static func convertible(c: Campaign, rules: ChaosRules) -> int:
	return clampi(mini(rules.sp("max_wp_per_month") - c.converted, c.wp), 0, 1 << 30)


static func convert(c: Campaign, rules: ChaosRules, wp: int) -> String:
	var n := mini(wp, convertible(c, rules))
	if n <= 0:
		return "No more WP can be converted this month." if c.wp > 0 else "The Warchest is empty."
	c.wp -= n
	c.converted += n
	c.sp += roundi(n * rate(c, rules))
	return ""


## A new month between contracts: conversion, healing and training reset.
static func new_month(c: Campaign) -> void:
	c.month += 1
	c.converted = 0
	c.done.clear()
	c.market.clear()


## Why nothing can be bought now, or "".
static func closed(c: Campaign) -> String:
	if c.contract != null:
		return "Finish the current contract first."
	if c.wp < 0:
		return "No spending while the company is in Warchest debt."
	return ""


## Takes `n` SP, or says why it can't.
static func pay(c: Campaign, n: int) -> String:
	var why := closed(c)
	if why == "" and c.sp < n:
		why = "Needs %d SP; you have %d." % [n, c.sp]
	if why == "":
		c.sp -= n
	return why


static func repair(c: Campaign, m: CampaignMech, def: UnitDef, job: String, rules: ChaosRules) -> String:
	if not MechRepair.needs(m, def, job):
		return "Nothing to do."
	var why := pay(c, MechRepair.cost(def, job, rules))
	if why == "":
		MechRepair.apply(m, def, job)
	return why


static func heal(c: Campaign, p: CampaignPilot, rules: ChaosRules) -> String:
	if p.dead or p.wounds <= 0:
		return "No wounds to heal."
	if c.done.count("heal:" + p.id) >= rules.sp("heals_per_month"):
		return "Only one wound heals a month."
	var why := pay(c, rules.sp("heal_wound"))
	if why == "":
		p.wounds -= 1
		c.done.append("heal:" + p.id)
	return why


## Cost to lower `skill` ("gunnery" or "piloting") by one: triple for a
## MechWarrior who sat out the last contract (p. 164).
static func train_cost(p: CampaignPilot, skill: String, rules: ChaosRules) -> int:
	var n := rules.sp("train_" + skill)
	return n if p.fought_last else n * rules.sp("idle_training_multiplier")


static func train(c: Campaign, p: CampaignPilot, skill: String, rules: ChaosRules) -> String:
	var key := "train:%s:%s" % [p.id, skill]
	if p.dead:
		return "Killed in action."
	if int(p.get(skill)) <= 0:
		return "Already as good as it gets."
	if c.done.has(key):
		return "One point per skill between contracts."
	var why := pay(c, train_cost(p, skill, rules))
	if why == "":
		p.set(skill, int(p.get(skill)) - 1)
		c.done.append(key)
	return why


## Hiring a MechWarrior: Green 100 SP, Regular x2, Veteran x3 (p. 163).
static func hire_cost(level: String, rules: ChaosRules) -> int:
	return rules.sp("hire_mechwarrior") * int(rules.support().get("hire_multiplier", {}).get(level, 1))


static func hire(c: Campaign, level: String, rules: ChaosRules) -> String:
	var why := pay(c, hire_cost(level, rules))
	if why == "":
		var names: Array = rules.support().get("recruit_names", ["MechWarrior"])
		var s := rules.skill(level)
		c.add_pilot(String(names[c.pilots.size() % names.size()]), s.x, s.y)
	return why


## Seats free MechWarrior `p` in 'Mech `m` (free of charge).
static func assign(c: Campaign, m: CampaignMech, p: CampaignPilot, def: UnitDef) -> String:
	if m.written_off:
		return "That 'Mech is a write-off."
	if not c.free_pilots().has(p):
		return "%s already has a 'Mech." % p.name
	m.pilot_id = p.id
	MechRepair.tidy(m, def)
	return ""
