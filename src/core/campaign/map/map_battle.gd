class_name MapBattle
extends RefCounted
## Turns a map campaign meeting into a battle and writes it back
## (Campaign Operations pp. 149-153). The battlefield is generated from the
## zone's terrain; the scenario's stand-in mission is played with Forced
## Withdrawal; a Defend order, and a held fortress in or next to the zone,
## each give +1 Initiative. Afterwards both rosters keep their damage, and
## a losing lance that can still fight falls back one zone.
## TODO(rules): the book leaves the loser's retreat to the GM.


## {state, rosters: [{uid: mech id}, {uid: mech id}]} or {} if a side can't field a 'Mech.
static func build(mc: MapCampaign, b: Dictionary, db: UnitDb, seed_value: int) -> Dictionary:
	var lances := [_side_lance(mc, b, 0), _side_lance(mc, b, 1)]
	var fb := ForceBuilder.new(db, ForceBuilder.BUDGETS.back())
	fb.commanders = true
	var ids := [[], []]
	for side in 2:
		ids[side] = mc.fit_mechs(lances[side])
		for id: String in ids[side]:
			fb.add(side, mc.roster(side).mech(id).design)
		if ids[side].is_empty():
			return {}
	fb.mission_id = String(b.get("mission", ""))
	fb.forced_withdrawal = true
	var dice := Dice.new(seed_value)
	var state := fb.build(battlefield(mc, b["zone"], seed_value), dice)
	if state == null:
		return {}
	for side in 2:
		state.initiative_bonus[side] = initiative(mc, lances[side], b["zone"])
	var rosters := [CampaignBattle.prepare(mc.player, state, 0, ids[0]),
			CampaignBattle.prepare(mc.enemy, state, 1, ids[1])]
	return {"state": state, "rosters": rosters}


## A generated map for the zone's terrain theme.
static func battlefield(mc: MapCampaign, z: Vector2i, _seed_value: int) -> BattleMap:
	var terrain := mc.region.terrain_at(z)
	var theme_id := String(mc.rules.get("terrains", {}).get(terrain, {}).get("theme", "grassland"))
	var loc := mc.region.location_at(z)
	var variants := {"factory": "industrial", "fortress": "fortified", "seaport": "coastal"}
	var kind := String(loc.get("kind", ""))
	if variants.has(kind):
		theme_id = String(variants[kind])
	var themes := MapTheme.load_all()
	var theme: MapTheme = themes[0]
	for t in themes:
		if t.id == theme_id:
			theme = t
	return MapGenerator.build(theme, MapGenerator.SIZES[1], MapGeography.battle_seed(mc.region, z), TerrainDb.load_file())


static func initiative(mc: MapCampaign, l: MapLance, z: Vector2i) -> int:
	var n := 1 if l.order == MapLance.DEFEND else 0
	for loc in mc.region.locations:
		if loc["benefit"] == "fortress" and int(loc["owner"]) == l.side and mc.region.distance(loc["zone"], z) <= 1:
			n += 1
	return n


## Writes the battle back into both rosters; returns the player's report.
static func finish(mc: MapCampaign, b: Dictionary, state: GameState, rosters: Array, winner: int,
		kills: Dictionary = {}) -> Array[String]:
	var report := CampaignBattle.finish(mc.player, state, rosters[0], winner == 0, kills, null, 0)
	CampaignBattle.finish(mc.enemy, state, rosters[1], winner == 1, kills, null, 1)
	report[0] = "Turn %d, %s: %s %s." % [mc.turn, ScenarioTable.name_of(b["scenario"]),
			mc.lance(_lance_id(b, 0)).name if mc.lance(_lance_id(b, 0)) != null else "Your lance",
			"won" if winner == 0 else "lost"]
	if winner >= 0:
		var loser := _side_lance(mc, b, 1 - winner)
		if loser != null and not mc.fit_mechs(loser).is_empty():
			loser.zone = _fallback(mc, loser)
			report.append("%s falls back." % loser.name)
	mc.battles.erase(b)
	mc.log.append_array(report)
	MapCampaignHistory.record(mc, b["zone"], winner, report)
	MapIntelligence.observe(mc)
	return report


static func _side_lance(mc: MapCampaign, b: Dictionary, side: int) -> MapLance:
	return mc.lance(_lance_id(b, side))


static func _lance_id(b: Dictionary, side: int) -> String:
	for key in ["attacker", "defender"]:
		if String(b[key]).begins_with("p" if side == 0 else "e"):
			return String(b[key])
	return ""


## The neighboring zone closest to the side's home (south edge or capital).
static func _fallback(mc: MapCampaign, l: MapLance) -> Vector2i:
	var home: Vector2i = Vector2i(l.zone.x, mc.region.height - 1) if l.side == 0 else mc.region.locations[0]["zone"]
	return mc.region.step_toward(l.zone, home) if home != l.zone else l.zone
