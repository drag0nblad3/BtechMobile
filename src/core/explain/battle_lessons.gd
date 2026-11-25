class_name BattleLessons
extends RefCounted
## Tactical Academy: likely mistakes found in the recorded event ledger, each
## with a short lesson. Judges the decision, not the dice: a shot at 11+ is
## flagged even when it hit. Reads BattleForensics timeline facts only.

const LONG_SHOT := 11  ## Needs 11+ on 2d6: 3 in 36 (8%).


## timeline: BattleForensics.analyze()["timeline"]; labels: str(id) -> {name, side}.
## Returns [{title, detail, lesson, turn, frame, side}] in battle order.
static func find(timeline: Array, labels: Dictionary = {}) -> Array:
	var out: Array = []
	var long_shots := {}  # "turn:unit" -> [count, first fact]
	var rear := {}
	for fact: Dictionary in timeline:
		var d: Dictionary = fact["data"]
		match String(fact["event"]):
			GameEvent.HEAT:
				var heat := int(d.get("heat", 0))
				if HeatScale.shutdown_avoid(heat) > 0:
					var ammo := HeatScale.ammo_explosion_avoid(heat)
					_add(out, fact, labels, int(d.get("unit_id", -1)), "Overheated",
							"ended the turn at heat %d (%s)" % [heat, HeatScale.effects_text(heat)],
							"Above 13 heat you roll to avoid shutting down%s. Hold back the weapons with the least damage per heat." % (
							" and to keep your ammo from exploding" if ammo > 0 else ""))
			GameEvent.WEAPON_FIRED:
				if int(d.get("need", 0)) >= LONG_SHOT and int(d.get("need", 0)) <= 12 and not bool(d.get("no_ammo", false)):
					_count(long_shots, fact, int(d.get("attacker_id", -1)))
			GameEvent.DAMAGE:
				if bool(d.get("rear", false)) and int(d.get("amount", 0)) > 0:
					_count(rear, fact, int(d.get("unit_id", -1)))
			GameEvent.UNIT_MOVED:
				var hexes := int(d.get("hexes", 0))
				if int(d.get("mode", -1)) == MoveMode.Kind.RUN and hexes > 0 and hexes <= 2:
					_add(out, fact, labels, int(d.get("unit_id", -1)), "Ran for nothing",
							"ran only %d hex%s" % [hexes, "" if hexes == 1 else "es"],
							"Up to 2 hexes gives no defense bonus whether you walk or run. Running still costs your own shots 1 more than walking, and a 'Mech 1 more heat.")
	for k: String in long_shots:
		var e: Array = long_shots[k]
		_add(out, e[1], labels, int(k.split(":")[1]), "Long shots",
				"fired %d shot%s needing 11 or more (8%% or less each)" % [e[0], "" if e[0] == 1 else "s"],
				"Those shots rarely hit but cost full heat. Close the range, find a clearer line, or hold them.")
	for k: String in rear:
		var e: Array = rear[k]
		_add(out, e[1], labels, int(k.split(":")[1]), "Rear exposed",
				"took %d hit%s in the rear armor" % [e[0], "" if e[0] == 1 else "s"],
				"Rear armor is thin. End moves facing the enemy, and don't leave an enemy behind you.")
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["turn"]) < int(b["turn"]))
	return out


static func _count(tally: Dictionary, fact: Dictionary, unit_id: int) -> void:
	var k := "%d:%d" % [int(fact["turn"]), unit_id]
	if not tally.has(k):
		tally[k] = [0, fact]
	tally[k][0] += 1


static func _add(out: Array, fact: Dictionary, labels: Dictionary, unit_id: int, title: String,
		what: String, lesson: String) -> void:
	var meta: Dictionary = labels.get(str(unit_id), {})
	var name := String(meta.get("name", "Unit #%d" % unit_id))
	var side := int(meta.get("side", -1))
	if side >= 0:
		name = "%s %s" % [Names.side(side), name]
	out.append({"title": title, "detail": "%s %s." % [name, what], "lesson": lesson,
			"turn": int(fact["turn"]), "frame": int(fact["frame"]), "side": side})
