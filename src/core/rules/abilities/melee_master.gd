class_name MeleeMaster
extends RefCounted
## Melee Master (Campaign Operations p. 77): one extra punch, kick, club or
## hatchet attack in the Physical Attack Phase, on top of the usual two
## punches or one other attack. Each limb still attacks once; two-armed
## attacks (club, push, two-handed) use both arms.
## TODO(rules): combining the extra attack with a charge or DFA is not offered.

const EXTRA := ["punch", "kick", "club", "hatchet"]


## The limbs an attack uses.
static func limbs(opt: Dictionary) -> Array[int]:
	var limb := int(opt["limb"])
	if limb < 0 or opt["kind"] == "zweihander":
		return [Location.LA, Location.RA]
	return [limb]


## May `opt` join the attacks already in `out`?
static func fits(out: Array[Dictionary], opt: Dictionary, master: bool) -> bool:
	var all: Array[Dictionary] = out.duplicate()
	all.append(opt)
	var used := {}
	var kicks := 0
	for o in all:
		kicks += 1 if o["kind"] == "kick" else 0
		for l in limbs(o):
			if used.has(l):
				return false
			used[l] = true
	if kicks > 1:
		return false
	if normal(all):
		return true
	if not master:
		return false
	for i in all.size():
		if EXTRA.has(all[i]["kind"]):
			var rest := all.duplicate()
			rest.remove_at(i)
			if normal(rest):
				return true
	return false


## Without the ability: up to two punches (one per arm), or one other attack.
static func normal(set: Array) -> bool:
	if set.size() <= 1:
		return true
	for o: Dictionary in set:
		if o["kind"] != "punch" and o["kind"] != "brush_off":
			return false
	return set.size() <= 2
