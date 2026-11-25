class_name CampaignStory
extends RefCounted
## Fictional GM-style campaign flavor, based only on known player state.
## No combat, market, contract or strategic RNG is consumed.

const PATH := "res://data/campaign/story.json"

static func offer(c: Campaign, k: Contract, index: int) -> Dictionary:
	var data: Dictionary = JsonFile.read(PATH)
	var employers: Array = data["employers"]
	var rivals: Array = data["rivals"]
	var locations: Array = data["locations"]
	var seed_value := int(hash([c.name, floori(c.battles / 3.0)])) & 0x7fffffff
	var employer := String(employers[(seed_value + index) % employers.size()])
	var rival := String(rivals[seed_value % rivals.size()])
	var site := String(locations[(seed_value + c.battles + index) % locations.size()])
	var hook := String(data["hooks"].get(k.mission_id, "Complete the assigned combat objectives."))
	var context := "The employer is opening a new operation."
	if c.battles > 0:
		context = "The employer has reviewed your last contract."
		if c.last_met > 0:
			context = "Reports of your last successful objectives have reached the employer."
		elif c.last_met == 0:
			context = "The employer is requesting a recovery operation after your last setback."
	return {"title": "%s: %s" % [employer, site],
		"briefing": "%s Intelligence names %s as a possible opponent, not a confirmed roster. %s" % [context, rival, hook]}


static func outcome(k: Contract, won: bool, met: int) -> String:
	if k.story.is_empty():
		return ""
	return "%s — %s; %d contract objectives met." % [k.story["title"], "field victory" if won else "field defeat", met]


static func dispatch(mc: MapCampaign) -> String:
	var data: Dictionary = JsonFile.read(PATH)
	var lines: Array = data["dispatch"]
	var i := (mc.operation + mc.turn) % lines.size()
	var ready := mc.player.ready_mechs().size()
	var capital := ""
	if not mc.region.locations.is_empty():
		capital = String(mc.region.locations[0].get("name", ""))
	var situation := "Establish a foothold before committing the main force."
	var held := mc.region.points(0)
	var target := ceili(mc.region.total_points() * float(mc.rules.get("victory_share", 0.8)))
	if mc.winner == 0:
		situation = "Regional objectives secured. Prepare the next deployment."
	elif mc.winner == 1:
		situation = "Regional operation closed. Review the company losses and results."
	elif ready <= 4:
		situation = "Readiness is low. Prioritize recovery and concentrate fit formations."
	elif held > 0 and held * 2 >= target:
		situation = "Maintain captured positions while preparing the final advance."
	elif held > 0:
		situation = "The foothold is established; expand control without overextending."
	return "Operations briefing · %s · %d ready 'Mechs. %s %s" % [capital, ready, situation, lines[i]]
