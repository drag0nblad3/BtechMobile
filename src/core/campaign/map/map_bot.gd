class_name MapBot
extends RefCounted
## Orders for the defending side. Garrisons hold their key location
## (Defend), lances standing on a lost location try to take it back,
## and the rest go after the nearest enemy lance or lost location: Attack
## when next to it, Move otherwise. TODO(rules): the book's GM decides.


static func orders(mc: MapCampaign, side: int = 1) -> void:
	var held := {}
	for l in mc.lances_of(side):
		var loc := mc.region.location_at(l.zone)
		var garrison := not loc.is_empty() and int(loc["owner"]) == side and not held.has(l.zone)
		if mc.fit_mechs(l).is_empty():
			MapOrders.give(mc, l, MapLance.REPAIR)
		elif garrison:
			held[l.zone] = true
			MapOrders.give(mc, l, MapLance.DEFEND)
		else:
			var goal := _goal(mc, l)
			if goal == l.zone:
				MapOrders.give(mc, l, MapLance.ATTACK)
			elif mc.region.distance(l.zone, goal) == 1:
				MapOrders.give(mc, l, MapLance.ATTACK, goal)
			else:
				MapOrders.give(mc, l, MapLance.MOVE if not l.fast_moved else MapLance.DEFEND,
						mc.region.step_toward(l.zone, goal))


## The nearest enemy lance or location the other side holds.
static func _goal(mc: MapCampaign, l: MapLance) -> Vector2i:
	var best := l.zone
	var best_d := 1 << 20
	var spots: Array[Vector2i] = []
	for o in mc.lances_of(1 - l.side):
		if o.on_map():
			spots.append(o.zone)
	for loc in mc.region.locations:
		if int(loc["owner"]) != l.side:
			spots.append(loc["zone"])
	for z in spots:
		var d := mc.region.distance(l.zone, z)
		if d < best_d:
			best = z
			best_d = d
	return best
