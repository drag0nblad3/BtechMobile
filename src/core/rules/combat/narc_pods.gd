class_name NarcPods
extends RefCounted
## Special Narc and iNarc pods (book pp. 193-194), loaded as munitions in
## their own ammo bins (`ammo:inarc_beacon:haywire` and so on; the firing
## mode picks one). Explosive pods (Narc or iNarc) just do damage: 4, or 6
## for iNarc. iNarc only: haywire pods give the 'Mech +1 to all its ranged
## attacks and stop it spotting; ECM pods treat it as inside hostile ECM;
## Nemesis pods draw the enemy's Artemis and Narc-equipped missiles onto it
## when it stands on their line of sight. Lasting pods work from the next
## turn, until their location is destroyed, and not while the 'Mech is in ECM
## hostile to the pod's side.
## TODO(rules): a Nemesis shot is rolled against the decoy with the decoy's
## own to-hit number; SG missiles and Arrow IV homing aren't in the game.

const EXPLOSIVE := "explosive"
const HAYWIRE := "haywire"
const ECM := "ecm"
const NEMESIS := "nemesis"


## Damage of an explosive pod from this beacon.
static func explosive_damage(def: WeaponDef) -> int:
	return 6 if def.id == "inarc_beacon" else 4


## Does `u` carry a working enemy pod of this kind?
static func has(state: GameState, u: Unit, kind: String) -> bool:
	for p: Dictionary in u.narc_pods:
		if String(p.get("kind", "")) == kind and int(p["side"]) != u.side and int(p["turn"]) < state.turn \
				and not u.is_location_destroyed(int(p["loc"])) and not Ecm.hostile_at(state, int(p["side"]), u.coord):
			return true
	return false


## Haywire pod on the attacker: +1 to its ranged attacks.
static func add_haywire(th: ToHit, state: GameState, attacker: Unit) -> void:
	if has(state, attacker, HAYWIRE):
		th.add("haywire pod", 1, "An enemy haywire pod is scrambling your sensors: +1 to every shot, and you can't spot.")


## The friendly 'Mech tagged by an enemy Nemesis pod that this shot hits
## instead of `target`, or null. Only Artemis and Narc-equipped missiles.
static func decoy(state: GameState, dice: Dice, attacker: Unit, w: MountedWeapon, target: Unit) -> Unit:
	if target == null or not (WeaponModes.has_artemis(w) or WeaponModes.ammo_kind(w) == Narc.KIND):
		return null
	var line := Hex.line(attacker.coord, target.coord)
	var best: Array[Unit] = []
	var best_d := 99
	for u in state.units_of_side(attacker.side):
		if u == attacker or u.destroyed or not line.has(u.coord) or u.coord == target.coord \
				or not has(state, u, NEMESIS) or LineOfSight.check(state.map, attacker, u)["blocked"]:
			continue
		var d := Hex.distance(attacker.coord, u.coord)
		if d < best_d:
			best = [u]
			best_d = d
		elif d == best_d:
			best.append(u)
	if best.is_empty():
		return null
	return best[0] if best.size() == 1 else best[dice.pick(best.size())]


## A beacon hit: an explosive pod does its damage where it lands; any other
## pod sticks there (aimed or rolled) for its side.
static func land(state: GameState, dice: Dice, emit: Callable, attacker: Unit, w: MountedWeapon,
		target: Unit, th: ToHit, arc_id: int, data: Dictionary) -> void:
	var kind := WeaponModes.ammo_kind(w)
	var hl := AimedShot.location(dice, th, arc_id, target.def.quad) if th.aim_loc >= 0 else HitTable.roll(dice, arc_id)
	data["pod_kind"] = kind
	if kind == EXPLOSIVE:
		data["pod_damage"] = explosive_damage(w.def)
		emit.call(GameEvent.WEAPON_FIRED, data)
		WeaponFire.hit_with(state, dice, emit, target, arc_id, explosive_damage(w.def), attacker.id, w.def.name, hl, th.cover_hex, ["M"])
		return
	Narc.attach(state, attacker, target, hl["loc"], kind)
	data["narc_loc"] = hl["loc"]
	emit.call(GameEvent.WEAPON_FIRED, data)
