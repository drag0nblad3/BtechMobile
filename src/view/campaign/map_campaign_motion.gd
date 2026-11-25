class_name MapCampaignMotion
extends RefCounted
## Presentation-only transitions from observations before/after a day.
## Never reveal an unseen enemy endpoint or movement.


static func snapshot(mc: MapCampaign) -> Dictionary:
	var positions := {}
	var visible := MapFog.seen(mc)
	for l in mc.lances:
		if l.on_map() and MapFog.shows(mc, l, visible):
			positions[l.id] = {"zone": l.zone, "side": l.side}
	var owners := {}
	for loc in mc.region.locations:
		owners[loc["id"]] = int(loc["owner"])
	return {"positions": positions, "owners": owners}


static func changes(mc: MapCampaign, before: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var visible := MapFog.seen(mc)
	for l in mc.lances:
		if not l.on_map() or not MapFog.shows(mc, l, visible):
			continue
		var old: Dictionary = before["positions"].get(l.id, {})
		if not old.is_empty() and old["zone"] != l.zone:
			out.append({"from": old["zone"], "to": l.zone, "side": l.side})
	for loc in mc.region.locations:
		if int(before["owners"].get(loc["id"], loc["owner"])) != int(loc["owner"]):
			out.append({"from": loc["zone"], "to": loc["zone"], "side": loc["owner"]})
	return out
