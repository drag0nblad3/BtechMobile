class_name MoveMode
extends RefCounted
## Ground movement modes. Jumping gets its own planner later.

enum Kind { WALK, RUN }


static func name_of(k: int) -> String:
	return ["Walk", "Run"][k] if k >= 0 and k < 2 else "-"


static func budget(def: UnitDef, k: int) -> int:
	return def.run_mp() if k == Kind.RUN else def.walk_mp
