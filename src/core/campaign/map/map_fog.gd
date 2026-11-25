class_name MapFog
extends RefCounted
## Fog of war on the campaign map: the invader sees enemy lances in or next
## to the zones its lances stand in, and within 2 zones of a lance that
## carried out a Scout order this turn (kept in MapCampaign.scouted until the
## next turn's moves). Battles reveal their zone. Key locations and who
## holds them are always known.
## TODO(rules): ours; the book leaves what each side knows to the GM. The
## computer defender sees everything.

const SCOUT_RANGE := 2


## Zones the invader can see now.
static func seen(mc: MapCampaign) -> Dictionary:
	var out := {}
	for z in mc.scouted:
		out[z] = true
	for l in mc.lances_of(0):
		if not l.on_map():
			continue
		out[l.zone] = true
		for n in mc.region.neighbors(l.zone):
			out[n] = true
	for b in mc.battles:
		out[b["zone"]] = true
	return out


## Shown to the player: its own lances, and enemy lances in seen zones.
static func shows(mc: MapCampaign, l: MapLance, seen_zones: Dictionary = {}) -> bool:
	if l.side == 0:
		return true
	return l.on_map() and (seen_zones if not seen_zones.is_empty() else seen(mc)).has(l.zone)


## After the moves: what the invader's Scout orders found.
static func scout(mc: MapCampaign) -> void:
	mc.scouted.clear()
	for l in mc.lances_of(0):
		if l.order != MapLance.SCOUT or not l.on_map() or mc.fit_mechs(l).is_empty():
			continue
		for x in mc.region.width:
			for y in mc.region.height:
				var z := Vector2i(x, y)
				if mc.region.distance(l.zone, z) <= SCOUT_RANGE and not mc.scouted.has(z):
					mc.scouted.append(z)
