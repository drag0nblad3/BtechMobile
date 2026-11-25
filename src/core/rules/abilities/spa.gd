class_name Spa
extends RefCounted
## Special Pilot Abilities (Campaign Operations pp. 70-82): which a
## MechWarrior has, and their names and costs from data/pilot_abilities.json.
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

static var _data: Dictionary = {}


## An ability may carry a choice after a colon: "weapon_specialist:ppc".
static func has(u: Unit, id: String) -> bool:
	return choice(u, id) != "" or (u != null and u.pilot != null and u.pilot.abilities.has(id))


## The choice made for ability `id` ("ppc" for "weapon_specialist:ppc"), or "".
static func choice(u: Unit, id: String) -> String:
	if u == null or u.pilot == null:
		return ""
	for a in u.pilot.abilities:
		if a.begins_with(id + ":"):
			return a.substr(id.length() + 1)
	return ""


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
