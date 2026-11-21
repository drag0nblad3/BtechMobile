class_name OmniConfig
extends RefCounted
## OmniMechs (book p. 20): one chassis whose weapons sit in pods that
## technicians swap between battles. In play an OmniMech follows the normal
## 'Mech rules; each configuration (Prime, A, B, ...) is its own design.
## A data file with "configs" holds the fixed parts once (engine, armor,
## fixed equipment) and each configuration's pod gear; this expands it.


## Design dictionaries in a unit file: itself, or one per configuration.
static func expand(d: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not d.has("configs"):
		out.append(d)
		return out
	for c: Dictionary in d["configs"]:
		var v := d.duplicate(true)
		v.erase("configs")
		for k: String in c:
			if k != "equipment":
				v[k] = c[k]
		v["equipment"] = merge_equipment(d.get("equipment", {}), c.get("equipment", {}))
		v["omni"] = true
		v["chassis"] = d["id"]
		v["config"] = c["model"]
		v["id"] = config_id(d["id"], c["model"])
		out.append(v)
	return out


## Fixed items first, then the pods, per location.
static func merge_equipment(fixed: Dictionary, pods: Dictionary) -> Dictionary:
	var eq := {}
	for code: String in fixed:
		eq[code] = (fixed[code] as Array).duplicate()
	for code: String in pods:
		if not eq.has(code):
			eq[code] = []
		eq[code].append_array(pods[code])
	return eq


## "timber_wolf" + "Prime" -> "timber_wolf_prime".
static func config_id(chassis: String, model: String) -> String:
	return "%s_%s" % [chassis, model.to_lower().replace(" ", "_")]
