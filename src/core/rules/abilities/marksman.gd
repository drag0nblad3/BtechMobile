class_name Marksman
extends RefCounted
## Marksman (Campaign Operations p. 79): a MechWarrior who stood still may
## aim one weapon at a moving 'Mech as if using a targeting computer (+3,
## never the head, no pulse lasers; AimedShot). Only that weapon fires that
## turn and no physical attack follows. With a working targeting computer
## the aimed shot also gets -2.
## TODO(rules): "stationary" read as no hexes entered and no jump (turning
## in place allowed). The computer player doesn't use it.

const TC_MOD := -2
const LABEL := "marksman"


## May aim like a targeting computer this turn.
static func ready(u: Unit) -> bool:
	return u != null and Spa.has(u, Spa.MARKSMAN) and u.hexes_moved == 0 \
			and u.move_mode != MoveMode.Kind.JUMP and not u.marksman_used


## Marks an aimed shot at a moving target as the Marksman's.
static func adjust(th: ToHit, had_tc: bool) -> void:
	if had_tc:
		th.add(LABEL, TC_MOD, "Marksman with a targeting computer: -2 on the aimed shot.")
	else:
		th.add(LABEL, 0, "Marksman: aims like a targeting computer; only this weapon fires this turn.")


static func on(th: ToHit) -> bool:
	return th.mods.any(func(m: Dictionary) -> bool: return m["label"] == LABEL)


## Keeps only the first Marksman shot when there is one.
static func filter(decl: Array[Dictionary]) -> Array[Dictionary]:
	for d in decl:
		if d.has("to_hit") and on(d["to_hit"]):
			return [d] as Array[Dictionary]
	return decl
