class_name EraAvailability
extends RefCounted
## Offline variant-specific Master Unit List records. No tech-base or chassis inference.

enum Mode { OFF, ADVISORY, STRICT }
const MODE_NAMES := ["Off", "Advisory", "Strict"]
const PATH := "res://data/forces/availability.json"
const ERAS := [
	{"id": "age_of_war", "name": "Age of War", "start": 2398, "end": 2570},
	{"id": "star_league", "name": "Star League", "start": 2571, "end": 2780},
	{"id": "sw_early", "name": "Early Succession War", "start": 2781, "end": 2900},
	{"id": "sw_lostech", "name": "Late Succession War - LosTech", "start": 2901, "end": 3019},
	{"id": "sw_renaissance", "name": "Late Succession War - Renaissance", "start": 3020, "end": 3049},
	{"id": "clan_invasion", "name": "Clan Invasion", "start": 3050, "end": 3061},
	{"id": "civil_war", "name": "Civil War", "start": 3062, "end": 3067},
	{"id": "jihad", "name": "Jihad", "start": 3068, "end": 3080},
	{"id": "republic", "name": "Early Republic", "start": 3081, "end": 3100},
	{"id": "late_republic", "name": "Late Republic", "start": 3101, "end": 3130},
	{"id": "dark_age", "name": "Dark Age", "start": 3131, "end": 3150},
	{"id": "ilclan", "name": "ilClan", "start": 3151, "end": 3153},
]
const FACTIONS := [
	{"id": "federated_suns", "name": "Federated Suns"},
	{"id": "draconis_combine", "name": "Draconis Combine"},
	{"id": "lyran_commonwealth", "name": "Lyran Commonwealth"},
	{"id": "free_worlds_league", "name": "Free Worlds League"},
	{"id": "capellan_confederation", "name": "Capellan Confederation"},
	{"id": "federated_commonwealth", "name": "Federated Commonwealth"},
	{"id": "lyran_alliance", "name": "Lyran Alliance"},
	{"id": "free_rasalhague_republic", "name": "Free Rasalhague Republic"},
	{"id": "comstar", "name": "ComStar"},
	{"id": "mercenary", "name": "Mercenary"},
	{"id": "wolfs_dragoons", "name": "Wolf's Dragoons"},
	{"id": "taurian_concordat", "name": "Taurian Concordat"},
	{"id": "magistracy_of_canopus", "name": "Magistracy of Canopus"},
	{"id": "republic_of_the_sphere", "name": "Republic of the Sphere"},
	{"id": "clan_wolf", "name": "Clan Wolf"},
	{"id": "clan_wolf_in_exile", "name": "Clan Wolf (in Exile)"},
	{"id": "clan_jade_falcon", "name": "Clan Jade Falcon"},
	{"id": "clan_ghost_bear", "name": "Clan Ghost Bear"},
	{"id": "clan_smoke_jaguar", "name": "Clan Smoke Jaguar"},
	{"id": "clan_nova_cat", "name": "Clan Nova Cat"},
	{"id": "clan_sea_fox", "name": "Clan Sea Fox"},
	{"id": "rasalhague_dominion", "name": "Rasalhague Dominion"},
	{"id": "wolf_empire", "name": "Wolf Empire"},
	{"id": "ilclan_wolf", "name": "ilClan Wolf"},
]
var records: Dictionary = {}


func _init(source: Dictionary = {}) -> void:
	var data: Dictionary = source if not source.is_empty() else JsonFile.read(PATH)
	records = data.get("units", {})


static func era_index(year: int) -> int:
	for i in ERAS.size():
		var era: Dictionary = ERAS[i]
		if year >= int(era["start"]) and year <= int(era["end"]):
			return i
	return -1


static func era_id(year: int) -> String:
	var index := era_index(year)
	return String(ERAS[index]["id"]) if index >= 0 else ""


static func era_name(year: int) -> String:
	var index := era_index(year)
	return String(ERAS[index]["name"]) if index >= 0 else "Outside published timeline"


static func faction_name(id: String) -> String:
	for faction: Dictionary in FACTIONS:
		if faction["id"] == id:
			return String(faction["name"])
	return id


## Available, unavailable and unverified are distinct outcomes. Missing data
## never proves a negative. A known introduction year rules out an anachronism.
func check(def_id: String, year: int, faction_id: String) -> Dictionary:
	var era := era_id(year)
	if era == "":
		return {"status": "unverified", "reason": "Year is outside the supported MUL timeline."}
	var row: Dictionary = records.get(def_id, {})
	if row.is_empty():
		return {"status": "unverified", "reason": "No verified MUL entry for this exact variant."}
	var intro := int(row.get("intro_year", 0))
	if intro > 0 and year < intro:
		return {"status": "unavailable", "reason": "Not introduced until %d." % intro}
	var by_faction: Dictionary = row.get("factions", {})
	if not by_faction.has(faction_id):
		return {"status": "unverified", "reason": "No verified MUL faction record for %s." % faction_name(faction_id)}
	var allowed: Array = by_faction[faction_id]
	if allowed.has(era):
		return {"status": "available", "reason": "MUL confirms %s in %s." % [
			faction_name(faction_id), era_name(year)]}
	return {"status": "unavailable", "reason": "MUL does not list this variant for %s during %s." % [
		faction_name(faction_id), era_name(year)]}
