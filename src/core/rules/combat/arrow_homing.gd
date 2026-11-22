class_name ArrowHoming
extends RefCounted
## Homing Arrow IV missiles (book p. 190). Fired at a hex in the launcher's
## arc (here: the hex of the unit you pick), no line of sight needed; a close
## shot still can't aim within 6 hexes. When it lands it homes on a unit that
## friendly TAG designated this turn within 8 hexes of that hex (the
## attacker's pick: here the enemy nearest the hex). No such unit: the missile
## is lost, no scatter. Then 2D6 with no modifiers: 4+ deals 20 damage to that
## unit (hit from the launcher's direction) and 5 AE to everything else in
## its hex; 3 or less deals 5 AE to everything in its hex. AMS can't stop it.
## A friend of the attacker next to that unit with an enemy Nemesis pod on it
## (p. 194) draws the missile on 1-3 on 1D6 (picked at random among several).

const KIND := "homing"
const NEED := 4
const REACH := 8
const DAMAGE := 20
const SPLASH := 5


static func to_hit(attacker: Unit, w: MountedWeapon, c: Vector2i) -> ToHit:
	var th := ToHit.new()
	var dist := Hex.distance(attacker.coord, c)
	if dist < ArrowIv.MIN_HEXES:
		th.impossible = "Arrow IV can't aim %d or fewer hexes away" % (ArrowIv.MIN_HEXES - 1)
		return th
	var arc_id := FiringArc.fire_arc(attacker.coord, FiringArc.weapon_facing(attacker, w.loc), c)
	if not FiringArc.weapon_covers(w.loc, ArmFlip.rear(attacker, w), arc_id, attacker.def.quad):
		th.impossible = "The hex is in your %s arc; %s can't point there" % [FiringArc.NAMES[arc_id], w.label()]
		return th
	th.add("homing", NEED, "Homing missiles ride a friendly TAG beam: 4+ on 2D6, nothing modifies it.")
	th.indirect = true
	return th


## The unit a homing missile aimed at `c` locks onto, or null.
static func target(state: GameState, attacker: Unit, c: Vector2i) -> Unit:
	var best: Unit = null
	var best_key := 9999
	for u in state.units:
		if u.destroyed or u.carrier_id() >= 0 or not designated(state, attacker.side, u):
			continue
		var d := Hex.distance(u.coord, c)
		if d > REACH:
			continue
		var key := d + (0 if u.side != attacker.side else 100)
		if key < best_key:
			best = u
			best_key = key
	return best


## The attacker's friends next to `t` carrying an enemy Nemesis pod.
static func nemesis(state: GameState, attacker: Unit, t: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in state.units_of_side(attacker.side):
		if u != t and not u.destroyed and Hex.distance(u.coord, t.coord) == 1 and NarcPods.has(state, u, NarcPods.NEMESIS):
			out.append(u)
	return out


## Did a TAG on `side` designate `u` this turn?
static func designated(state: GameState, side: int, u: Unit) -> bool:
	var t: Dictionary = state.tagged.get(u.id, {})
	if t.is_empty() or int(t["turn"]) != state.turn:
		return false
	var by := state.unit_by_id(int(t["by"]))
	return by != null and by.side == side


static func land(state: GameState, dice: Dice, emit: Callable, attacker: Unit, w: MountedWeapon, c: Vector2i,
		distant: bool) -> void:
	var data := {"attacker_id": attacker.id, "target_id": -1, "target_hex": c, "weapon": w.def.name,
			"weapon_id": w.def.id, "roll": 0, "need": NEED, "hit": false, "mods": [], "missiles": 0,
			"target_noun": "hex", "homing": true, "distant": distant}
	var t := target(state, attacker, c)
	if t == null:
		data["homing_lost"] = true
		emit.call(GameEvent.WEAPON_FIRED, data)
		return
	var decoys := nemesis(state, attacker, t)
	if not decoys.is_empty():
		data["nemesis_roll"] = dice.d6()
		if int(data["nemesis_roll"]) <= 3:
			t = decoys[0] if decoys.size() == 1 else decoys[dice.pick(decoys.size())]
			data["nemesis"] = true
	data["roll"] = dice.roll_2d6()
	data["hit"] = data["roll"] >= NEED
	data["target_id"] = t.id
	data["target_noun"] = ""
	emit.call(GameEvent.WEAPON_FIRED, data)
	var base := state.map.get_tile(t.coord).level
	if data["hit"]:
		var arc_id := FiringArc.arc(t.coord, t.facing, attacker.coord)
		WeaponFire.hit_with(state, dice, emit, t, arc_id, DAMAGE, attacker.id, w.def.name, {}, Hex.INVALID, ["DB"])
	AreaEffect.blast(state, dice, emit, t.coord, attacker.coord, SPLASH, base, attacker.id, w.def.name,
			t.id if data["hit"] else -1)
