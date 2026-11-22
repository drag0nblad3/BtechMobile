class_name ForceCatalogQuery
extends RefCounted
## Text search for official designs. Never alters unit definitions or costs.

static func matches(def: UnitDef, phrase: String) -> bool:
	var q := phrase.strip_edges().to_lower()
	if q.is_empty():
		return true
	var words := q.split(" ", false)
	var text := " ".join([def.name, def.model, def.chassis, def.config,
		def.role, def.weight_class()])
	for mount: Dictionary in def.weapon_mounts:
		text += " " + (mount["weapon"] as WeaponDef).name
	if def.asset != null:
		text += " " + def.asset.motive_name() + " " + def.asset.summary()
	if def.vehicle != null:
		text += " " + def.vehicle.motive_name()
	if def.battle_armor != null:
		for weapon: Dictionary in def.battle_armor.weapons:
			text += " " + String(weapon.get("name", ""))
	text = text.to_lower()
	for word in words:
		if not text.contains(word):
			return false
	return true
