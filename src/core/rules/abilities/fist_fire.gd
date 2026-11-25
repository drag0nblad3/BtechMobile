class_name FistFire
extends RefCounted
## Fist Fire (Campaign Operations p. 75): after a punch or arm weapon swing
## lands, the MechWarrior fires one direct-fire energy or ballistic weapon
## in that arm, at -1 to hit, and a hit strikes the same location. The arm
## needs a working shoulder, upper arm, lower arm and hand.
## TODO(rules): the weapon is picked automatically (most damage); only
## 'Mechs are targets (vehicles and Assets have no matching location).

const MOD := -1
const ACTUATORS := ["shoulder", "upper_arm", "lower_arm", "hand"]


## The arm weapon to follow up with, or null.
static func weapon(a: Unit, arm: int) -> MountedWeapon:
	if not Spa.has(a, Spa.FIST_FIRE) or arm < 0 or a.is_location_out(arm):
		return null
	for act in ACTUATORS:
		if not a.has_working_actuator(arm, act):
			return null
	var best: MountedWeapon = null
	for w in a.weapons:
		var d := w.def
		if w.loc != arm or w.destroyed or w.fired or w.jammed or d.ams or d.is_cluster() \
				or not (d.type == "energy" or d.type == "ballistic") or WeaponModes.shots(w) != 1 \
				or WeaponModes.ammo_kind(w) == WeaponModes.CLUSTER:
			continue
		if best == null or d.damage > best.def.damage:
			best = w
	return best


## After a physical hit `d` that struck location `hl`.
static func follow_up(state: GameState, dice: Dice, emit: Callable, a: Unit, t: Unit, d: Dictionary, hl: Dictionary) -> void:
	if not ["punch", "hatchet", "sword"].has(String(d["kind"])) or t.destroyed \
			or t.asset != null or t.vehicle != null or t.ba != null:
		return
	var w := weapon(a, int(d["limb"]))
	if w == null:
		return
	var th := ToHitCalc.weapon(state, a, w, t)
	if not th.possible():
		return
	th.add("fist fire", MOD, "Fist Fire: the arm weapon fires point-blank after the blow: -1.")
	var shots := WeaponFire.take_shots(a, w)
	if shots == 0:
		return
	w.fired = true
	a.heat_generated += w.def.heat * shots
	var roll := dice.roll_2d6()
	var need := th.target()
	var hit := roll >= need
	emit.call(GameEvent.WEAPON_FIRED, {"attacker_id": a.id, "target_id": t.id, "weapon": w.def.name,
			"weapon_id": w.def.id, "weapon_index": a.weapons.find(w), "roll": roll, "need": need,
			"hit": hit, "mods": th.mods, "missiles": 0, "shots": shots, "mode": w.mode, "fist_fire": true})
	if not hit:
		return
	var dmg := w.def.damage
	if not w.def.damage_by_range.is_empty():
		dmg = w.def.damage_at(Hex.distance(a.coord, t.coord), 0)
	var arc_id := FiringArc.arc(t.coord, t.facing, a.coord)
	WeaponFire.hit_with(state, dice, emit, t, arc_id, dmg, a.id, w.def.name,
			{"loc": hl["loc"], "rear": hl.get("rear", false), "tac": false, "roll": 0, "no_cover": true},
			Hex.INVALID, ArmorTypes.weapon_attack(w.def))
