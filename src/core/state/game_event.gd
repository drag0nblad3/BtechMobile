class_name GameEvent
extends RefCounted
## Something that happened in the rules. Views animate events; the log and
## the explanation layer read them. Data keys per type are next to each constant.

const TURN_STARTED := &"turn_started"     # {turn}
const INITIATIVE := &"initiative"         # {rolls: {side: total}, order: [sides]}
const PHASE_CHANGED := &"phase_changed"   # {phase}
const UNIT_MOVED := &"unit_moved"         # {unit_id, from: Vector3i, path: [Vector3i], mode, mp, hexes}
const ACTIVE_SIDE := &"active_side"       # {side}
const FIRE_DECLARED := &"fire_declared"   # {unit_id, shots: [{weapon, target_id, need}]}
const WEAPON_FIRED := &"weapon_fired"     # {attacker_id, target_id, weapon, weapon_id, roll, need, hit, mods, missiles, cluster_roll?, no_ammo?}
const DAMAGE := &"damage"                 # {unit_id, source_id, source, amount, loc, rear, steps, covered, tac}
const UNIT_DESTROYED := &"unit_destroyed" # {unit_id, reason}
const HEAT := &"heat"                     # {unit_id, before, gained, sinks, heat, effects}
const HEAT_ROLL := &"heat_roll"           # {unit_id, kind: ammo|shutdown|restart, roll, need, ok}
const SHUTDOWN := &"shutdown"             # {unit_id, shutdown: bool}
const CLUB := &"club"                     # {unit_id, club: "tree"|"girder"}
const AMMO_EXPLOSION := &"ammo_explosion" # {unit_id, loc, ammo, damage, steps}
const PILOT_HIT := &"pilot_hit"           # {unit_id, hits, why}
const CONSCIOUSNESS := &"consciousness"   # {unit_id, roll, need, conscious, was_conscious}
const CRITICAL := &"critical"             # {unit_id, loc, slot, effect}
const HULL_BREACH := &"hull_breach"     # {unit_id, loc, roll (0 bare, -1 spread), flooded, effects: [String]}
const CRIT_CHECK := &"crit_check"         # {unit_id, loc, roll, crits}
const PSR := &"psr"                       # {unit_id, roll, need, ok, reasons: [String], mods}
const FALL := &"fall"                     # {unit_id, damage, levels}
const WENT_PRONE := &"went_prone"         # {unit_id} dropped prone on purpose
const STAND := &"stand"                   # {unit_id, ok}
const PHYSICAL := &"physical"             # {attacker_id, target_id, kind, limb, roll, need, hit, damage, mods}
const CHARGE_DECLARED := &"charge_declared" # {unit_id, target_id, kind: charge|dfa, need}
const SKID := &"skid"                     # {unit_id, hexes, wanted} slid after a failed roll
const DISPLACED := &"displaced"           # {unit_id, from: Vector3i, path: [Vector3i]}
const BUILDING := &"building"             # {kind: flattened|entry_failed|destroy_check|shot|cover_hit|collapsed, coord, name, unit_id?, damage?, roll?, need?}
const INTENT := &"intent"                 # {unit_id, text} why a player chose its action
const GAME_OVER := &"game_over"           # {winner: side or -1}

var type: StringName
var data: Dictionary


func _init(t: StringName, d: Dictionary = {}) -> void:
	type = t
	data = d
