class_name Contract
extends RefCounted
## One Chaos Campaign track offered to the company: a standard mission, an
## enemy force sized as a percentage of the company's deployed BV, the
## Warchest objectives it pays for, and optional harder conditions
## (options) that pay extra if at least one objective is met.

var mission_id := ""
var story: Dictionary = {}  ## Fictional briefing, persisted with the offer.
var enemy_percent := 100
var objectives: Array[String] = []
var offered: Array[String] = []  ## Options the player may add.
var chosen: Array[String] = []   ## Options the player took.


## Warchest cost to take it: a share of everything it could pay (p. 173).
func cost(rules: ChaosRules) -> int:
	return int(round(max_reward(rules) * rules.cost_share()))


## Every objective plus every offered option.
func max_reward(rules: ChaosRules) -> int:
	var total := 0
	for id in objectives:
		total += int(rules.objective(id).get("wp", 0))
	for id in offered:
		total += int(rules.option(id).get("wp", 0))
	return total


## WP earned: each objective met, plus chosen options if any was met.
func payout(rules: ChaosRules, met: Array[String]) -> int:
	var total := 0
	for id in met:
		total += int(rules.objective(id).get("wp", 0))
	if not met.is_empty():
		for id in chosen:
			total += int(rules.option(id).get("wp", 0))
	return total


func to_dict() -> Dictionary:
	return {"mission": mission_id, "enemy_percent": enemy_percent, "objectives": Array(objectives),
		"offered": Array(offered), "chosen": Array(chosen), "story": story.duplicate(true)}


static func from_dict(d: Dictionary) -> Contract:
	var c := Contract.new()
	c.mission_id = String(d.get("mission", ""))
	c.story = d.get("story", {}).duplicate(true)
	c.enemy_percent = int(d.get("enemy_percent", 100))
	for k in ["objectives", "offered", "chosen"]:
		for id in d.get(k, []):
			(c.get(k) as Array).append(String(id))
	return c
