class_name StarterFormations
extends RefCounted
## Curated examples, not unit refits; validates against the real builder.

const PATH := "res://data/forces/starter_formations.json"


static func all() -> Array[Dictionary]:
	var data: Dictionary = JsonFile.read(PATH)
	var out: Array[Dictionary] = []
	for entry: Dictionary in data.get("formations", []):
		out.append(entry)
	return out


static func description(form: Dictionary) -> String:
	var units: Array = form.get("units", [])
	return "%s  ·  %d 'Mechs" % [
		"CLAN STAR" if String(form.get("kind", "")) == "star" else "IS LANCE",
		units.size()]


## Preflight the entire replacement under the selected side's actual skill.
## No existing roster or budget is modified by this method.
static func plan(builder: ForceBuilder, side: int, form: Dictionary) -> Dictionary:
	if side < 0 or side >= builder.rosters.size():
		return {"ok": false, "reason": "Unknown force."}
	var ids: Array = form.get("units", [])
	var kind := String(form.get("kind", ""))
	var wanted := 5 if kind == "star" else 4
	if kind not in ["lance", "star"] or ids.size() != wanted:
		return {"ok": false, "reason": "Formation has the wrong number of 'Mechs."}
	var ceiling: int = ForceBuilder.BUDGETS.back()
	var test := ForceBuilder.new(builder.units, ceiling)
	test.skills[side] = builder.skills[side]
	for id in ids:
		var def: UnitDef = builder.units.get_def(String(id))
		if def == null or def.is_support() or def.is_clan() != (kind == "star"):
			return {"ok": false, "reason": "Starter formation contains an invalid unit."}
		var error := test.cant_add(side, String(id))
		if error != "":
			return {"ok": false, "reason": error}
		test.add(side, String(id))
	var total := test.bv(side)
	var chosen := -1
	for level in ForceBuilder.BUDGETS:
		if level >= total and level >= builder.budget:
			chosen = level
			break
	if chosen < 0:
		return {"ok": false, "reason": "This formation exceeds the maximum BV limit."}
	return {"ok": true, "cost": total, "budget": chosen,
		"raises_budget": chosen > builder.budget}


## Atomic view-layer operation; other side, skill, rules and mission persist.
static func apply(builder: ForceBuilder, side: int, form: Dictionary) -> Dictionary:
	var preview := plan(builder, side, form)
	if not preview.get("ok", false):
		return preview
	var new_roster: Array = []
	for id in form.get("units", []):
		new_roster.append(String(id))
	builder.budget = int(preview["budget"])
	builder.rosters[side] = new_roster
	return preview
