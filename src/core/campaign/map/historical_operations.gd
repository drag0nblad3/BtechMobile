class_name HistoricalOperations
extends RefCounted
## Company-scale counterfactual operations. Source rosters are separate from
## scenario assumptions; no scripted victory, historical deaths or dice changes.

const PATH := "res://data/campaign/historical_operations.json"


static func all() -> Array:
	var data: Dictionary = JsonFile.read(PATH)
	return data.get("operations", [])


static func find(id: String) -> Dictionary:
	for op: Dictionary in all():
		if op["id"] == id:
			return op
	return {}


static func problem(op: Dictionary, db: UnitDb) -> String:
	if op.is_empty():
		return "Unknown historical operation."
	var rows: Array = op["terrain_rows"]
	var width := String(rows[0]).split(" ").size()
	var height := rows.size()
	for key in ["player_lances", "enemy_lances"]:
		for lance: Dictionary in op[key]:
			var z: Array = lance["zone"]
			if int(z[0]) < 0 or int(z[0]) >= width or int(z[1]) < 0 or int(z[1]) >= height:
				return "Invalid deployment zone."
			for m: Dictionary in lance["members"]:
				if db.get_def(String(m["design"])) == null:
					return "Missing design: %s" % m["design"]
	return ""


static func create(op: Dictionary, db: UnitDb) -> MapCampaign:
	if not problem(op, db).is_empty():
		return null
	var mc := MapCampaign.new()
	mc.rules = MapCampaign.load_rules()
	mc.rules["historical_operation"] = op.duplicate(true)
	mc.rules["operations"] = 1
	mc.rules["turn_limit"] = 12
	mc.rules["victory_share"] = 0.75
	mc.rules["factory_designs"] = []
	mc.region = _region(op)
	mc.player = Campaign.new()
	mc.enemy = Campaign.new()
	mc.player.name = String(op["player"])
	mc.enemy.name = String(op["enemy"])
	for side in 2:
		var roster := mc.roster(side)
		var formations: Array = op["player_lances" if side == 0 else "enemy_lances"]
		for entry: Dictionary in formations:
			var ids: Array[String] = []
			for m: Dictionary in entry["members"]:
				var p := roster.add_pilot(String(m["pilot"]), 4, 5)
				var mech := roster.add_mech(String(m["design"]))
				mech.pilot_id = p.id
				ids.append(mech.id)
			var z: Array = entry["zone"]
			var l := mc.add_lance(side, Vector2i(int(z[0]), int(z[1])), ids)
			l.name = String(entry["name"])
			l.target = l.zone
	mc.log.append("%s · %s" % [op["title"], op["date"]])
	mc.log.append(String(op["summary"]))
	MapIntelligence.observe(mc)
	return mc


static func _region(op: Dictionary) -> MapRegion:
	var region := MapRegion.new()
	var rows: Array = op["terrain_rows"]
	region.width = String(rows[0]).split(" ").size()
	region.height = rows.size()
	region.geography_seed = maxi(1, int(hash(op["id"])) & 0x7fffffff)
	for row: String in rows:
		for terrain_id: String in row.split(" "):
			region.terrain.append(terrain_id)
	for i in op["locations"].size():
		var loc: Dictionary = op["locations"][i].duplicate(true)
		var z: Array = loc["zone"]
		loc["zone"] = Vector2i(int(z[0]), int(z[1]))
		loc["id"] = "historical_%d" % i
		loc["points"] = int(loc["points"])
		loc["owner"] = int(loc["owner"])
		region.locations.append(loc)
	return region


static func context(mc: MapCampaign) -> String:
	var op: Dictionary = mc.rules.get("historical_operation", {})
	if op.is_empty():
		return ""
	var text := "%s · %s\n%s" % [op["title"], op["date"], op["fidelity"]]
	if mc.winner >= 0:
		text += "\nYour result: %s. Historical context: %s" % [
			"sector secured" if mc.winner == 0 else "operation unsuccessful", op["historical_result"]]
	return text


static func substitutions(op: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for key in ["player_lances", "enemy_lances"]:
		for l: Dictionary in op.get(key, []):
			for m: Dictionary in l["members"]:
				if m.has("recorded_variant"):
					out.append("%s: %s — %s" % [m["pilot"], m["recorded_variant"], m["note"]])
	return out
