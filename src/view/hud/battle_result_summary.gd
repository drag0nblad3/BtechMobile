class_name BattleResultSummary
extends RefCounted
## Read-only summary for the results panel; Academy retains the full analysis.

static func describe(state: GameState, frames: Array, bot_sides: Array) -> String:
	var labels := {}
	for u: Unit in state.all_units():
		labels[str(u.id)] = {"name": u.def.name, "side": u.side}
	var report := BattleForensics.analyze(frames, labels)
	var lines: Array[String] = ["AFTER-ACTION REPORT"]
	var damage := 0
	var taken := 0
	var shots := 0
	var hits := 0
	var best: Dictionary = {}
	for row: Dictionary in report["units"]:
		if int(row["side"]) < 0 or bot_sides.has(int(row["side"])):
			continue
		damage += int(row["damage_dealt"])
		taken += int(row["damage_taken"])
		shots += int(row["attacks"])
		hits += int(row["hits"])
		if best.is_empty() or int(row["damage_dealt"]) > int(best["damage_dealt"]):
			best = row
	lines.append("Damage dealt: %d  ·  Received: %d" % [damage, taken])
	lines.append("Attacks landed: %d/%d%s" % [hits, shots,
		" (%d%%)" % roundi(100.0 * hits / shots) if shots > 0 else ""])
	if not best.is_empty() and int(best["damage_dealt"]) > 0:
		lines.append("MVP (damage dealt): %s · %d" % [best["name"], best["damage_dealt"]])
	var moments: Array = report["moments"]
	if not moments.is_empty():
		var moment: Dictionary = moments[0]
		lines.append("Key moment · Turn %d: %s" % [moment["turn"], moment["title"]])
		lines.append(String(moment["detail"]))
	lines.append("See Tactical Academy for the full ledger and replay.")
	return "\n".join(lines)
