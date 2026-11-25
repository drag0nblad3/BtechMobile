class_name MapOrders
extends RefCounted
## Giving a lance its order for the turn (Campaign Operations p. 148), with
## the reasons an order can't be given.


## Why `l` can't take `order` toward `target`, or "".
static func why_not(mc: MapCampaign, l: MapLance, order: String, target: Vector2i) -> String:
	var why := can_take(mc, l, order)
	if why != "":
		return why
	if order == MapLance.DROPSHIP:
		return "Tap the zone to fly to." if target == l.zone or not mc.region.has_zone(target) else ""
	var probe := MapLance.new()
	probe.order = order
	var reach := probe.reach()
	if reach > 0 and target != l.zone:
		if not mc.region.has_zone(target):
			return "That zone isn't on the map."
		if order == MapLance.MOVE and MapFactory.sea_route(mc, l, target):
			return ""
		if mc.region.distance(l.zone, target) > reach:
			return "Too far: %s reaches %d zone%s." % [MapLance.NAMES[order], reach, "" if reach == 1 else "s"]
	return ""


## Why `l` can't take `order` at all this turn (wherever it goes), or "".
static func can_take(mc: MapCampaign, l: MapLance, order: String) -> String:
	if not MapLance.ORDERS.has(order):
		return "Unknown order."
	if not l.on_map():
		return "%s is in the air until its DropShip lands." % l.name
	if order == MapLance.DROPSHIP:
		return MapDrop.why_not(mc, l)
	if order == MapLance.MOVE and l.fast_moved:
		return "%s made a Fast Move last turn and can't take a Move order now." % l.name
	if mc.fit_mechs(l).is_empty() and MapLance.COMBAT.has(order) and order != MapLance.DEFEND:
		return "%s has no 'Mech able to fight." % l.name
	return ""


static func give(mc: MapCampaign, l: MapLance, order: String, target: Vector2i = Vector2i(-1, -1)) -> String:
	var t := target if target != Vector2i(-1, -1) else l.zone
	var why := why_not(mc, l, order, t)
	if why == "":
		l.order = order
		l.target = t
	return why
