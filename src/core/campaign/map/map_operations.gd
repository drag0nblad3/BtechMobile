class_name MapOperations
extends RefCounted
## App-specific linked regions, using unchanged map-campaign victory rules.
## Preserve surviving company and its condition; do not grant free repairs.


static func advance(mc: MapCampaign, db: UnitDb, rng: RandomNumberGenerator) -> bool:
	if mc.winner != 0 or not mc.battles.is_empty() or mc.operation >= int(mc.rules.get("operations", 1)):
		return false
	var survivors: Array[MapLance] = []
	for l in mc.lances_of(0):
		if not MapRepair.lost(mc, l):
			survivors.append(l)
	if survivors.is_empty() or mc.player.ready_mechs().is_empty():
		return false
	mc.log.append("Region %d secured on day %d (%d points)." % [mc.operation, mc.turn - 1, mc.region.points(0)])
	mc.operation += 1
	mc.region = MapRegionGen.generate(mc.rules, rng)
	mc.lances = survivors
	mc.scouted.clear()
	mc.intel.clear()
	mc.turn = 1
	mc.winner = -1
	var landing := Vector2i(mc.region.width / 2, mc.region.height - 1)
	for l in survivors:
		l.zone = landing
		l.target = landing
		l.order = MapLance.DEFEND
		l.fast_moved = false
		l.transit = 0
	mc._enemy_forces(db, rng)
	MapIntelligence.observe(mc)
	mc.log.append("Region %d: company deployed." % mc.operation)
	return true
