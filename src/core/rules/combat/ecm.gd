class_name Ecm
extends RefCounted
## Guardian ECM suites (p. 200): an enemy 'Mech's working ECM jams within
## 6 hexes. Of the systems in this game, only Artemis IV is affected: if the
## attacker or its target is inside hostile ECM, Artemis launchers fire
## normally but lose their +2 cluster bonus. Streaks, targeting computers
## and AMS are unaffected. Artemis also never helps indirect fire (p. 188).
## TODO(rules): ECM is always on (it is an activated item); water-line
## blocking, Angel ECM and probes aren't modelled. C3 checks ECM itself (C3).

const RADIUS := 6


## Weight and slots: a Clan suite is lighter. TODO(rules): construction data.
static func tons(def: UnitDef) -> float:
	return EcmTypes.tons(def)


static func slots(def: UnitDef) -> int:
	return EcmTypes.slots(def)


static func working(u: Unit) -> bool:
	return u.def.ecm_loc >= 0 and not u.ecm_lost and not u.destroyed and not u.shutdown \
			and not u.is_location_destroyed(u.def.ecm_loc)


## Is `c` inside ECM hostile to `side`?
static func hostile_at(state: GameState, side: int, c: Vector2i) -> bool:
	for u in state.units:
		if u.side != side and working(u) and Hex.distance(u.coord, c) <= RADIUS:
			return true
	return false


## Is `c` inside hostile Angel ECM (the only kind that degrades boosted C3)?
static func hostile_angel_at(state: GameState, side: int, c: Vector2i) -> bool:
	for u in state.units:
		if u.side != side and u.def.ecm_type == "angel_ecm" and working(u) and Hex.distance(u.coord, c) <= RADIUS:
			return true
	return false


## Angel ECM around the attacker or target stops a Streak locking on: a
## hit rolls on the Cluster Hits Table like a standard launcher (p. 200).
static func angel_blocks_streak(state: GameState, attacker: Unit, target: Unit) -> bool:
	return hostile_angel_at(state, attacker.side, attacker.coord) or hostile_angel_at(state, attacker.side, target.coord)


## Why this shot gets no Artemis bonus ("" if it does).
static func artemis_blocked(state: GameState, attacker: Unit, target: Unit, th: ToHit) -> String:
	if th.indirect:
		return "indirect fire gets no Artemis bonus"
	if hostile_at(state, attacker.side, attacker.coord) or hostile_at(state, attacker.side, target.coord):
		return "enemy ECM jams the Artemis guidance"
	if EcmInterference.jams(state, attacker):
		return "battlefield ECM interference jams the Artemis guidance"
	return ""
