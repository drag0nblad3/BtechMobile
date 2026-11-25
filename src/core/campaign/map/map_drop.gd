class_name MapDrop
extends RefCounted
## DropShip Move (Campaign Operations p. 148): the invader's DropShips lift
## a lance from its landing row, or from a DropPort it holds, to any zone.
## The flight takes 2 turns; from a held DropPort, or to one, 1 turn. While
## in the air the lance is off the map and can't fight or be attacked.
## TODO(rules): only the invader has DropShips; it may land on an enemy.


## Why `l` can't start a DropShip Move now, or "".
static func why_not(mc: MapCampaign, l: MapLance) -> String:
	if l.side != 0:
		return "Only the invader has DropShips."
	if not l.on_map():
		return "%s is already in the air." % l.name
	if l.zone.y != mc.region.height - 1 and not _port(mc, l.zone, l.side):
		return "DropShips load at your landing zone or a DropPort you hold."
	return ""


## Turns the flight to `target` takes.
static func turns(mc: MapCampaign, l: MapLance, target: Vector2i) -> int:
	return 1 if _port(mc, l.zone, l.side) or _port(mc, target, l.side) else 2


## At the start of the turn: lances lift off or land.
static func fly(mc: MapCampaign) -> void:
	for l in mc.lances:
		if l.order != MapLance.DROPSHIP:
			continue
		if l.on_map():
			l.transit = turns(mc, l, l.target) - 1
			if l.transit > 0:
				l.zone = MapLance.OFF_MAP
				continue
		elif l.transit > 0:
			l.transit -= 1
			if l.transit > 0:
				continue
		l.zone = l.target


static func _port(mc: MapCampaign, z: Vector2i, side: int) -> bool:
	var loc := mc.region.location_at(z)
	return not loc.is_empty() and loc["benefit"] == "dropport" and int(loc["owner"]) == side
