class_name InfernoAmmo
extends RefCounted
## Inferno ammunition cooking off (book pp. 107, 192). A 'Mech carrying
## inferno ammo makes its own set of avoid rolls by heat: 4+ at 10, 6+ at 14,
## 8+ at 19, 10+ at 23, 12+ at 28 (alongside the normal ammo rolls). A bin
## that explodes adds 2 heat a missile left in it (30 at most) to the 'Mech
## at once, on top of the usual ammo explosion damage, and the new heat level
## brings fresh shutdown and inferno rolls straight away.
## TODO(rules): an Arrow IV shot counts as one missile; inferno bins are left
## out of the normal ammo explosion roll.

const KIND := "inferno"
const HEAT_PER_MISSILE := 2
const MAX_HEAT := 30


static func avoid(heat: int) -> int:
	if heat >= 28:
		return 12
	if heat >= 23:
		return 10
	if heat >= 19:
		return 8
	if heat >= 14:
		return 6
	if heat >= 10:
		return 4
	return 0


static func is_inferno(bin: AmmoBin) -> bool:
	return bin.kind == KIND


static func _worst(u: Unit) -> AmmoBin:
	var best: AmmoBin = null
	for a in u.ammo:
		if is_inferno(a) and not a.destroyed and a.shots > 0 and (best == null or a.shots > best.shots):
			best = a
	return best


## Heat Phase: inferno avoid rolls, repeated while explosions raise the heat.
static func check(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	var last := -1
	while not u.destroyed and u.heat != last:
		last = u.heat
		var bin := _worst(u)
		var need := ExtremeTemp.avoid(avoid(u.heat), state.conditions)
		if bin == null or need == 0:
			return
		var roll := dice.roll_2d6() if need < 99 else 0
		emit.call(GameEvent.HEAT_ROLL, {"unit_id": u.id, "kind": "inferno", "roll": roll, "need": need, "ok": roll >= need})
		if roll >= need:
			return
		var heat := mini(MAX_HEAT, HEAT_PER_MISSILE * bin.shots * maxi(1, bin.weapon.missiles))
		u.heat += heat
		emit.call(GameEvent.HEAT, {"unit_id": u.id, "before": u.heat - heat, "gained": heat, "sinks": 0,
				"outside": 0, "heat": u.heat, "inferno": true, "effects": HeatScale.effects_text(u.heat, state.conditions)})
		AmmoExplosion.explode(state, dice, emit, u, bin)
		if not u.shutdown and not u.destroyed:
			HeatShutdown.check(dice, emit, u, state.conditions)
