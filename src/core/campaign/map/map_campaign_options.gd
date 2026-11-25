class_name MapCampaignOptions
extends RefCounted
## Optional verified variant availability uses the existing MUL database.
## This mode remains a lance-scale Inner Sphere campaign.


static func pool(db: UnitDb, year: int, faction: String) -> Array[UnitDef]:
	var availability := EraAvailability.new()
	return EnemyForce.designs(db).filter(func(d: UnitDef) -> bool:
		return availability.check(d.id, year, faction).get("status") == "available")


## Resolve the preset into real available designs, preserving approximate
## tonnage and BV. Refuse unverified historical setup.
static func prepare(rules: Dictionary, db: UnitDb) -> String:
	if not rules.get("historical", false):
		return ""
	var year := int(rules.get("era_year", 3025))
	var own := pool(db, year, String(rules.get("player_faction", "federated_suns")))
	var foe := pool(db, year, String(rules.get("enemy_faction", "draconis_combine")))
	if own.is_empty() or foe.is_empty():
		return "No verified Inner Sphere designs for one of the selected factions in that year."
	rules["era_year"] = year
	rules["player_faction"] = String(rules.get("player_faction", "federated_suns"))
	rules["enemy_faction"] = String(rules.get("enemy_faction", "draconis_combine"))
	var company: Array = rules.get("starting_company", [])
	for entry: Dictionary in company:
		var old := db.get_def(String(entry["design"]))
		var best: UnitDef = own[0]
		var gap := INF
		for d: UnitDef in own:
			var score := absf(float(d.tonnage - old.tonnage)) * 100.0 + absf(float(d.bv - old.bv)) if old != null else float(d.bv)
			if score < gap:
				best = d
				gap = score
		entry["design"] = best.id
	rules["factory_designs"] = own.map(func(d: UnitDef) -> String: return d.id)
	return ""
