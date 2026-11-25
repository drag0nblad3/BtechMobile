class_name MapTactics
extends RefCounted
## Tactical quality, not a win-probability model. Both deployment axes
## matter because standard missions may use either. LOS is deterministic
## stratified sampling of standing, non-submerged ground positions.

static func assess(m: BattleMap, sight := true) -> Dictionary:
	var center := MapMobility.center_cells(m)
	var ns := MapMobility.axis(m, 0, center)
	var ew := MapMobility.axis(m, 2, center)
	var out := {"north_south": ns, "east_west": ew, "center_cells": center.size()}
	if sight:
		out["sight"] = sightlines(m)
	return out


## Only gross mobility failures trigger extra generation attempts. A lake
## or a dense city may legitimately favour one kind of force.
static func penalty(report: Dictionary) -> float:
	var p := 0.0
	for key in ["north_south", "east_west"]:
		var a: Dictionary = report[key]
		p += 12.0 * maxf(0.0, 0.85 - float(a["shared"]))
		p += 3.0 * maxi(0, 2 - int(a["exits"]))
		p += 2.0 * maxi(0, 4 - int(a["shared_center"]))
		p += 4.0 * maxf(0.0, 0.50 - float(a["center_balance"]))
		p += maxi(0, 8 - mini(int(a["deploy_a"]), int(a["deploy_b"])))
		if int(a["cross_mp"]) >= MapMobility.UNREACHABLE:
			p += 20.0
	return p


## Sample actual LOS at 3-6, 7-12 and 13-20 hexes. Both directions
## are checked because the engine's divided-line/cover rules are directional.
static func sightlines(m: BattleMap) -> Dictionary:
	var samples := [0, 0, 0]
	var clear := [0, 0, 0]
	var cover := [0, 0, 0]
	var cells: Array[Vector2i] = []
	for y in range(1, m.height, 3):
		for x in range(1, m.width, 3):
			var c := Hex.from_offset(Vector2i(x, y))
			if MapMobility.usable(m.get_tile(c)):
				cells.append(c)
	for i in cells.size():
		var a := cells[i]
		for j in range(i + 1, cells.size()):
			var b := cells[j]
			var d := Hex.distance(a, b)
			if d < 3 or d > 20:
				continue
			var band := 0 if d <= 6 else 1 if d <= 12 else 2
			var la := Bridges.stand_level(m.get_tile(a))
			var lb := Bridges.stand_level(m.get_tile(b))
			for direction in 2:
				var r := LineOfSight._best(m, a, b, la + 2, lb + 2, lb) if direction == 0 else LineOfSight._best(m, b, a, lb + 2, la + 2, la)
				samples[band] += 1
				if not r["blocked"]:
					clear[band] += 1
					if int(r["woods"]) > 0 or r["cover"] != Hex.INVALID:
						cover[band] += 1
	var out := {}
	for i in 3:
		out[["short", "medium", "long"][i]] = {"samples": samples[i],
			"visible": float(clear[i]) / maxi(1, samples[i]),
			"covered_visible": float(cover[i]) / maxi(1, clear[i])}
	return out
