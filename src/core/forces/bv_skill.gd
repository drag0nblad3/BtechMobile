class_name BvSkill
extends RefCounted
## Battle Value skill adjustment (book p. 222): a 'Mech's BV is multiplied by
## a factor for its MechWarrior's Gunnery and Piloting (4/5 is 1.00). The
## table lives in data/bv_skill.json.

const PATH := "res://data/bv_skill.json"
## Skill presets offered when building a force: [label, gunnery, piloting].
const PRESETS := [["Regular", 4, 5], ["Veteran", 3, 4], ["Elite", 2, 3], ["Green", 5, 6]]

static var _table: Array = []


static func multiplier(gunnery: int, piloting: int) -> float:
	if _table.is_empty():
		_table = JsonFile.read(PATH)["multipliers"]
	return float(_table[clampi(gunnery, 0, 8)][clampi(piloting, 0, 8)])


## Base BV adjusted for skill, rounded to the nearest point.
static func adjusted(bv: int, gunnery: int, piloting: int) -> int:
	return roundi(bv * multiplier(gunnery, piloting))


static func preset_name(gunnery: int, piloting: int) -> String:
	for p: Array in PRESETS:
		if p[1] == gunnery and p[2] == piloting:
			return "%s %d/%d" % [p[0], gunnery, piloting]
	return "%d/%d" % [gunnery, piloting]
