class_name ReadoutEquipmentCatalog
extends RefCounted
## Unified read-only catalog built from game definitions and actual installations.


static func build(db: WeaponDb, usage: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for w: WeaponDef in db.by_id.values():
		var item := entry("weapon:" + w.id, w.name, "Weapon / " + w.type.capitalize(), w.tech,
			"Damage %d maximum • Heat %d • Range %s\n%.2f tons • %d slots • BV %d • Ammo/ton %d" % [w.max_damage(), w.heat, w.range_text(), w.tons, w.slots, w.bv, w.ammo_per_ton])
		item["ammo"] = w.uses_ammo()
		out.append(item)
		if w.uses_ammo():
			out.append(ammo(w, ""))
		for kind: String in w.munitions:
			out.append(ammo(w, kind))
	var data: Dictionary = JsonFile.read("res://data/readout_equipment.json")
	for row: Dictionary in data.get("entries", []):
		out.append(row)
	for id: String in ActiveProbe.KINDS:
		var k: Dictionary = ActiveProbe.KINDS[id]
		out.append(entry(id, k["name"], "Electronics", "clan" if id.begins_with("c_") else "inner_sphere",
			"%s t • %d slots • %d hexes\nCounters certain visibility modifiers within range; hostile ECM can interfere." % [k["tons"], k["slots"], k["range"]]))
	for id: String in EcmTypes.KINDS:
		var k: Dictionary = EcmTypes.KINDS[id]
		for tech: String in ["inner_sphere", "clan"]:
			var clan := tech == "clan"
			if id == "watchdog_ecm" and not clan:
				continue
			out.append(entry(id + (":clan" if clan else ":is"), k["name"], "Electronics", tech,
				"%s t • %d slots • BV %d\nElectronic countermeasures; disrupts affected hostile electronic systems.%s" % [k["clan_tons" if clan else "tons"], k["clan_slots" if clan else "slots"], k["bv"], "\nIntegrated probe: %d hexes" % k["probe"] if k.has("probe") else ""]))
	for id: String in InertGear.KINDS:
		var k: Dictionary = InertGear.KINDS[id]
		var note := "Carried equipment; its dedicated combat effect is not implemented." if id == "a_pod" else "Target designation system for supported attacks."
		out.append(entry(id, k["name"], "Electronics" if id != "a_pod" else "Protection", "clan" if id.begins_with("c_") else "inner_sphere",
			"%s t • %d slots\n%s" % [k["tons"], k["slots"], note]))
	for id: String in ArmorTypes.KINDS:
		var k: Dictionary = ArmorTypes.KINDS[id]
		out.append(entry("armor:" + id, k["name"] + " Armor", "Armor", "both",
			"%s\nConstruction checker: %g%% of standard armor points per ton." % [k["about"], float(k["mult"]) * 100.0]))
	for id: String in StructureTypes.KINDS:
		var k: Dictionary = StructureTypes.KINDS[id]
		var note := "Damage consumes two structure points per point." if id == "composite" else "Each structure point absorbs two damage." if id == "reinforced" else "Weight-saving internal structure."
		out.append(entry("structure:" + id, k["name"] + " Structure", "Structure", "both",
			"%s\nConstruction checker: %g%% of standard structure weight." % [note, float(k["mult"]) * 100.0]))
	for id: String in Gyro.SLOTS:
		out.append(entry("gyro:" + id, id.capitalize() + " Gyro", "Gyro", "both",
			"%d slots • %g%% of standard gyro weight before rounding.\nWeight depends on engine rating." % [Gyro.SLOTS[id], float(Gyro.WEIGHT[id]) * 100.0]))
	var known := {}
	for item: Dictionary in out:
		known[item["id"]] = true
	for id: String in usage:
		if known.has(id):
			continue
		if id.begins_with("ammo:"):
			var parts := id.split(":")
			var w := db.get_def(parts[1])
			if w != null:
				out.append(ammo(w, parts[2]))
				continue
		# Keep any newly encountered installed system browsable, even if no stats are available.
		out.append(entry(id, id.replace(":", " ").capitalize(), "Other equipment", "both",
			"Present in the catalog. Detailed specifications are not yet documented here."))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var cmp := String(a["name"]).naturalnocasecmp_to(String(b["name"]))
		return cmp < 0 if cmp != 0 else String(a["id"]) < String(b["id"]))
	return out


static func entry(id: String, label: String, category: String, tech: String, about: String) -> Dictionary:
	return {"id": id, "name": label, "category": category, "tech": tech, "about": about}


static func ammo(w: WeaponDef, kind: String) -> Dictionary:
	var profile: WeaponDef = w.munitions.get(kind, w)
	var label := "Standard" if kind.is_empty() else (profile.label if not profile.label.is_empty() else kind.capitalize())
	var about := "Ammunition for " + w.name + "."
	if kind.is_empty() or w.munitions.has(kind):
		about += "\n%d rounds per ton • Ammo BV/ton %d" % [profile.ammo_per_ton, profile.ammo_bv]
	else:
		about += "\nSpecial ammunition recorded on an official design; subtype-specific stats not shown."
	return entry(ReadoutEquipmentUsage.ammo_id(w, kind), w.name + " Ammo (" + label + ")", "Ammunition", w.tech, about)


static func categories(entries: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for item: Dictionary in entries:
		var category := String(item["category"])
		if not out.has(category):
			out.append(category)
	out.sort()
	out.push_front("Any category")
	return out


static func matches(item: Dictionary, query: String, filters: Dictionary) -> bool:
	var category := String(filters.get("category", ""))
	if not category.is_empty() and item["category"] != category:
		return false
	var tech := int(filters.get("tech", 0))
	if tech == 1 and item["tech"] not in ["inner_sphere", "both"]:
		return false
	if tech == 2 and item["tech"] not in ["clan", "both"]:
		return false
	var ammo_mode := int(filters.get("ammo", 0))
	if ammo_mode > 0 and (not item.has("ammo") or bool(item["ammo"]) != (ammo_mode == 1)):
		return false
	var text := ("%s %s %s %s %s" % [item["name"], item["id"], item["category"], item["tech"], item["about"]]).to_lower().replace("_", " ")
	for word in query.strip_edges().to_lower().split(" ", false):
		if not text.contains(word):
			return false
	return true
