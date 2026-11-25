class_name MapFactory
extends RefCounted
## Factory and Seaport key locations (Campaign Operations p. 152 sample
## table). A Factory the invader holds at the end of a turn builds one free
## 'Mech, once per campaign: it joins a lance there with room, or forms a
## new lance; a Factory also repairs like a city. A lance on a Seaport its
## side holds may Move straight to the other held Seaport, however far.
## TODO(rules): the book's "one level below the formation size" is read as
## one 'Mech, built from data/campaign/map_campaign.json `factory_designs`
## by a Green MechWarrior; only the invader's factory production counts.


## Builds the free 'Mech where due; returns the news.
static func produce(mc: MapCampaign, db: UnitDb) -> Array[String]:
	var news: Array[String] = []
	var designs: Array = mc.rules.get("factory_designs", [])
	for loc in mc.region.locations:
		if loc["benefit"] != "factory" or int(loc["owner"]) != 0 or loc.get("produced", false) or designs.is_empty():
			continue
		var design := String(designs[mc.turn % designs.size()])
		if db.get_def(design) == null:
			continue
		loc["produced"] = true
		var p := mc.player.add_pilot("Recruit %d" % (mc.player.pilots.size() + 1), MapRepair.GREEN.x, MapRepair.GREEN.y)
		var m := mc.player.add_mech(design)
		m.pilot_id = p.id
		var home := _lance_with_room(mc, loc["zone"])
		if home == null:
			mc.add_lance(0, loc["zone"], [m.id])
		else:
			home.mech_ids.append(m.id)
		var def := db.get_def(design)
		news.append("%s builds a %s %s for you." % [loc["name"], def.name, def.model])
	return news


## Moving from one held Seaport to another.
static func sea_route(mc: MapCampaign, l: MapLance, target: Vector2i) -> bool:
	return target != l.zone and _port(mc, l.zone, l.side) and _port(mc, target, l.side)


static func _port(mc: MapCampaign, z: Vector2i, side: int) -> bool:
	var loc := mc.region.location_at(z)
	return not loc.is_empty() and loc["benefit"] == "seaport" and int(loc["owner"]) == side


static func _lance_with_room(mc: MapCampaign, z: Vector2i) -> MapLance:
	for l in mc.lances_of(0):
		if l.zone == z and l.mech_ids.filter(func(id: String) -> bool: return not mc.player.mech(id).written_off).size() < MapCampaign.LANCE:
			return l
	return null
