class_name ReadoutEquipmentUsage
extends RefCounted
## Actual equipment installations in official catalog designs, not refit legality.


static func ammo_id(w: WeaponDef, kind: String = "") -> String:
	return "ammo:" + w.id + ":" + kind


static func ids(d: UnitDef) -> Array[String]:
	var out: Array[String] = []
	for m: Dictionary in d.weapon_mounts:
		var w: WeaponDef = m["weapon"]
		out.append("weapon:" + w.id)
		for key: String in ["artemis", "artemis_v", "apollo", "capacitor"]:
			if m.get(key, false):
				out.append(key)
	for a: Dictionary in d.ammo_mounts:
		var w: WeaponDef = a["weapon"]
		out.append(ammo_id(w, String(a.get("kind", ""))))
	for gear: Dictionary in d.inert:
		out.append(String(gear["kind"]))
	if d.probe != "":
		out.append(d.probe)
	if d.ecm_loc >= 0:
		out.append(d.ecm_type + (":clan" if d.clan_part("ecm") else ":is"))
	for key: String in ["targeting_computer", "masc", "supercharger", "c3i"]:
		if int(d.get(DesignItems.LOC_ITEMS[key])) >= 0:
			out.append(key)
	if d.c3_master_loc >= 0:
		out.append("c3bs_master" if d.c3_boosted else "c3_master")
	if d.c3_slave_loc >= 0:
		out.append("c3bs_slave" if d.c3_boosted else "c3_slave")
	if not d.case_locs.is_empty():
		out.append("case")
	if not d.case2_locs.is_empty():
		out.append("case2")
	for m: Dictionary in d.melee:
		out.append(String(m["kind"]))
	if Tsm.has(d):
		out.append("tsm")
	if not d.is_support():
		if d.is_clan():
			out.append("case_builtin")
		out.append("armor:" + d.armor_type)
		out.append("structure:" + d.structure_type)
		out.append("engine:" + d.engine_type)
		out.append("gyro:" + d.gyro_type)
		out.append("cockpit:" + d.cockpit_type)
		out.append("double_heat_sink" if d.double_heat_sinks else "heat_sink")
		if d.jump_mp > 0:
			out.append("improved_jump_jet" if JumpJets.improved(d) else "jump_jet")
	return out


static func index(entries: Array[UnitDef]) -> Dictionary:
	var result := {}
	for d: UnitDef in entries:
		for id: String in ids(d):
			if not result.has(id):
				result[id] = []
			var users: Array = result[id]
			if not users.has(d):
				users.append(d)
	return result
