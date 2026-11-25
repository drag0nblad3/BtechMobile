class_name MapCampaignLogistics
extends RefCounted
## Explains already implemented key-location benefits. No new supply rule.


static func describe(mc: MapCampaign, z: Vector2i) -> String:
	var loc := mc.region.location_at(z)
	if loc.is_empty():
		return "No key location. Repair orders remain available."
	var owner := "Friendly" if int(loc["owner"]) == 0 else "Enemy-held"
	var benefit := ""
	match String(loc.get("benefit", "")):
		"repair": benefit = "Full repair and pilot recovery for occupying friendly lances."
		"fortress": benefit = "Full repair; +1 initiative for friendly battles here or adjacent."
		"supply": benefit = "Armor and ammunition replenishment; no structure repair."
		"factory": benefit = "Full repair and one-time Mech production when captured."
		"seaport": benefit = "Direct Move to another friendly seaport."
		"dropport": benefit = "Faster DropShip transit."
		_: benefit = "Strategic objective; no additional facility benefit."
	return owner + " · " + benefit
