class_name MoveMode
extends RefCounted
## Ground movement modes. Jumping gets its own planner later.

enum Kind { WALK, RUN }


static func name_of(k: int) -> String:
	return ["Walk", "Run"][k] if k >= 0 and k < 2 else "-"


## MP available this turn, after heat and damage. Standing up costs 2 MP.
static func budget(unit: Unit, k: int) -> int:
	var mp := unit.run_mp() if k == Kind.RUN else unit.walk_mp()
	return mp - (2 if unit.prone else 0)
