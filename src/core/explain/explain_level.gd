class_name ExplainLevel
extends RefCounted
## How much teaching text the game shows. FULL explains every modifier and
## offers advice; LIGHT shows the numbers in one line; OFF shows outcomes only.

enum { FULL, LIGHT, OFF }

const NAMES := ["Full", "Light", "Off"]


static func name_of(level: int) -> String:
	return NAMES[clampi(level, 0, 2)]


static func next(level: int) -> int:
	return (level + 1) % 3
