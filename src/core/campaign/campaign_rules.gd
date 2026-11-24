class_name CampaignRules
extends RefCounted
## The company's starting set-up (data/campaign/rules.json): its name and
## starting lance of official designs. Book numbers live in ChaosRules.

const PATH := "res://data/campaign/rules.json"

var data: Dictionary = {}


static func load_file(path: String = PATH) -> CampaignRules:
	var r := CampaignRules.new()
	r.data = JsonFile.read(path)
	return r


func starting_lance() -> Array:
	return data.get("starting_lance", [])
