class_name MapIntelligence
extends RefCounted
## Optional GM-style last-known observations. Only update visible zones;
## do not consult unseen formations when presenting a stale contact.


static func observe(mc: MapCampaign) -> void:
	var seen := MapFog.seen(mc)
	for z: Vector2i in seen:
		var count := 0
		var fit := 0
		for l in mc.lances_of(1):
			if l.zone == z and l.on_map():
				count += 1
				fit += mc.fit_mechs(l).size()
		mc.intel[key(z)] = {"day": mc.turn, "lances": count, "fit": fit}


static func key(z: Vector2i) -> String:
	return "%d,%d" % [z.x, z.y]


static func report(mc: MapCampaign, z: Vector2i) -> String:
	var observation: Dictionary = mc.intel.get(key(z), {})
	if observation.is_empty():
		return "Unobserved"
	var current := MapFog.seen(mc).has(z)
	return "%s: %d enemy lances, %d fit Mechs (day %d)" % [
		"Observed" if current else "Last known, not confirmed",
		observation["lances"], observation["fit"], observation["day"]]
