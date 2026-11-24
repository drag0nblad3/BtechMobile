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


static func _pick(list: Array, rng: RandomNumberGenerator) -> String:
	return String(list[rng.randi_range(0, list.size() - 1)]["id"])
