class_name MissionState
extends RefCounted
## Running mission bookkeeping on GameState. `def` is null for a plain
## last-side-standing battle.

var def: Mission = null
var vp: Dictionary = {}            ## side -> Victory Points scored during play
var crippled: Dictionary = {}      ## unit id -> reason
var torso_saved: Dictionary = {}   ## unit id -> true: passed the roll to ignore a lost torso
var withdraw_from: Dictionary = {} ## unit id -> distance to its home edge at turn start
var withdraw_fails: Dictionary = {}## unit id -> turns in a row it couldn't get closer
var exited: Dictionary = {}        ## unit id -> "withdraw" | "mission"
var scans: Dictionary = {}        ## unit id -> enemy 'Mechs it has scanned (Sensor Check)
var last_turn: int = 0             ## Random Duration: the mission ends after this turn (0 = not set)


func add_vp(side: int, n: int) -> void:
	vp[side] = int(vp.get(side, 0)) + n


func is_crippled(u: Unit) -> bool:
	return crippled.has(u.id)


## On the map and still fighting: not destroyed, not gone, and not withdrawing.
func remains(u: Unit) -> bool:
	if u.destroyed or exited.has(u.id):
		return false
	return not (def != null and def.forced_withdrawal and crippled.has(u.id))
