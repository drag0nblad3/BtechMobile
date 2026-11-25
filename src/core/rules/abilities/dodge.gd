class_name Dodge
extends RefCounted
## Dodge (Campaign Operations p. 74): a MechWarrior attacked physically makes
## one special Piloting roll (all the usual Piloting modifiers) when the first
## physical attack against it is rolled that turn. Each physical attack
## whose margin of success is lower than the dodge's misses. A failed dodge
## roll doesn't knock the 'Mech down.
## TODO(rules): applies to punches, kicks, pushes and melee weapons, not to
## charges or death from above; a prone or immobile 'Mech can't dodge.


## The dodge margin for `t` this phase (rolled once, kept in `margins`), or
## null when it doesn't dodge.
static func margin(state: GameState, dice: Dice, emit: Callable, t: Unit, margins: Dictionary) -> Variant:
	if not Spa.has(t, Spa.DODGE) or t.prone or ToHitCalc.is_immobile(t) or t.def.is_support():
		return null
	if not margins.has(t.id):
		var th := Psr.standing_mods(t)
		var r := dice.roll_2d6()
		emit.call(GameEvent.PSR, {"unit_id": t.id, "roll": r, "need": th.target(), "ok": r >= th.target(),
				"reason": "dodge", "mods": th.mods, "no_fall": true})
		margins[t.id] = r - th.target()
	return margins[t.id]


## True when the dodge beats an attack that hit with `roll` against `need`.
static func beats(dodge_margin: Variant, roll: int, need: int) -> bool:
	return dodge_margin != null and int(dodge_margin) > roll - need
