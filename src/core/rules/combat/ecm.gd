class_name Ecm
extends RefCounted
## Guardian ECM suites (p. 200): an enemy 'Mech's working ECM jams within
## 6 hexes. Of the systems in this game, only Artemis IV is affected: if the
## attacker or its target is inside hostile ECM, Artemis launchers fire
## normally but lose their +2 cluster bonus. Streaks, targeting computers
## and AMS are unaffected. Artemis also never helps indirect fire (p. 188).
## TODO(rules): ECM is always on (it is an activated item); water-line
## blocking, Angel ECM, Narc, C3 and probes aren't modelled.

const RADIUS := 6


static func working(u: Unit) -> bool:
	return u.def.ecm_loc >= 0 and not u.ecm_lost and not u.destroyed and not u.shutdown \
			and not u.is_location_destroyed(u.def.ecm_loc)


## Is `c` inside ECM hostile to `side`?
static func hostile_at(state: GameState, side: int, c: Vector2i) -> bool:
	for u in state.units:
		if u.side != side and working(u) and Hex.distance(u.coord, c) <= RADIUS:
			return true
	return false


## Why this shot gets no Artemis bonus ("" if it does).
static func artemis_blocked(state: GameState, attacker: Unit, target: Unit, th: ToHit) -> String:
	if th.spotter_id >= 0:
		return "indirect fire gets no Artemis bonus"
	if hostile_at(state, attacker.side, attacker.coord) or hostile_at(state, attacker.side, target.coord):
		return "enemy ECM jams the Artemis guidance"
	return ""
