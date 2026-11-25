class_name MapBot
extends RefCounted
## Orders for the defending side. Garrisons hold their key location
## (Defend). Free lances first reinforce a held location that has more
## invading lances next to it than defenders in it (within 3 zones,
## Fast Move when 2 away); the rest go after the nearest enemy lance or
## lost location: Attack when next to it, Move otherwise.
## TODO(rules): the book's GM decides.


static func orders(mc: MapCampaign, side: int = 1) -> void:
	var held := {}
	for l in mc.lances_of(side):
		var loc := mc.region.location_at(l.zone)
		var garrison := not loc.is_empty() and int(loc["owner"]) == side and not held.has(l.zone)
		if mc.fit_mechs(l).is_empty() or (not garrison and mc.fit_mechs(l).size() * 2 < l.mech_ids.size()):
			MapOrders.give(mc, l, MapLance.REPAIR)
		elif garrison:
			held[l.zone] = true
			MapOrders.give(mc, l, MapLance.DEFEND)
		elif _reinforce(mc, l):
			pass
		else:
			var goal := _goal(mc, l)
			if goal == l.zone:
				MapOrders.give(mc, l, MapLance.ATTACK)
			elif mc.region.distance(l.zone, goal) == 1:
				MapOrders.give(mc, l, MapLance.ATTACK, goal)
			else:
				MapOrders.give(mc, l, MapLance.MOVE if not l.fast_moved else MapLance.DEFEND,
						mc.region.step_toward(l.zone, goal))


## Sends `l` to a threatened held location; false if none needs it.
static func _reinforce(mc: MapCampaign, l: MapLance) -> bool:
	if l.fast_moved:
		return false  # must rest this turn
	var best := Vector2i(-1, -1)
	var best_d := 4
	for loc in mc.region.locations:
		var z: Vector2i = loc["zone"]
		if int(loc["owner"]) != l.side or z == l.zone or mc.region.distance(l.zone, z) >= best_d:
			continue
		var threat := 0
		var guard := 0
		for o in mc.lances:
			if not o.on_map() or mc.fit_mechs(o).is_empty():
				continue
			if o.side != l.side and mc.region.distance(o.zone, z) <= 1:
				threat += 1
			elif o.side == l.side and o.zone == z:
				guard += 1
		if threat > guard:
			best = z
			best_d = mc.region.distance(l.zone, z)
	if best == Vector2i(-1, -1):
		return false
	if best_d <= 2:
		return MapOrders.give(mc, l, MapLance.FAST_MOVE if best_d == 2 else MapLance.MOVE, best) == ""
	return MapOrders.give(mc, l, MapLance.MOVE, mc.region.step_toward(l.zone, best)) == ""


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
