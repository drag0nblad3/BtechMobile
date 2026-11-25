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

static var _data: Dictionary = {}


static func has(u: Unit, id: String) -> bool:
	return u != null and u.pilot != null and u.pilot.abilities.has(id)


## Gives `p` ability `id`; Lucky takes its points (1-4) as rerolls.
static func grant(p: Pilot, id: String, points := 1) -> void:
	if not p.abilities.has(id):
		p.abilities.append(id)
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
