class_name MapCampaignHistory
extends RefCounted
## Full player after-action reports retain region and day context.


static func record(mc: MapCampaign, zone: Vector2i, winner: int, lines: Array[String]) -> void:
	var loc := mc.region.location_at(zone)
	var label := String(loc.get("name", "%s (%d,%d)" % [
		mc.region.terrain_at(zone).capitalize(), zone.x + 1, zone.y + 1]))
	mc.reports.append({"operation": mc.operation, "day": mc.turn, "zone": label,
		"winner": winner, "lines": Array(lines)})
