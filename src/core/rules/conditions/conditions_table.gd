class_name ConditionsTable
extends RefCounted
## Battlefield Conditions Table (book p. 227), for the mission complication.
## 2D6: 2-3 Extreme Cold, 4 Wind, 5 Snowfall, 6 Night, 7 roll twice more,
## 8 Rain, 9 Gravity, 10 Low Visibility, 11-12 Extreme Heat. Temperature
## level on 1D6: 1-3 = 1, 4-5 = 2, 6 = 3 (the same type twice adds a level,
## up to 3). Gravity on 1D6: 0.5, 0.8, 1.2, 1.5, 1.5, 2. Further 7s are
## ignored; incompatible results (rain/snowfall, cold/heat, and either with
## rain or snowfall against the temperature rules) and repeats are rerolled.

const GRAVITY := [0.5, 0.8, 1.2, 1.5, 1.5, 2.0]
const MAX_ROLLS := 30


static func roll(dice: Dice) -> Conditions:
	var c := Conditions.new()
	var want := 1
	var seen := {}
	var twice_used := false
	var guard := 0
	while want > 0 and guard < MAX_ROLLS:
		guard += 1
		var r := dice.roll_2d6()
		if r == 7:
			if not twice_used:
				twice_used = true
				want += 1  # this roll becomes two more
			continue
		if not _apply(c, r, dice, seen):
			continue
		want -= 1
	return c


## Applies one result; false if it must be rerolled.
static func _apply(c: Conditions, r: int, dice: Dice, seen: Dictionary) -> bool:
	var kind := _kind(r)
	var temp := kind == "cold" or kind == "heat"
	if seen.has(kind) and not temp:
		return false
	var trial := Conditions.from_dict(c.to_dict())
	match kind:
		"cold", "heat":
			var lvl := _temp_level(dice.d6())
			var cur: int = trial.get(kind)
			trial.set(kind, mini(Conditions.MAX_TEMP, maxi(cur, lvl) + 1 if cur > 0 else lvl))
		"gravity":
			trial.gravity = GRAVITY[dice.d6() - 1]
		_:
			trial.set(kind, true)
	if not trial.problems().is_empty():
		return false
	seen[kind] = true
	for k: String in ["cold", "heat", "gravity", "low_visibility", "wind", "rain", "snowfall", "night"]:
		c.set(k, trial.get(k))
	return true


static func _kind(r: int) -> String:
	match r:
		2, 3:
			return "cold"
		4:
			return "wind"
		5:
			return "snowfall"
		6:
			return "night"
		8:
			return "rain"
		9:
			return "gravity"
		10:
			return "low_visibility"
	return "heat"


static func _temp_level(d: int) -> int:
	return 1 if d <= 3 else (2 if d <= 5 else 3)
