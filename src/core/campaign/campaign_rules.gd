class_name CampaignRules
extends RefCounted
## The app's own campaign numbers (data/campaign/rules.json). The Core
## Rulebook leaves campaigns to other books (p. 212), so none of these are
## official. TODO(rules): swap in an official campaign system if one is added.

const PATH := "res://data/campaign/rules.json"

var data: Dictionary = {}


static func load_file(path: String = PATH) -> CampaignRules:
	var r := CampaignRules.new()
	r.data = JsonFile.read(path)
	return r


func xp(kind: String) -> int:
	return int(data.get("xp", {}).get(kind, 0))


func wounds_healed() -> int:
	return int(data.get("wounds_healed_per_battle", 0))


func starting_lance() -> Array:
	return data.get("starting_lance", [])
