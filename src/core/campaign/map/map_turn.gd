class_name MapTurn
extends RefCounted
## One Strategic Turn (Campaign Operations pp. 148-154). `start` carries
## out the orders: moves, Repair orders, then pairs up opposing lances that
## share a zone into battles. Once those are fought, `finish` hands key
## locations to the side left alone in their zone, applies location
## benefits, and checks for a winner: the invader wins with 80% of the
## points; the defender wins if no invading lance can fight or the turn
## limit passes (our pick for the book's stalemate).
## Moves go one zone at a time for everyone at once: a lance stops when it
## enters a zone holding an enemy lance that can fight, and two enemy lances
## that swap zones meet where the defender's lance stood.
## TODO(rules): our reading of simultaneous movement; a lance with no 'Mech
## able to fight is overrun by an enemy lance in its zone.


static func start(mc: MapCampaign, dice: Dice) -> Array[Dictionary]:
	MapDrop.fly(mc)
	_move(mc)
	MapFog.scout(mc)
	MapIntelligence.observe(mc)
	for l in mc.lances:
		if l.order == MapLance.REPAIR:
			MapRepair.full(mc, l)
	mc.battles.clear()
	for z in _zones(mc):
		var mine := _fighting(mc, z, 0)
		var theirs := _fighting(mc, z, 1)
		_overrun(mc, z, mine, theirs)
		for i in mini(mine.size(), theirs.size()):
			var att := ScenarioTable.attacker(mine[i], theirs[i], dice)
			var s := ScenarioTable.roll(mine[i], theirs[i], dice, mc.rules)
			s["zone"] = z
			s["attacker"] = att.id
			s["defender"] = (theirs[i] if att == mine[i] else mine[i]).id
			s["mission"] = ScenarioTable.mission_for(s["scenario"], mc.rules)
			mc.battles.append(s)
	return mc.battles


static func finish(mc: MapCampaign, db: UnitDb) -> Array[String]:
	var news: Array[String] = []
	mc.lances = mc.lances.filter(func(l: MapLance) -> bool: return not MapRepair.lost(mc, l))
	for loc in mc.region.locations:
		var z: Vector2i = loc["zone"]
		var here := [_fighting(mc, z, 0).size() > 0, _fighting(mc, z, 1).size() > 0]
		for side in 2:
			if here[side] and not here[1 - side] and int(loc["owner"]) != side:
				loc["owner"] = side
				news.append("%s takes %s (%d point%s)." % [Names.side(side), loc["name"], loc["points"], "" if int(loc["points"]) == 1 else "s"])
		for l in mc.lances:
			if l.zone == z and l.side == int(loc["owner"]):
				MapRepair.benefit(mc, l, String(loc["benefit"]), db)
	news.append_array(MapFactory.produce(mc, db))
	for l in mc.lances:
		if not l.on_map():
			continue  # still in the air: keeps its DropShip Move
		l.fast_moved = l.order == MapLance.FAST_MOVE
		l.order = MapLance.DEFEND
		l.target = l.zone
	mc.winner = winner(mc)
	mc.turn += 1
	mc.log.append_array(news)
	MapIntelligence.observe(mc)
	return news


static func winner(mc: MapCampaign) -> int:
	var need := ceili(mc.region.total_points() * float(mc.rules.get("victory_share", 0.8)))
	if mc.region.points(0) >= need or mc.lances_of(1).all(func(l: MapLance) -> bool: return mc.fit_mechs(l).is_empty()):
		return 0
	if mc.lances_of(0).all(func(l: MapLance) -> bool: return mc.fit_mechs(l).is_empty()):
		return 1
	if mc.turn >= int(mc.rules.get("turn_limit", 20)):
		return 1
	return -1


## Everyone steps one zone at a time; contact with the enemy stops both.
static func _move(mc: MapCampaign) -> void:
	var left := {}
	for l in mc.lances:
		var going := l.on_map() and l.reach() > 0 and mc.region.has_zone(l.target)
		left[l.id] = l.reach() if going else 0
		if going and MapFactory.sea_route(mc, l, l.target):
			l.zone = l.target  # across the water, port to port
			left[l.id] = 0
	for step in 2:
		var before := {}
		for l in mc.lances:
			before[l.id] = l.zone
			if int(left[l.id]) > step and l.zone != l.target:
				l.zone = mc.region.step_toward(l.zone, l.target)
		for l in mc.lances:
			if l.zone == before[l.id] or mc.fit_mechs(l).is_empty():
				continue
			for o in mc.lances:
				if o.side == l.side or not o.on_map() or mc.fit_mechs(o).is_empty():
					continue
				if o.zone == l.zone:
					left[l.id] = 0
					left[o.id] = 0
				elif o.zone == before[l.id] and before[o.id] == l.zone:  # swapped: meet on the defender's ground
					var ground: Vector2i = before[o.id] if o.side == 1 else before[l.id]
					l.zone = ground
					o.zone = ground
					left[l.id] = 0
					left[o.id] = 0


## Lances of `side` in `z` with at least one 'Mech that can fight.
static func _fighting(mc: MapCampaign, z: Vector2i, side: int) -> Array[MapLance]:
	var out: Array[MapLance] = []
	for l in mc.lances:
		if l.side == side and l.zone == z and not mc.fit_mechs(l).is_empty():
			out.append(l)
	return out


## Lances that can't fight, caught in a zone with the enemy, are lost.
static func _overrun(mc: MapCampaign, z: Vector2i, mine: Array, theirs: Array) -> void:
	for l in mc.lances:
		var foes: Array = theirs if l.side == 0 else mine
		if l.zone == z and not foes.is_empty() and mc.fit_mechs(l).is_empty():
			for id in l.mech_ids:
				mc.roster(l.side).mech(id).written_off = true


static func _zones(mc: MapCampaign) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for l in mc.lances:
		if l.on_map() and not out.has(l.zone):
			out.append(l.zone)
	return out
