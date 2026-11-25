class_name SpaShop
extends RefCounted
## Learning Special Pilot Abilities with Support Points (Campaign Operations
## pp. 70, 163-164). A MechWarrior's Skill Rating caps them: Green none,
## Regular one worth up to 2 points, Veteran and Elite two worth up to 4 in
## all. Each costs 100 SP, and a MechWarrior learns at most one every three
## months. TODO(rules): Lucky is learned at 1 point (one reroll); a Weapon
## Specialist picks from the weapons on its current 'Mech.

const ORDER := ["elite", "veteran", "regular"]


## "green", "regular", "veteran" or "elite", from gunnery and piloting.
static func rating(p: CampaignPilot, rules: ChaosRules) -> String:
	for level: String in ORDER:
		var s := rules.skill(level)
		if p.gunnery <= s.x and p.piloting <= s.y:
			return level
	return "green"


## [most abilities, most points] for the pilot's rating.
static func limits(p: CampaignPilot, rules: ChaosRules) -> Vector2i:
	var l: Array = rules.support().get("spa_limits", {}).get(rating(p, rules), [0, 0])
	return Vector2i(int(l[0]), int(l[1]))


static func points(p: CampaignPilot) -> int:
	var n := 0
	for a in p.abilities:
		n += int(Spa.info(a.get_slice(":", 0)).get("cost", 1))
	return n


## Abilities `p` could learn now: [{entry, name, cost}] (cost in points).
static func offers(p: CampaignPilot, def: UnitDef) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var have := p.abilities.map(func(a: String) -> String: return a.get_slice(":", 0))
	for a: Dictionary in Spa.all():
		var id := String(a["id"])
		if have.has(id) and id != Spa.TERRAIN_MASTER:
			continue
		var picks: Array = a.get("choices", [])
		if id == Spa.WEAPON_SPECIALIST:
			picks = _weapons(def)
		if picks.is_empty():
			out.append({"entry": id, "name": a["name"], "cost": int(a["cost"])})
		for pick in picks:
			var entry := "%s:%s" % [id, pick]
			if not p.abilities.has(entry):
				out.append({"entry": entry, "name": "%s (%s)" % [a["name"], String(pick).capitalize()], "cost": int(a["cost"])})
	return out


## Why `p` can't learn ability `entry` now, or "".
static func why_not(c: Campaign, p: CampaignPilot, entry: String, rules: ChaosRules) -> String:
	if p.dead:
		return "Killed in action."
	var lim := limits(p, rules)
	if lim.x == 0:
		return "%s is still Green: no special abilities yet." % p.name
	if p.abilities.size() >= lim.x:
		return "A %s MechWarrior can have %d abilit%s." % [rating(p, rules).capitalize(), lim.x, "y" if lim.x == 1 else "ies"]
	var cost := int(Spa.info(entry.get_slice(":", 0)).get("cost", 1))
	if points(p) + cost > lim.y:
		return "Too much for a %s MechWarrior: at most %d points of abilities." % [rating(p, rules).capitalize(), lim.y]
	var wait := int(rules.support().get("spa_months", 3)) - (c.month - p.spa_month)
	if wait > 0:
		return "%s learned an ability recently: %d more month%s." % [p.name, wait, "" if wait == 1 else "s"]
	return ""


static func learn(c: Campaign, p: CampaignPilot, entry: String, rules: ChaosRules) -> String:
	var why := why_not(c, p, entry, rules)
	if why == "":
		why = SupportShop.pay(c, rules.sp("spa"))
	if why == "":
		p.abilities.append(entry)
		p.spa_month = c.month
	return why


static func _weapons(def: UnitDef) -> Array:
	var ids := []
	if def != null:
		for m: Dictionary in def.weapon_mounts:
			var w: WeaponDef = m["weapon"]
			if not ids.has(w.id):
				ids.append(w.id)
	return ids
