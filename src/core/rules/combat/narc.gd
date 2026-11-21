class_name Narc
extends RefCounted
## Narc missile beacons (book p. 188). A beacon hit attaches a homing pod to
## the location struck (no damage); the pod lasts until that location is
## destroyed. From the next turn, the pod's side firing Narc-equipped
## missiles (`ammo:<launcher>:narc`) at that 'Mech gets -1 to hit and +2 on
## the cluster roll, unless the 'Mech stands in ECM hostile to that side.
## Narc ammo explodes for 2 a pod.
## TODO(rules): indirect fire at a pod without a spotter; iNarc and special
## pods; AMS against pods; the computer doesn't fire beacons.

const KIND := "narc"
const TO_HIT_MOD := -1
const CLUSTER_BONUS := 2


## Flags launchers that have Narc-equipped ammo and loads it if that's all there is.
static func setup_ammo(u: Unit) -> void:
	for w in u.weapons:
		w.narc_ammo = u.ammo.any(func(a: AmmoBin) -> bool: return a.weapon == w.def and a.kind == KIND)
		if w.narc_ammo and u.ammo_for(w.def) == 0:
			w.mode = KIND


## Does `attacker`'s side have a working pod on `target`?
static func homing(state: GameState, attacker: Unit, target: Unit) -> bool:
	if Ecm.hostile_at(state, attacker.side, target.coord):
		return false
	for p: Dictionary in target.narc_pods:
		if p["side"] == attacker.side and p["turn"] < state.turn and not target.is_location_destroyed(p["loc"]):
			return true
	return false


## Narc-equipped missiles homing on a pod: the -1 to hit.
static func add(th: ToHit, state: GameState, attacker: Unit, w: MountedWeapon, target: Unit) -> void:
	if WeaponModes.ammo_kind(w) != KIND or not homing(state, attacker, target):
		return
	th.narc_homing = true
	th.add("Narc homing pod", TO_HIT_MOD, "A Narc pod on the target guides these missiles in: -1 to hit and +2 on the cluster roll.")


static func attach(state: GameState, attacker: Unit, target: Unit, loc: int) -> void:
	target.narc_pods.append({"side": attacker.side, "loc": loc, "turn": state.turn})
