class_name ArrowIv
extends RefCounted
## Arrow IV artillery missiles fired by 'Mechs (book pp. 182, 190). The shot
## aims at a hex (here: the hex of the unit you pick) 7+ hexes away. To-hit:
## Gunnery +4, attacker movement and its own conditions, plus indirect-fire
## modifiers if it can't see the hex (a spotter is needed); never range,
## target movement or immobile modifiers. 7-17 hexes ("close") lands this
## phase; 18+ ("distant") lands in next turn's weapon phase on the hex as it
## was. A hit deals 20 to everything in the hex and 10 to the hexes around
## it, in 5-point groups (AreaEffect). A miss scatters half the margin of
## failure (rounded up; the full margin when distant) in a 1D6 direction,
## never out of the launcher's arc. AMS can't stop it; no aimed shots.
## TODO(rules): homing, smoke, inferno and other munitions; the bot only
## fires it at units; scatter is checked against the arc the launcher faces
## when the missile lands.

const MIN_HEXES := 7
const DISTANT := 18
const MOD := 4
const CENTER := 20
const RING := 10


static func is_arrow(w: MountedWeapon) -> bool:
	return w.def.artillery


static func to_hit(state: GameState, attacker: Unit, w: MountedWeapon, target: Unit) -> ToHit:
	var th := ToHit.new()
	var c := target.coord
	var dist := Hex.distance(attacker.coord, c)
	if dist < MIN_HEXES:
		th.impossible = "Arrow IV can't hit anything %d or fewer hexes away" % (MIN_HEXES - 1)
		return th
	var arc_id := FiringArc.fire_arc(attacker.coord, FiringArc.weapon_facing(attacker, w.loc), c)
	if not FiringArc.weapon_covers(w.loc, ArmFlip.rear(attacker, w), arc_id, attacker.def.quad):
		th.impossible = "The target is in your %s arc; %s can't point there" % [FiringArc.NAMES[arc_id], w.label()]
		return th
	th.add("Gunnery", attacker.pilot.gunnery, "Your MechWarrior's gunnery skill is the base number.")
	th.add("artillery", MOD, "Arrow IV is artillery: +4, but range and the target's movement don't count.")
	ToHitCalc.add_attacker_movement(th, attacker)
	var los := LineOfSight.check(state.map, attacker, target)
	if los["blocked"]:
		var spotter := IndirectFire.spotter(state, attacker, target)
		if spotter == null:
			th.impossible = "No line of sight, and no friendly 'Mech can spot that hex"
			return th
		IndirectFire.add_mods(th, state, spotter, target)
		th.indirect = true
		th.spotter_id = spotter.id
		los = LineOfSight.none()
	ToHitCalc.add_attacker_conditions(th, attacker, los)
	if Location.is_arm_of(attacker.def, w.loc):
		ToHitCalc.add_arm_actuators(th, attacker, w.loc)
	return th


## Fires the missile at `target`'s hex: lands now, or next turn if distant.
static func fire(state: GameState, dice: Dice, emit: Callable, attacker: Unit, w: MountedWeapon,
		target: Unit, th: ToHit) -> void:
	var data := {"attacker_id": attacker.id, "target_id": -1, "target_hex": target.coord, "weapon": w.def.name,
			"weapon_id": w.def.id, "roll": 0, "need": th.target(), "hit": false, "mods": th.mods,
			"missiles": 0, "target_noun": "hex"}
	if WeaponFire.take_shots(attacker, w) == 0:
		data["no_ammo"] = true
		emit.call(GameEvent.WEAPON_FIRED, data)
		return
	w.fired = true
	attacker.heat_generated += w.def.heat
	var distant := Hex.distance(attacker.coord, target.coord) >= DISTANT
	if distant:
		state.artillery.append({"attacker_id": attacker.id, "weapon_index": attacker.weapons.find(w),
				"hex": target.coord, "turn": state.turn + 1, "need": th.target(), "mods": th.mods})
		data["arrives_next_turn"] = true
		emit.call(GameEvent.WEAPON_FIRED, data)
		return
	land(state, dice, emit, attacker, w, target.coord, th.target(), th.mods, false)


## Rolls and lands a missile aimed at `c`.
static func land(state: GameState, dice: Dice, emit: Callable, attacker: Unit, w: MountedWeapon, c: Vector2i,
		need: int, mods: Array, distant: bool) -> void:
	var roll := dice.roll_2d6()
	var data := {"attacker_id": attacker.id, "target_id": -1, "target_hex": c, "weapon": w.def.name,
			"weapon_id": w.def.id, "roll": roll, "need": need, "hit": roll >= need, "mods": mods,
			"missiles": 0, "target_noun": "hex", "artillery": true, "distant": distant}
	var at := c
	if not data["hit"]:
		var mof := need - roll
		var dist := mof if distant else ceili(mof / 2.0)
		var dir := dice.d6()
		at = AreaEffect.scatter(state, dir, attacker.coord, c, dist, func(h: Vector2i) -> bool: return _in_arc(attacker, w, h))
		data["scatter"] = {"dir": dir, "hexes": dist, "to": at}
	emit.call(GameEvent.WEAPON_FIRED, data)
	if at == Hex.INVALID:
		return
	AreaEffect.strike(state, dice, emit, at, attacker.coord, CENTER, RING, attacker.id, w.def.name)


## Weapon phase: lands the distant missiles due this turn.
static func resolve_due(state: GameState, dice: Dice, emit: Callable) -> void:
	var keep: Array[Dictionary] = []
	for a: Dictionary in state.artillery:
		if int(a["turn"]) > state.turn:
			keep.append(a)
			continue
		var u := state.unit_by_id(int(a["attacker_id"]))
		if u == null:
			continue
		land(state, dice, emit, u, u.weapons[int(a["weapon_index"])], a["hex"], int(a["need"]), a["mods"], true)
	state.artillery = keep


static func _in_arc(attacker: Unit, w: MountedWeapon, h: Vector2i) -> bool:
	var arc_id := FiringArc.fire_arc(attacker.coord, FiringArc.weapon_facing(attacker, w.loc), h)
	return FiringArc.weapon_covers(w.loc, ArmFlip.rear(attacker, w), arc_id, attacker.def.quad)
