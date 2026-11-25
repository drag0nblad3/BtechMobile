class_name IntroTech
extends RefCounted
## Introductory Rules technology (Campaign Operations p. 163): a 'Mech
## built only from the Introductory Rules Equipment Table rearms and is
## bought for fewer Support Points than a Standard Rules one.
## TODO(rules): Advanced/Experimental ammo (50 SP to rearm) isn't told
## apart; everything that isn't Introductory counts as Standard.

const STANDARD_PARTS := ["engine_type", "gyro_type", "cockpit_type", "structure_type", "armor_type"]
const NO_GEAR := ["ecm_loc", "masc_loc", "supercharger_loc", "tc_loc", "c3_master_loc", "c3_slave_loc", "c3i_loc"]


static func is_intro(def: UnitDef, rules: ChaosRules) -> bool:
	if def.is_clan() or def.omni or def.double_heat_sinks or def.jump_jet_type != "" or def.probe != "":
		return false
	for k: String in STANDARD_PARTS:
		if String(def.get(k)) != "standard":
			return false
	for k: String in NO_GEAR:
		if int(def.get(k)) >= 0:
			return false
	if not (def.case_locs.is_empty() and def.case2_locs.is_empty() and def.inert.is_empty() and def.bulk_slots.is_empty()):
		return false
	var weapons: Array = rules.support().get("intro_weapons", [])
	for w: Dictionary in def.weapon_mounts:
		if not weapons.has(w["weapon"].id) or w["artemis"] or w["artemis_v"] or w["apollo"] or w["capacitor"]:
			return false
	for a: Dictionary in def.ammo_mounts:
		if not weapons.has(a["weapon"].id) or String(a["kind"]) != "":
			return false
	var melee: Array = rules.support().get("intro_melee", [])
	for m: Dictionary in def.melee:
		if not melee.has(m["kind"]):
			return false
	return true
