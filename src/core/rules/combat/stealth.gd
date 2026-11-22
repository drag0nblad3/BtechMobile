class_name Stealth
extends RefCounted
## Stealth armor (book pp. 202, 209). An activated system: it starts the game
## on and may be switched off or on in the End Phase. It only works while the
## 'Mech's ECM suite does. While on, its own ECM stops jamming, the 'Mech acts
## as if inside hostile ECM (Artemis, probes) and can't use C3; attacks on
## it are +1 at medium range and +2 at long range, it can't be a secondary
## target, and it builds 10 heat each turn.
## TODO(rules): hidden units with stealth vs probes aren't modelled; the bot
## never switches it off.

const HEAT := 10
const MEDIUM := 1
const LONG := 2


static func has(def: UnitDef) -> bool:
	return def.armor_type == "stealth"


## Is the stealth system working now?
static func active(u: Unit) -> bool:
	return has(u.def) and not u.stealth_off and Ecm.suite_ok(u)


## Why `u` can't ask to switch it on/off ("" = it can).
static func problem(u: Unit) -> String:
	if not has(u.def):
		return "no stealth armor"
	if u.destroyed:
		return "destroyed"
	return ""


## The setting from the next End Phase: true = off.
static func planned_off(u: Unit) -> bool:
	return u.stealth_off if u.stealth_request < 0 else u.stealth_request == 0


## End Phase: carries out a pending request.
static func apply(emit: Callable, u: Unit) -> void:
	if u.stealth_request < 0:
		return
	var off := u.stealth_request == 0
	u.stealth_request = -1
	if off == u.stealth_off:
		return
	u.stealth_off = off
	emit.call(GameEvent.STEALTH, {"unit_id": u.id, "on": not off})


## Heat the system builds this turn.
static func heat(u: Unit) -> int:
	return HEAT if active(u) else 0


## The range modifier for an attack on `target` at bracket `br`.
static func add_mods(th: ToHit, target: Unit, br: int) -> void:
	if not active(target):
		return
	if br == WeaponDef.Bracket.MEDIUM:
		th.add("stealth armor", MEDIUM, "Its stealth armor blurs sensors: +1 at medium range, +2 at long. Get closer.")
	elif br == WeaponDef.Bracket.LONG:
		th.add("stealth armor", LONG, "Its stealth armor blurs sensors: +2 at long range, +1 at medium. Get closer.")
