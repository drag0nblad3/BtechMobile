class_name DesignItems
extends RefCounted
## Reads one equipment entry of a design file into a UnitDef.
## Items: "<weapon id>", "<weapon id>@rear", "<launcher>+artemis",
## "<MRM>+apollo" (Apollo), "<PPC>+capacitor" (PpcCapacitor),
## "<weapon id>~N" (its last N slots sit in the next location in, as on
## official sheets: an arm's AC/20 spilling into the side torso),
## "ammo:<weapon id>", "ammo:<weapon id>:cluster" (or ":narc"; ":half" for
## a half-ton bin), "heat_sink", "jump_jet",
## "case", "hatchet", "sword", "endo_steel", "ferro_fibrous", "tsm",
## "targeting_computer", "guardian_ecm", "masc", "supercharger", "c3_master",
## "c3_slave", "c3bs_master", "c3bs_slave" (C3Boosted), "c3i" (C3i), "angel_ecm", "watchdog_ecm" (EcmTypes), "beagle_probe", "c_active_probe", "c_light_active_probe",
## "a_pod", "tag", "c_tag", "c_light_tag" (InertGear, Tag), "case2" (CASE II).
## In the file, "<item>*N" repeats an item N times.

## Bulky slots: structure, armor and myomer that only take up space.
const BULK := ["endo_steel", "ferro_fibrous", "light_ferro", "heavy_ferro", "tsm", "endo_composite",
		"ferro_lamellor", "reflective", "reactive", "ballistic_reinforced", "anti_penetrative",
		"impact_resistant", "heat_dissipating", "stealth"]

## One-per-'Mech items stored as a location: item -> UnitDef property.
const LOC_ITEMS := {"guardian_ecm": "ecm_loc", "targeting_computer": "tc_loc", "masc": "masc_loc",
		"supercharger": "supercharger_loc", "c3_master": "c3_master_loc", "c3_slave": "c3_slave_loc",
		"c3bs_master": "c3_master_loc", "c3bs_slave": "c3_slave_loc", "c3i": "c3i_loc",
		"angel_ecm": "ecm_loc", "watchdog_ecm": "ecm_loc"}


static func add(def: UnitDef, loc: int, item: String, weapons: WeaponDb) -> void:
	if item in BULK:
		_append(def.bulk_slots, loc, item)
	elif InertGear.KINDS.has(item):
		def.inert.append({"kind": item, "loc": loc})
	elif ActiveProbe.KINDS.has(item):
		def.probe = item
		def.probe_loc = loc
	elif LOC_ITEMS.has(item):
		def.set(LOC_ITEMS[item], loc)
		if item.begins_with("c3bs_"):
			def.c3_boosted = true
		if item.ends_with("_ecm"):
			def.ecm_type = item
	elif item == "case":
		def.case_locs.append(loc)
	elif item == "case2":
		def.case2_locs.append(loc)
	elif item == "hatchet" or item == "sword":
		def.melee.append({"kind": item, "loc": loc})
	elif item == "heat_sink" or item == "jump_jet":
		_append(def.other_items, loc, item)
	elif item.begins_with("ammo:"):
		var ap := Array(item.substr(5).split(":"))
		var half := ap.has("half")  # a half-ton bin: half the shots, half the weight
		ap.erase("half")
		var aw := _weapon(def, weapons, ap[0])
		def.ammo_mounts.append({"weapon": aw, "loc": loc, "kind": ap[1] if ap.size() > 1 else "", "half": half})
	else:
		var spill := item.split("~")
		var artemis := spill[0].ends_with("+artemis")
		var apollo := spill[0].ends_with("+apollo")
		var cap := spill[0].ends_with("+capacitor")
		var parts := spill[0].trim_suffix("+artemis").trim_suffix("+apollo").trim_suffix("+capacitor").split("@")
		def.weapon_mounts.append({"weapon": _weapon(def, weapons, parts[0]), "loc": loc,
				"rear": parts.size() > 1, "artemis": artemis, "apollo": apollo, "capacitor": cap, "spill": int(spill[1]) if spill.size() > 1 else 0})


static func _weapon(def: UnitDef, weapons: WeaponDb, id: String) -> WeaponDef:
	assert(weapons != null, "%s: equipment needs a WeaponDb" % def.id)
	var w := weapons.get_def(id)
	assert(w != null, "%s: unknown weapon %s" % [def.id, id])
	return w


static func _append(d: Dictionary, loc: int, item: String) -> void:
	if not d.has(loc):
		d[loc] = []
	d[loc].append(item)
