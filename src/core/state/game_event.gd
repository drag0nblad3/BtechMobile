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
const UNJAM := &"unjam"                   # {unit_id, weapon, roll, need, ok, why?} clearing a rotary AC
const CLUB := &"club"                     # {unit_id, club: "tree"|"girder"}
const CAPACITOR := &"capacitor"           # {unit_id, weapon} a PPC capacitor took a charge
const TAG := &"tag"                       # {unit_id, target_id, roll, need, hit, mods, why?} TAG designation
const AMMO_EXPLOSION := &"ammo_explosion" # {unit_id, loc, ammo, damage, steps}
const PILOT_HIT := &"pilot_hit"           # {unit_id, hits, why}
const CONSCIOUSNESS := &"consciousness"   # {unit_id, roll, need, conscious, was_conscious}
const CRITICAL := &"critical"             # {unit_id, loc, slot, effect}
const HULL_BREACH := &"hull_breach"     # {unit_id, loc, roll (0 bare, -1 spread), flooded, effects: [String]}
const CRIT_CHECK := &"crit_check"         # {unit_id, loc, roll, crits}
const PSR := &"psr"                       # {unit_id, roll, need, ok, reasons: [String], mods}
const FALL := &"fall"                     # {unit_id, damage, levels}
const WENT_PRONE := &"went_prone"         # {unit_id} dropped prone on purpose
const HEAT_SINKS_SWITCHED := &"heat_sinks_switched"  # {unit_id, off}
const STEALTH := &"stealth"  # {unit_id, on}
const MASC := &"masc"                     # {unit_id, roll, need, ok, next}
const STAND := &"stand"                   # {unit_id, ok}
const PHYSICAL := &"physical"             # {attacker_id, target_id, kind, limb, roll, need, hit, damage, mods}
const CHARGE_DECLARED := &"charge_declared" # {unit_id, target_id, kind: charge|dfa, need}
const SKID := &"skid"                     # {unit_id, hexes, wanted} slid after a failed roll
const DISPLACED := &"displaced"           # {unit_id, from: Vector3i, path: [Vector3i]}
const MINEFIELD := &"minefield"           # {kind: laid|triggered|cleared|survived, coord, side, unit_id?, roll?, need?, hit?, groups?, density?}
const BUILDING := &"building"             # {kind: flattened|entry_failed|destroy_check|shot|cover_hit|collapsed, coord, name, unit_id?, damage?, roll?, need?}
const INTENT := &"intent"                 # {unit_id, text} why a player chose its action
const SENSOR_CHECK := &"sensor_check"     # {unit_id, roll, need, ok, why, mods}
const DESTROY_CHECK := &"destroy_check"   # {unit_id, damage, roll, bonus, need, destroyed, auto, by, degraded?, check?} an Asset (DestroyCheck)
const VEHICLE := &"vehicle"                 # {kind: motive|crit, unit_id, roll, ...} combat vehicle damage effects
const TRANSPORT := &"transport"         # {unit_id, carrier_id, kind: board|deploy|thrown} infantry and its APC (AssetTransport)
const CRIPPLED := &"crippled"             # {unit_id, why, withdraw: bool}
const UNIT_EXITED := &"unit_exited"       # {unit_id, kind: withdraw|mission, vp}
const MISSION := &"mission"               # {kind: vp, side, vp, total} | {kind: duration, roll, ends_on, last}
const SCAN := &"scan"                     # {unit_id, roll, need, ok, mods, target_id? count?, hex? intel_roll? vp? total?}
const OBJECTIVE := &"objective"           # {kind: picked_up|dropped|pushed|fragile|confirmed|useless, hex, unit_id?, why?, roll?, broke?}
const WAVE := &"wave"                     # {side, roll, need, arrived}
const COMBAT_DROP := &"combat_drop"       # {unit_id, aim, hex, margin}
const UNIT_REVEALED := &"unit_revealed"   # {unit_id, why, by_enemy} a hidden unit comes out
const POINT_BLANK := &"point_blank"       # {unit_id, target_id, fired: bool} a found unit's ambush shot
const CONDITIONS := &"conditions"         # {names: [String]} battlefield conditions, at the start
const GAME_OVER := &"game_over"           # {winner: side or -1, why, scores?: {side: vp}}

var type: StringName
var data: Dictionary


func _init(t: StringName, d: Dictionary = {}) -> void:
	type = t
	data = d
