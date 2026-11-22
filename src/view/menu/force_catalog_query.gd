class_name ForceCatalogQuery
extends RefCounted
## Text search, weight class filter and sorting for official designs.
## Never alters unit definitions or costs.

const CLASSES := ["All", "Light", "Medium", "Heavy", "Assault"]
const SORTS := ["Name", "BV", "Tons"]


## Class 0 keeps everything; units without a weight class only pass class 0.
static func in_class(def: UnitDef, class_index: int) -> bool:
	if class_index <= 0:
		return true
	if def.asset != null or def.battle_armor != null:
		return false
	return def.weight_class() == CLASSES[class_index]


## Sorts catalog entries ({"def"}) in place: by name (as given), BV high to
## low at the side's skill, or tonnage high to low.
static func sort(matches: Array[Dictionary], sort_index: int, builder: ForceBuilder, side: int) -> void:
	if sort_index == 1:
		var bv := {}
		for m in matches:
			var d: UnitDef = m["def"]
			bv[d.id] = builder.unit_bv(side, d)
		matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return bv[(a["def"] as UnitDef).id] > bv[(b["def"] as UnitDef).id])
	elif sort_index == 2:
		matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return (a["def"] as UnitDef).tonnage > (b["def"] as UnitDef).tonnage)

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
