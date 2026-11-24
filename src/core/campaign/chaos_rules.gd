class_name ChaosRules
extends RefCounted
## Campaign Operations' Chaos Campaign numbers (data/campaign/chaos.json):
## Warchest objectives and options, track cost, enemy force sizes, skill
## levels. Where the book leaves a choice to the GM the file marks our pick.

const PATH := "res://data/campaign/chaos.json"

var data: Dictionary = {}


static func load_file(path: String = PATH) -> ChaosRules:
	var r := ChaosRules.new()
	r.data = JsonFile.read(path)
	return r


func objectives() -> Array:
	return data.get("objectives", [])


func options() -> Array:
	return data.get("options", [])


func objective(id: String) -> Dictionary:
	return _find(objectives(), id)


func option(id: String) -> Dictionary:
	return _find(options(), id)


func starting_wp() -> int:
	return int(data.get("starting_wp", 0))


func cost_share() -> float:
	return float(data.get("track_cost_share", 0.75))


## [gunnery, piloting] for "green", "regular", "veteran" or "elite".
func skill(level: String) -> Vector2i:
	var s: Array = data.get("skill_levels", {}).get(level, [4, 5])
	return Vector2i(int(s[0]), int(s[1]))


func _find(list: Array, id: String) -> Dictionary:
	for d: Dictionary in list:
		if d.get("id", "") == id:
			return d
	return {}
