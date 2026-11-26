class_name ContractBoard
extends RefCounted
## Builds the contracts on offer between battles: a standard mission, an
## enemy size from the book's examples, two or three objectives (at least
## one about beating the enemy and one about keeping your own force), and
## two options. The mix is our pick; the book leaves it to the GM.

const ENEMY_CHECKS := ["enemy_down", "trade"]


static func offer(rules: ChaosRules, rng: RandomNumberGenerator, count: int = 3) -> Array[Contract]:
	var out: Array[Contract] = []
	var missions := StandardMissions.available_ids()
	for i in count:
		var c := Contract.new()
		c.mission_id = missions[rng.randi_range(0, missions.size() - 1)]
		var sizes: Array = rules.data.get("enemy_bv_percent", [100])
		c.enemy_percent = int(sizes[rng.randi_range(0, sizes.size() - 1)])
		var attack: Array = rules.objectives().filter(func(o: Dictionary) -> bool: return o["check"] in ENEMY_CHECKS)
		var keep: Array = rules.objectives().filter(func(o: Dictionary) -> bool: return not o["check"] in ENEMY_CHECKS)
		c.objectives.append(_pick(attack, rng))
		c.objectives.append(_pick(keep, rng))
		if rng.randi_range(0, 1) == 1:
			var rest: Array = rules.objectives().filter(func(o: Dictionary) -> bool: return not c.objectives.has(o["id"]))
			c.objectives.append(_pick(rest, rng))
		var opts: Array = rules.options().duplicate()
		for n in 2:
			var id := _pick(opts, rng)
			c.offered.append(id)
			opts = opts.filter(func(o: Dictionary) -> bool: return o["id"] != id)
		out.append(c)
	return out


## Preserve an existing board whenever a debt-free choice is available.
## For older unfought companies with a smaller Warchest, offer a low-cost
## track using the same legal objective/option mix and full price formula.
## No effect on later campaigns, active contracts or company balances.
static func ensure_opening_choice(company: Campaign, rules: ChaosRules) -> int:
	if company.battles != 0 or company.contract != null or company.on_debt or company.offers.is_empty():
		return -1
	if affordable_index(company, rules) >= 0:
		return -1
	var cheapest := company.offers[0]
	var index := 0
	for i in company.offers.size():
		if company.offers[i].cost(rules) < cheapest.cost(rules):
			cheapest = company.offers[i]
			index = i
	var attack: Array = rules.objectives().filter(func(o: Dictionary) -> bool: return o["check"] in ENEMY_CHECKS)
	var keep: Array = rules.objectives().filter(func(o: Dictionary) -> bool: return not o["check"] in ENEMY_CHECKS)
	var opts: Array = rules.options().duplicate()
	if attack.is_empty() or keep.is_empty() or opts.size() < 2:
		return -1
	for pool: Array in [attack, keep, opts]:
		pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["wp"]) < int(b["wp"]))
	var replacement := Contract.new()
	replacement.mission_id = cheapest.mission_id
	replacement.enemy_percent = cheapest.enemy_percent
	replacement.objectives.assign([attack[0]["id"], keep[0]["id"]])
	replacement.offered.assign([opts[0]["id"], opts[1]["id"]])
	if replacement.cost(rules) > company.wp:
		return -1
	company.offers[index] = replacement
	return index


static func affordable_index(company: Campaign, rules: ChaosRules) -> int:
	for i in company.offers.size():
		if company.offers[i].cost(rules) <= company.wp:
			return i
	return -1


static func _pick(list: Array, rng: RandomNumberGenerator) -> String:
	return String(list[rng.randi_range(0, list.size() - 1)]["id"])
