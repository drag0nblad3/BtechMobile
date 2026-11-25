class_name MapOperations
extends RefCounted
## App-specific linked regions, using unchanged map-campaign victory rules.
## Preserve surviving company and its condition; do not grant free repairs.


static func advance(mc: MapCampaign, db: UnitDb, rng: RandomNumberGenerator) -> bool:
	if mc.winner != 0 or not mc.battles.is_empty() or mc.operation >= int(mc.rules.get("operations", 1)):
		return false
	var ids: Array[String] = []
	for l in mc.lances_of(0):
		for id in l.mech_ids:
			var m := mc.player.mech(id)
			if m != null and not m.written_off and not ids.has(id):
				ids.append(id)
	if ids.is_empty() or mc.player.ready_mechs().is_empty():
		return false
	mc.log.append("Region %d secured on day %d (%d points)." % [mc.operation, mc.turn - 1, mc.region.points(0)])
	mc.operation += 1
	mc.region = MapRegionGen.generate(mc.rules, rng)
	mc.lances.clear()
	mc.scouted.clear()
	mc.intel.clear()
	mc.turn = 1
	mc.winner = -1
	var landing := Vector2i(mc.region.width / 2, mc.region.height - 1)
	for i in ceili(ids.size() / float(MapCampaign.LANCE)):
		mc.add_lance(0, landing, ids.slice(i * MapCampaign.LANCE, (i + 1) * MapCampaign.LANCE))
	mc._enemy_forces(db, rng)
	mc.log.append("Region %d: company deployed." % mc.operation)
	return true
