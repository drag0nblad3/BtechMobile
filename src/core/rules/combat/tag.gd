class_name Tag
extends RefCounted
## Target Acquisition Gear (book p. 200). Before anyone fires, a 'Mech with
## TAG may designate one enemy: a normal to-hit roll (no targeting computer),
## no damage, and it doesn't count as one of its targets or stop it punching.
## A designated target counts as spotted for indirect fire that turn, with the
## TAG 'Mech as the spotter but never the "spotter attacking" +1. A 'Mech that
## designates can't spot a different target. Light TAG has shorter range, and
## a C3 Master doubles as TAG (p. 199). ECM doesn't affect TAG.
## TODO(rules): the book resolves all TAG before the Ranged Attack Phase; here
## a 'Mech fires TAG during that phase before its own declaration, so shots
## declared earlier don't benefit. No TAG-guided munitions (semi-guided,
## Arrow IV homing, Copperhead) yet.

## Ranges from the weapon tables (pp. 250, 252): short, medium, long.
const RANGES := {"tag": [5, 9, 15], "c_tag": [5, 9, 15], "c_light_tag": [3, 6, 9], "c3_master": [5, 9, 15]}
const NAMES := {"tag": "TAG", "c_tag": "TAG", "c_light_tag": "Light TAG", "c3_master": "C3 Master (as TAG)"}


static func has(def: UnitDef) -> bool:
	return def.c3_master_loc >= 0 or def.inert.any(func(g: Dictionary) -> bool: return RANGES.has(g["kind"]))


## Working TAG mounts as weapons the to-hit rules understand.
static func mounts(u: Unit) -> Array[MountedWeapon]:
	var out: Array[MountedWeapon] = []
	for g: Dictionary in u.def.inert:
		if RANGES.has(g["kind"]) and not _slot_hit(u, g["loc"], InertGear.KINDS[g["kind"]]["name"]):
			out.append(MountedWeapon.new(_def(g["kind"]), g["loc"], false))
	if C3.is_master(u.def) and C3.working(u):
		out.append(MountedWeapon.new(_def("c3_master"), u.def.c3_master_loc, false))
	return out


## Why `u` can't designate now, or "".
static func problem(state: GameState, u: Unit) -> String:
	if not has(u.def):
		return "no TAG"
	if used(state, u):
		return "TAG already fired this turn"
	if u.has_fired:
		return "TAG goes before your weapons fire"
	if NarcPods.has(state, u, NarcPods.HAYWIRE):
		return "a haywire pod stops it designating"
	if mounts(u).is_empty() or u.shutdown or not u.pilot.conscious:
		return "TAG is out of action"
	return ""


## Best to-hit for designating `target` (impossible if no mount can).
static func to_hit(state: GameState, u: Unit, target: Unit) -> ToHit:
	var best: ToHit = null
	for w in mounts(u):
		var th := ToHitCalc.weapon(state, u, w, target)
		if best == null or (th.possible() and (not best.possible() or th.target() < best.target())):
			best = th
	if best == null:
		best = ToHit.new()
		best.impossible = "no working TAG"
	return best


## Rolls the designation; returns the event data.
static func fire(state: GameState, dice: Dice, u: Unit, target: Unit) -> Dictionary:
	var th := to_hit(state, u, target)
	state.tag_used[u.id] = state.turn
	var d := {"unit_id": u.id, "target_id": target.id, "need": th.target(), "mods": th.mods}
	if not th.possible():
		d.merge({"roll": 0, "hit": false, "why": th.impossible})
		return d
	var r := dice.roll_2d6()
	d.merge({"roll": r, "hit": r >= th.target()})
	if d["hit"]:
		state.tagged[target.id] = {"by": u.id, "turn": state.turn}
		state.spotting[u.id] = {"target": target.id, "turn": state.turn, "tag": true}
	return d


static func used(state: GameState, u: Unit) -> bool:
	return int(state.tag_used.get(u.id, -1)) == state.turn


## The friendly 'Mech that TAG-designated `target` this turn, or null.
static func designator(state: GameState, side: int, target: Unit) -> Unit:
	var rec: Dictionary = state.tagged.get(target.id, {})
	if rec.is_empty() or int(rec["turn"]) != state.turn:
		return null
	var u := state.unit_by_id(int(rec["by"]))
	return u if u != null and u.side == side else null


static func _def(kind: String) -> WeaponDef:
	var w := WeaponDef.new()
	w.id = kind
	w.name = NAMES[kind]
	w.type = "electronic"  # never linked to a targeting computer
	w.short_range = RANGES[kind][0]
	w.medium_range = RANGES[kind][1]
	w.long_range = RANGES[kind][2]
	return w


static func _slot_hit(u: Unit, loc: int, slot_name: String) -> bool:
	if u.is_location_out(loc):
		return true
	for s: CritSlot in u.slots[loc]:
		if s.kind == CritSlot.Kind.GEAR and s.name == slot_name and s.hit:
			return true
	return false
