class_name DesignFilter
extends RefCounted
## Catalog of designs for the force builder: filter by technology (all,
## Inner Sphere, Clan) and group OmniMech configurations by chassis so the
## list shows each chassis once.

enum Mode { ALL, INNER_SPHERE, CLAN }
const NAMES := ["All 'Mechs", "Inner Sphere", "Clan"]
const CLAN_TIP := "Clan technology: its weapons hit harder and reach farther for their weight, and its XL engine survives losing a side torso, so a Clan 'Mech costs much more Battle Value than an Inner Sphere one its size."
const OMNI_TIP := "OmniMech: the same chassis with its weapon pods swapped between battles. Each configuration plays like its own 'Mech."


static func next(mode: int) -> int:
	return (mode + 1) % NAMES.size()


static func keeps(def: UnitDef, mode: int) -> bool:
	match mode:
		Mode.INNER_SPHERE:
			return not def.is_clan()
		Mode.CLAN:
			return def.is_clan()
	return true


## Groups of designs (light to heavy): one per ordinary design, one per
## OmniMech chassis holding its configurations (Prime first).
static func groups(db: UnitDb, mode: int) -> Array:
	var out := []
	var by_chassis := {}
	for def in db.sorted_defs():
		if not keeps(def, mode):
			continue
		if def.chassis == "":
			out.append([def])
		elif by_chassis.has(def.chassis):
			by_chassis[def.chassis].append(def)
		else:
			by_chassis[def.chassis] = [def]
			out.append(by_chassis[def.chassis])
	for g: Array in by_chassis.values():
		g.sort_custom(func(a: UnitDef, b: UnitDef) -> bool:
				return a.config == "Prime" or (b.config != "Prime" and a.config < b.config))
	return out


## Teaching line about a design's technology ("" for plain Inner Sphere).
static func tech_tip(def: UnitDef) -> String:
	var parts: Array[String] = []
	if def.is_clan():
		parts.append(CLAN_TIP)
	if def.omni:
		parts.append(OMNI_TIP)
	return " ".join(parts)
