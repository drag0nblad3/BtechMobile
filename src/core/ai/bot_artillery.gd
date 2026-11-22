class_name BotArtillery
extends RefCounted
## Bot area-effect fire: Arrow IV (standard and homing) and Apollo saturation.
## A blast is worth its expected damage to enemies caught, minus 1.5 times
## its expected damage to friends; a distant Arrow IV counts half (the target
## has a turn to move). Homing is only worth it with a TAG designation near
## the hex. The bot never fires smoke.

const FRIEND_WEIGHT := 1.5
const DISTANT_WEIGHT := 0.5


static func applies(w: MountedWeapon) -> bool:
	return ArrowIv.is_arrow(w) or ApolloSaturation.on(w)


## Expected value of firing `w` at `e`'s hex with to-hit `th`.
static func value(state: GameState, u: Unit, w: MountedWeapon, e: Unit, th: ToHit) -> float:
	if not th.possible():
		return 0.0
	if ApolloSaturation.on(w):
		var per := ClusterTable.expected(w.def.missiles) / 3.0
		return th.chance() * per * _net(state, u, ApolloSaturation.caught(state, e.coord))
	var kind := WeaponModes.ammo_kind(w)
	if kind == ArrowSmoke.KIND:
		return 0.0
	var far := DISTANT_WEIGHT if Hex.distance(u.coord, e.coord) >= ArrowIv.DISTANT else 1.0
	if kind == ArrowHoming.KIND:
		var t := ArrowHoming.target(state, u, e.coord)
		if t == null:
			return 0.0
		var hit := th.chance()
		var others := _net(state, u, _in_hex(state, t.coord)) - _weight(u, t)
		return far * (hit * (ArrowHoming.DAMAGE * _weight(u, t) + ArrowHoming.SPLASH * others)
				+ (1.0 - hit) * ArrowHoming.SPLASH * (others + _weight(u, t)))
	var ring := 0.0
	for f in 6:
		ring += _net(state, u, _in_hex(state, Hex.neighbor(e.coord, f)))
	return far * th.chance() * (ArrowIv.CENTER * _net(state, u, _in_hex(state, e.coord)) + ArrowIv.RING * ring)


## Units a blast in `c` would reach.
static func _in_hex(state: GameState, c: Vector2i) -> Array[Unit]:
	var out: Array[Unit] = []
	var tile := state.map.get_tile(c)
	if tile == null:
		return out
	for x in state.units:
		if x.coord == c and AreaEffect.reaches(state, x, tile.level):
			out.append(x)
	return out


## Enemies count +1, friends (and the shooter) -1.5.
static func _net(_state: GameState, u: Unit, units: Array[Unit]) -> float:
	var n := 0.0
	for x in units:
		n += _weight(u, x)
	return n


static func _weight(u: Unit, x: Unit) -> float:
	return 1.0 if x.side != u.side else -FRIEND_WEIGHT


## The Arrow IV munition or Apollo mode worth most against `e`.
static func best_mode(state: GameState, u: Unit, w: MountedWeapon, e: Unit, modes: Array) -> String:
	var best: String = modes[0]
	var best_v := -INF
	for m: String in modes:
		if m == ArrowSmoke.KIND:
			continue
		w.mode = m
		var th := ToHitCalc.weapon(state, u, w, e, false)
		var v := value(state, u, w, e, th) if applies(w) else Advisor.expected_damage(w, th)
		if v > best_v:
			best_v = v
			best = m
	return best


## Does `f` have a homing Arrow IV ready to fire?
static func homing_ready(f: Unit) -> bool:
	return f.weapons.any(func(w: MountedWeapon) -> bool:
			return ArrowIv.is_arrow(w) and f.can_fire(w) and f.ammo_for(w.def, ArrowHoming.KIND) > 0)
