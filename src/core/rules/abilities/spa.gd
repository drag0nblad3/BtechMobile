class_name Spa
extends RefCounted
## Special Pilot Abilities (Campaign Operations pp. 70-82): which a
## MechWarrior has (its own, or free from its formation), and their names and costs from data/pilot_abilities.json.
## Each ability's effect lives in its own file or a one-line hook.

const PATH := "res://data/pilot_abilities.json"
const BLOOD_STALKER := "blood_stalker"
const LUCKY := "lucky"
const MULTI_TASKER := "multi_tasker"
const SNIPER := "sniper"
const SPEED_DEMON := "speed_demon"
const EAGLES_EYES := "eagles_eyes"
const FORWARD_OBSERVER := "forward_observer"
const HOT_DOG := "hot_dog"
const JUMPING_JACK := "jumping_jack"
const MANEUVERING_ACE := "maneuvering_ace"
const MELEE_SPECIALIST := "melee_specialist"
const OBLIQUE_ATTACKER := "oblique_attacker"
const WEAPON_SPECIALIST := "weapon_specialist"
const CLUSTER_HITTER := "cluster_hitter"
const HUMAN_TRO := "human_tro"
const RANGE_MASTER := "range_master"
const TACTICAL_GENIUS := "tactical_genius"
const TERRAIN_MASTER := "terrain_master"
const DODGE := "dodge"
const FIST_FIRE := "fist_fire"
const HOPPER := "hopper"
const MARKSMAN := "marksman"
const ZWEIHANDER := "zweihander"

static var _data: Dictionary = {}


## An ability may carry a choice after a colon: "weapon_specialist:ppc".
static func has(u: Unit, id: String) -> bool:
	return choice(u, id) != "" or entries(u).has(id)


## The MechWarrior's own abilities and the free ones from its formation.
static func entries(u: Unit) -> Array[String]:
	var out: Array[String] = []
	if u != null and u.pilot != null:
		out.append_array(u.pilot.abilities)
	if u != null:
		out.append_array(u.formation_spas)
	return out


## The choice made for ability `id` ("ppc" for "weapon_specialist:ppc"), or "".
static func choice(u: Unit, id: String) -> String:
	var all_choices := choices(u, id)
	return all_choices[0] if not all_choices.is_empty() else ""


## Every choice made for ability `id` (Terrain Master can be bought more than once).
static func choices(u: Unit, id: String) -> Array[String]:
	var out: Array[String] = []
	for a in entries(u):
		if a.begins_with(id + ":"):
			out.append(a.substr(id.length() + 1))
	return out


## Gives `p` ability `id` (with an optional choice); Lucky takes its
## points (1-4) as rerolls.
static func grant(p: Pilot, id: String, points := 1, pick := "") -> void:
	var entry := id + (":" + pick if pick != "" else "")
	if not p.abilities.has(entry):
		p.abilities.append(entry)
	if id == LUCKY:
		p.lucky = clampi(points, 1, int(info(LUCKY).get("max", 4)))


static func info(id: String) -> Dictionary:
	for a: Dictionary in all():
		if a.get("id", "") == id:
			return a
	return {}


static func all() -> Array:
	if _data.is_empty():
		_data = JsonFile.read(PATH)
	return _data.get("abilities", [])


static func name_of(id: String) -> String:
	return String(info(id).get("name", id.capitalize()))
