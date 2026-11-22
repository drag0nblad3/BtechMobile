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
	{"id": "capellan_confederation", "name": "Capellan Confederation", "start": 2367, "end": 9999},
	{"id": "comstar", "name": "ComStar", "start": 2788, "end": 3141},
	{"id": "draconis_combine", "name": "Draconis Combine", "start": 2319, "end": 9999},
	{"id": "duchy_of_andurien", "name": "Duchy of Andurien (FWL)", "start": 3068, "end": 9999},
	{"id": "duchy_of_tamarind_abbey", "name": "Duchy of Tamarind-Abbey (FWL)", "start": 3071, "end": 3139},
	{"id": "federated_commonwealth", "name": "Federated Commonwealth", "start": 3055, "end": 3067},
	{"id": "federated_suns", "name": "Federated Suns", "start": 2317, "end": 9999},
	{"id": "free_rasalhague_republic", "name": "Free Rasalhague Republic", "start": 3034, "end": 3103},
	{"id": "free_worlds_league", "name": "Free Worlds League", "start": 2271, "end": 9999},
	{"id": "lyran_alliance", "name": "Lyran Alliance", "start": 3057, "end": 3084},
	{"id": "lyran_commonwealth", "name": "Lyran Commonwealth", "start": 2341, "end": 9999},
	{"id": "marik_stewart_commonwealth", "name": "Marik-Stewart Commonwealth (FWL)", "start": 3082, "end": 3138},
	{"id": "non_aligned_worlds", "name": "Non-Aligned Worlds (FWL)", "start": 3079, "end": 3150},
	{"id": "oriente_protectorate", "name": "Oriente Protectorate (FWL)", "start": 3068, "end": 3139},
	{"id": "regulan_fiefs", "name": "Regulan Fiefs (FWL)", "start": 3068, "end": 3148},
	{"id": "republic_of_the_sphere", "name": "Republic of the Sphere", "start": 3081, "end": 3151},
	{"id": "rim_commonality", "name": "Rim Commonality (FWL)", "start": 2681, "end": 3139},
	{"id": "st_ives_compact", "name": "St. Ives Compact", "start": 3029, "end": 3063},
	{"id": "tamar_pact", "name": "Tamar Pact", "start": 3151, "end": 9999},
	{"id": "terran_hegemony", "name": "Terran Hegemony", "start": 2315, "end": 2767},
	{"id": "vesper_marches", "name": "Vesper Marches", "start": 3151, "end": 9999},
	{"id": "word_of_blake", "name": "Word of Blake", "start": 3052, "end": 3081},
	{"id": "alyina_mercantile_league", "name": "Alyina Mercantile League", "start": 3151, "end": 9999},
	{"id": "clan_blood_spirit", "name": "Clan Blood Spirit", "start": 2807, "end": 3084},
	{"id": "clan_burrock", "name": "Clan Burrock", "start": 2807, "end": 3074},
	{"id": "clan_cloud_cobra", "name": "Clan Cloud Cobra", "start": 2807, "end": 9999},
	{"id": "clan_coyote", "name": "Clan Coyote", "start": 2807, "end": 9999},
	{"id": "clan_diamond_shark", "name": "Clan Diamond Shark", "start": 2895, "end": 3100},
	{"id": "clan_fire_mandrill", "name": "Clan Fire Mandrill", "start": 2807, "end": 3073},
	{"id": "clan_ghost_bear", "name": "Clan Ghost Bear", "start": 2807, "end": 3080},
	{"id": "clan_goliath_scorpion", "name": "Clan Goliath Scorpion", "start": 2807, "end": 3078},
	{"id": "clan_hells_horses", "name": "Clan Hell's Horses", "start": 2807, "end": 9999},
	{"id": "clan_ice_hellion", "name": "Clan Ice Hellion", "start": 2807, "end": 3074},
	{"id": "clan_jade_falcon", "name": "Clan Jade Falcon", "start": 2807, "end": 9999},
	{"id": "clan_mongoose", "name": "Clan Mongoose", "start": 2807, "end": 2868},
	{"id": "clan_nova_cat", "name": "Clan Nova Cat", "start": 2807, "end": 3143},
	{"id": "clan_protectorate", "name": "Clan Protectorate", "start": 3138, "end": 9999},
	{"id": "clan_sea_fox", "name": "Clan Sea Fox", "start": 2807, "end": 9999},
	{"id": "clan_smoke_jaguar", "name": "Clan Smoke Jaguar", "start": 2807, "end": 9999},
	{"id": "clan_snow_raven", "name": "Clan Snow Raven", "start": 2807, "end": 3083},
	{"id": "clan_star_adder", "name": "Clan Star Adder", "start": 2807, "end": 9999},
	{"id": "clan_steel_viper", "name": "Clan Steel Viper", "start": 2807, "end": 3075},
	{"id": "clan_stone_lion", "name": "Clan Stone Lion", "start": 3075, "end": 9999},
	{"id": "clan_widowmaker", "name": "Clan Widowmaker", "start": 2807, "end": 2834},
	{"id": "clan_wolf", "name": "Clan Wolf", "start": 2807, "end": 3151},
	{"id": "clan_wolf_in_exile", "name": "Clan Wolf (in Exile)", "start": 3057, "end": 3151},
	{"id": "clan_wolverine", "name": "Clan Wolverine", "start": 2807, "end": 2823},
	{"id": "ilclan_wolf", "name": "ilClan Wolf", "start": 3151, "end": 9999},
	{"id": "jade_falcon_remnant", "name": "Jade Falcon Remnant", "start": 3152, "end": 9999},
	{"id": "rasalhague_dominion", "name": "Rasalhague Dominion", "start": 3103, "end": 9999},
	{"id": "raven_alliance", "name": "Raven Alliance", "start": 3083, "end": 9999},
	{"id": "society", "name": "Society", "start": 2901, "end": 3085},
	{"id": "star_league_in_exile", "name": "Star League in Exile", "start": 2781, "end": 2822},
	{"id": "wolf_empire", "name": "Wolf Empire", "start": 3142, "end": 9999},
	{"id": "calderon_protectorate", "name": "Calderon Protectorate", "start": 3066, "end": 9999},
	{"id": "circinus_federation", "name": "Circinus Federation", "start": 2785, "end": 3081},
	{"id": "filtvelt_coalition", "name": "Filtvelt Coalition", "start": 3072, "end": 9999},
	{"id": "fronc_reaches", "name": "Fronc Reaches", "start": 3066, "end": 9999},
	{"id": "magistracy_of_canopus", "name": "Magistracy of Canopus", "start": 2530, "end": 9999},
	{"id": "marian_hegemony", "name": "Marian Hegemony", "start": 2920, "end": 9999},
	{"id": "outworlds_alliance", "name": "Outworlds Alliance", "start": 2413, "end": 3083},
	{"id": "pirates", "name": "Pirates", "start": 2005, "end": 9999},
	{"id": "rim_worlds_republic", "name": "Rim Worlds Republic", "start": 2250, "end": 2779},
	{"id": "scorpion_empire", "name": "Scorpion Empire", "start": 3080, "end": 9999},
	{"id": "taurian_concordat", "name": "Taurian Concordat", "start": 2335, "end": 9999},
	{"id": "kell_hounds", "name": "Kell Hounds", "start": 3010, "end": 9999},
	{"id": "mercenary", "name": "Mercenary", "start": 2005, "end": 9999},
	{"id": "wolfs_dragoons", "name": "Wolf's Dragoons", "start": 3004, "end": 9999},
	{"id": "solaris_7", "name": "Solaris 7", "start": 2901, "end": 9999},
	{"id": "star_league_first", "name": "Star League (First)", "start": 2571, "end": 2780},
	{"id": "star_league_second", "name": "Star League (Second)", "start": 3058, "end": 3067},
]
## Shared immutable snapshot: avoid decoding the full MUL table each time
## the force builder preflights another starter formation.
static var _cached_records: Dictionary = {}
var records: Dictionary = {}


func _init(source: Dictionary = {}) -> void:
	if not source.is_empty():
		records = source.get("units", {})
	elif _cached_records.is_empty():
		_cached_records = JsonFile.read(PATH).get("units", {})
		records = _cached_records
	else:
		records = _cached_records


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


static func faction_info(id: String) -> Dictionary:
	for faction: Dictionary in FACTIONS:
		if faction["id"] == id:
			return faction
	return {}


static func faction_name(id: String) -> String:
	return String(faction_info(id).get("name", id))


## Available, unavailable and unverified are distinct outcomes. Missing data
## never proves a negative. A known introduction year rules out an anachronism.
func check(def_id: String, year: int, faction_id: String) -> Dictionary:
	var era := era_id(year)
	if era == "":
		return {"status": "unverified", "reason": "Year is outside the supported MUL timeline."}
	var faction := faction_info(faction_id)
	if faction.is_empty():
		return {"status": "unverified", "reason": "Unknown MUL faction."}
	if year < int(faction["start"]) or year > int(faction["end"]):
		return {"status": "unavailable", "reason": "%s did not exist in %d." % [
			String(faction["name"]), year]}
	var row: Dictionary = records.get(def_id, {})
	if row.is_empty():
		return {"status": "unverified", "reason": "No verified MUL entry for this exact variant."}
	var intro := int(row.get("intro_year", 0))
	if intro > 0 and year < intro:
		return {"status": "unavailable", "reason": "Not introduced until %d." % intro}
	var by_faction: Dictionary = row.get("factions", {})
	if not by_faction.has(faction_id):
		if String(row.get("matrix_status", "")) == "published":
			return {"status": "unavailable", "reason": "MUL does not list this variant for %s during %s." % [
				faction_name(faction_id), era_name(year)]}
		return {"status": "unverified", "reason": "No verified MUL faction record for %s." % faction_name(faction_id)}
	var allowed: Array = by_faction[faction_id]
	if allowed.has(era):
		return {"status": "available", "reason": "MUL confirms %s in %s." % [
			faction_name(faction_id), era_name(year)]}
	return {"status": "unavailable", "reason": "MUL does not list this variant for %s during %s." % [
		faction_name(faction_id), era_name(year)]}
