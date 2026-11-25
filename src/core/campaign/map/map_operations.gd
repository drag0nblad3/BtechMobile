class_name MapOperations
extends RefCounted
## GM-style campaign configuration and intelligence. No new combat or repair rules.


## Strict catalog selection is optional; an empty verified pool blocks setup.
static func historic_pool(db: UnitDb, rules: Dictionary, side: int) -> Array[UnitDef]:
	var out: Array[UnitDef] = []
	var availability := EraAvailability.new()
	var year := int(rules.get("era_year", 3025))
	var factions: Array = rules.get("factions", ["mercenary", "draconis_combine"])
	for def: UnitDef in db.by_id.values():
		if def.is_support() or def.id.begins_with("test_"):
			continue
		if availability.check(def.id, year, String(factions[side])).get("status") == "available":
			out.append(def)
	out.sort_custom(func(a: UnitDef, b: UnitDef) -> bool: return a.id < b.id)
	return out


static func historic_roster(db: UnitDb, rules: Dictionary, rng: RandomNumberGenerator) -> bool:
	if not rules.get("historical", false):
		return true
	var mine := historic_pool(db, rules, 0)
	var foe := historic_pool(db, rules, 1)
	if mine.is_empty() or foe.is_empty():
		return false
	var roster: Array = rules["starting_company"]
	var allowed := {}
	for d in mine:
		allowed[d.id] = true
	for entry: Dictionary in roster:
		if not allowed.has(entry["design"]):
			entry["design"] = mine[rng.randi_range(0, mine.size() - 1)].id
	var factory: Array[String] = []
	for d in mine:
		factory.append(d.id)
	rules["factory_designs"] = Array(factory)
	return true


static func pick_force(fb: ForceBuilder, target: int, rng: RandomNumberGenerator, pool: Array) -> Array[String]:
	var best: Array[String] = []
	if pool.is_empty():
		return best
	var gap := 1 << 30
	for attempt in 80:
		var ids: Array[String] = []
		var bv := 0
		for slot in MapCampaign.LANCE:
			var def: UnitDef = pool[rng.randi_range(0, pool.size() - 1)]
			ids.append(def.id)
			bv += fb.unit_bv(1, def)
		if absi(bv - target) < gap:
			gap = absi(bv - target)
			best = ids
	return best


static func observe(mc: MapCampaign) -> void:
	var seen := MapFog.seen(mc)
	for z: Vector2i in seen:
		var count := 0
		var ready := 0
		for l in mc.lances_of(1):
			if l.on_map() and l.zone == z:
				count += 1
				ready += mc.fit_mechs(l).size()
		mc.intel[key(z)] = {"day": mc.turn, "lances": count, "ready": ready}


static func key(z: Vector2i) -> String:
	return "%d,%d" % [z.x, z.y]


static func should_repair(mc: MapCampaign, l: MapLance) -> bool:
	if not l.on_map():
		return false
	var damaged := 0
	for id in l.mech_ids:
		var m := mc.roster(l.side).mech(id)
		if m != null and not m.written_off and m.damaged():
			damaged += 1
	if damaged == 0 or damaged * 2 < l.mech_ids.size():
		return false
	for foe in mc.lances_of(1 - l.side):
		if foe.on_map() and not mc.fit_mechs(foe).is_empty() and mc.region.distance(l.zone, foe.zone) <= 1:
			return false
	return true


## Reassign intact formations only while co-located and not fighting or flying.
static func swap_mechs(mc: MapCampaign, a: MapLance, aid: String, b: MapLance, bid: String) -> bool:
	if not mc.battles.is_empty() or mc.winner >= 0 or a == b or a.side != 0 or b.side != 0 or not a.on_map() or a.zone != b.zone:
		return false
	if not a.mech_ids.has(aid) or not b.mech_ids.has(bid):
		return false
	a.mech_ids[a.mech_ids.find(aid)] = bid
	b.mech_ids[b.mech_ids.find(bid)] = aid
	return true


static func swap_pilots(mc: MapCampaign, a: CampaignMech, b: CampaignMech) -> bool:
	if not mc.battles.is_empty() or mc.winner >= 0 or a == b or a.written_off or b.written_off:
		return false
	var la: MapLance
	var lb: MapLance
	for l in mc.lances_of(0):
		if l.mech_ids.has(a.id):
			la = l
		if l.mech_ids.has(b.id):
			lb = l
	if la == null or lb == null or not la.on_map() or la.zone != lb.zone:
		return false
	var pa := mc.player.pilot(a.pilot_id)
	var pb := mc.player.pilot(b.pilot_id)
	if pa == null or pb == null or not pa.can_fight() or not pb.can_fight():
		return false
	var old := a.pilot_id
	a.pilot_id = b.pilot_id
	b.pilot_id = old
	return true


## Optional linked operation: preserve survivors, damage, and records. A new
## region is a new GM-defined campaign, not an automatic tabletop reward.
static func next_region(mc: MapCampaign, db: UnitDb, rng: RandomNumberGenerator) -> bool:
	if mc.winner != 0 or not mc.battles.is_empty() or mc.player.ready_mechs().is_empty():
		return false
	mc.log.append("Operation %d won. Company redeployed." % mc.operation)
	mc.operation += 1
	mc.region = MapRegionGen.generate(mc.rules, rng)
	mc.lances = mc.lances_of(0)
	var landing := Vector2i(mc.region.width / 2, mc.region.height - 1)
	for l in mc.lances:
		l.zone = landing
		l.target = landing
		l.order = MapLance.DEFEND
		l.fast_moved = false
		l.transit = 0
	mc.turn = 1
	mc.winner = -1
	mc.scouted.clear()
	mc.intel.clear()
	mc._enemy_forces(db, rng)
	observe(mc)
	return true
