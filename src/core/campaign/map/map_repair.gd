class_name MapRepair
extends RefCounted
## Repairs in a map campaign (Campaign Operations pp. 148, 154): the
## simplified Repair order fixes every 'Mech and MechWarrior in the lance
## and seats Green MechWarriors where one was killed (the dead stay dead);
## a held city, capital or fortress gives a free Repair, a supply depot
## repairs armor and ammunition only. A written-off 'Mech can't be fixed.

const GREEN := Vector2i(5, 6)


static func full(mc: MapCampaign, l: MapLance) -> void:
	var c := mc.roster(l.side)
	for id in l.mech_ids:
		var m := c.mech(id)
		if m == null or m.written_off:
			continue
		m.condition = {}
		var p := c.pilot(m.pilot_id)
		if p == null or p.dead:
			p = c.add_pilot("Recruit %d" % (c.pilots.size() + 1), GREEN.x, GREEN.y)
			m.pilot_id = p.id
		p.wounds = 0


## A held key location's benefit for a lance in its zone.
static func benefit(mc: MapCampaign, l: MapLance, kind: String, db: UnitDb) -> void:
	match kind:
		"repair", "fortress":
			full(mc, l)
		"supply":
			var c := mc.roster(l.side)
			for id in l.mech_ids:
				var m := c.mech(id)
				var def := db.get_def(m.design) if m != null else null
				if def == null or m.written_off or m.condition.is_empty():
					continue
				MechRepair.apply(m, def, MechRepair.ARMOR)
				MechRepair.apply(m, def, MechRepair.AMMO)


## Every 'Mech of the lance is gone for good.
static func lost(mc: MapCampaign, l: MapLance) -> bool:
	var c := mc.roster(l.side)
	return l.mech_ids.all(func(id: String) -> bool: return c.mech(id) == null or c.mech(id).written_off)
