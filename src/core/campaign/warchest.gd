class_name Warchest
extends RefCounted
## Warchest Points (Campaign Operations pp. 160, 173): paying for a contract,
## the one-contract debt allowance, and the payout from its objectives and
## options when the battle ends.


## Why the company can't take `k` now, or "" if it can (maybe on debt).
static func cant_take(c: Campaign, k: Contract, rules: ChaosRules) -> String:
	if c.contract != null:
		return "Finish the current contract first."
	if c.ready_mechs().is_empty():
		return "No 'Mech is ready to fight."
	if c.wp < k.cost(rules) and c.on_debt:
		return "Not enough Warchest Points, and you can't go into debt two contracts in a row."
	return ""


## Pays for `k` and makes it the company's contract. Going below zero is
## Warchest debt (p. 160).
static func take(c: Campaign, k: Contract, rules: ChaosRules) -> void:
	c.wp -= k.cost(rules)
	c.on_debt = c.wp < 0
	c.contract = k


## Scores the finished battle against the contract. Returns report lines.
static func settle(c: Campaign, rules: ChaosRules, state: GameState, side: int) -> Array[String]:
	var k := c.contract
	var out: Array[String] = []
	if k == null:
		return out
	var met: Array[String] = []
	for id in k.objectives:
		var obj := rules.objective(id)
		var ok := ChaosObjective.met(obj, state, side)
		if ok:
			met.append(id)
		out.append("%s %s (%d WP)" % ["✓" if ok else "✗", obj.get("title", id), int(obj.get("wp", 0))])
	for id in k.chosen:
		var opt := rules.option(id)
		out.append("%s option %s (%d WP)" % ["✓" if not met.is_empty() else "✗", opt.get("title", id), int(opt.get("wp", 0))])
	var pay := k.payout(rules, met)
	c.wp += pay
	out.append("Warchest: +%d WP, now %d WP." % [pay, c.wp])
	if c.wp < 0:
		out.append("The company is still in Warchest debt.")
	c.contract = null
	c.last_met = met.size()
	return out
