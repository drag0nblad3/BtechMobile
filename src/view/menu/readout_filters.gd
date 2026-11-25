class_name ReadoutFilters
extends RefCounted
## Combinable catalog filters and compact filter controls. Read-only data.

const KINDS := ["All units", "BattleMechs", "Vehicles", "Battle armor", "Support assets"]
const WEIGHTS := ["Any weight", "Light", "Medium", "Heavy", "Assault"]
const TECH := ["Any tech", "Inner Sphere", "Clan", "Mixed tech"]
const BV := ["Any BV", "Under 1000", "1000–1499", "1500–1999", "2000+"]
const SORT := ["Name A–Z", "BV ↑", "BV ↓", "Tons ↑", "Tons ↓"]
const AMMO := ["Any ammo", "Uses ammo", "No ammo bins"]


static func role(d: UnitDef) -> String:
	var published := String(d.source.get("role", "")).strip_edges()
	if published.is_empty():
		published = d.role.get_slice(":", 0).strip_edges()
	return published if published.length() <= 36 else ""


static func roles(entries: Array[UnitDef]) -> Array[String]:
	var out: Array[String] = []
	for d: UnitDef in entries:
		var value := role(d)
		if not value.is_empty() and not out.has(value):
			out.append(value)
	out.sort()
	out.push_front("Any role")
	return out


static func types(db: WeaponDb) -> Array[String]:
	var out: Array[String] = []
	for w: WeaponDef in db.by_id.values():
		if not out.has(w.type):
			out.append(w.type)
	out.sort()
	out.push_front("Any type")
	return out


static func unit_matches(d: UnitDef, phrase: String, filters: Dictionary) -> bool:
	var kind := int(filters.get("kind", 0))
	match kind:
		1:
			if d.is_support(): return false
		2:
			if d.vehicle == null: return false
		3:
			if d.battle_armor == null: return false
		4:
			if d.asset == null: return false
	if not ForceCatalogQuery.in_class(d, int(filters.get("weight", 0))):
		return false
	var tech := int(filters.get("tech", 0))
	if tech == 1 and d.tech_base != "inner_sphere": return false
	if tech == 2 and d.tech_base != "clan": return false
	if tech == 3 and d.clan_parts.is_empty() and d.tech_base != "mixed": return false
	var wanted := String(filters.get("role", ""))
	if not wanted.is_empty() and role(d) != wanted: return false
	var bv := int(filters.get("bv", 0))
	if bv > 0 and (d.asset != null or d.bv <= 0): return false
	match bv:
		1:
			if d.bv >= 1000: return false
		2:
			if d.bv < 1000 or d.bv >= 1500: return false
		3:
			if d.bv < 1500 or d.bv >= 2000: return false
		4:
			if d.bv < 2000: return false
	return ForceCatalogQuery.matches(d, phrase) or (not phrase.strip_edges().is_empty() and role(d).to_lower().contains(phrase.strip_edges().to_lower()))


static func weapon_matches(w: WeaponDef, phrase: String, filters: Dictionary) -> bool:
	var kind := String(filters.get("type", ""))
	if not kind.is_empty() and w.type != kind: return false
	var tech := int(filters.get("tech", 0))
	if tech == 1 and w.tech != "inner_sphere": return false
	if tech == 2 and w.tech != "clan": return false
	var ammo := int(filters.get("ammo", 0))
	if ammo == 1 and not w.uses_ammo(): return false
	if ammo == 2 and w.uses_ammo(): return false
	var text := ("%s %s %s %s" % [w.name, w.id, w.type, w.tech]).to_lower()
	for word in phrase.strip_edges().to_lower().split(" ", false):
		if not text.contains(word): return false
	return true


static func sort_units(entries: Array[UnitDef], mode: int) -> void:
	entries.sort_custom(func(a: UnitDef, b: UnitDef) -> bool:
		var av := a.bv if mode in [1, 2] else a.tonnage
		var bv := b.bv if mode in [1, 2] else b.tonnage
		if mode != 0 and av != bv:
			return av < bv if mode in [1, 3] else av > bv
		return a.display_name().naturalnocasecmp_to(b.display_name()) < 0)


static func row(parent: Control) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 6)
	parent.add_child(line)
	return line


static func choice(parent: Control, options: Array, change: Callable) -> OptionButton:
	var button := OptionButton.new()
	button.fit_to_longest_item = false
	button.clip_text = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 18)
	for value in options:
		button.add_item(String(value).capitalize() if String(value) == String(value).to_lower() else String(value))
		button.set_item_metadata(button.item_count - 1, value)
	button.select(0)
	button.item_selected.connect(change)
	parent.add_child(button)
	return button


static func selected(controls: Dictionary, text_keys: Array = []) -> Dictionary:
	var out := {}
	for key in controls:
		var button: OptionButton = controls[key]
		out[key] = (button.get_item_metadata(button.selected) if button.selected > 0 else "") if key in text_keys else button.selected
	return out


static func unit_controls(parent: Control, entries: Array[UnitDef], change: Callable) -> Dictionary:
	var first := row(parent)
	var second := row(parent)
	return {"kind": choice(first, KINDS, change), "weight": choice(first, WEIGHTS, change),
		"tech": choice(first, TECH, change), "role": choice(second, roles(entries), change),
		"bv": choice(second, BV, change), "sort": choice(second, SORT, change)}


static func weapon_controls(parent: Control, db: WeaponDb, change: Callable) -> Dictionary:
	var line := row(parent)
	return {"type": choice(line, types(db), change),
		"tech": choice(line, TECH.slice(0, 3), change), "ammo": choice(line, AMMO, change)}


static func reset(controls: Dictionary) -> void:
	for button: OptionButton in controls.values():
		button.select(0)
