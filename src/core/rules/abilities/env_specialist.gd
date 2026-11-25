class_name EnvSpecialist
extends RefCounted
## Environmental Specialist (Campaign Operations p. 74): in its chosen
## conditions, the environment's movement and piloting penalties are halved
## (rounded down) and, where the environment hurts weapon attacks, the
## specialist's own attacks get -1. Choices are the conditions this game
## models with modifiers: "wind", "ice" (icy ground), "low_visibility".
## TODO(rules): rain, snowfall and night have no modifiers here yet.

const WIND := "wind"
const ICE := "ice"
const LOW_VISIBILITY := "low_visibility"


static func knows(u: Unit, env: String) -> bool:
	return Spa.choices(u, Spa.ENV_SPECIALIST).has(env)


## A piloting penalty from environment `env`, halved for a specialist.
static func penalty(u: Unit, env: String, mod: int) -> int:
	return mod / 2 if knows(u, env) else mod


## Adds a halved piloting modifier with a note on why.
static func add_psr(th: ToHit, u: Unit, env: String, name: String, mod: int, why: String) -> void:
	var m := penalty(u, env, mod)
	if m == mod:
		th.add(name, mod, why)
	else:
		th.add(name, m, why + " Environmental Specialist: halved to %+d." % m)


## The -1 for a specialist attacking in conditions that hurt weapon attacks.
static func add_attack(th: ToHit, u: Unit, env: String) -> void:
	if knows(u, env):
		th.add("environmental specialist", -1, "Trained for these conditions: -1 to its attacks here.")
