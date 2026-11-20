class_name GameEvent
extends RefCounted
## Something that happened in the rules. Views animate events; the log
## records them. Data keys per type are documented next to each constant.

const TURN_STARTED := &"turn_started"     # {turn}
const INITIATIVE := &"initiative"         # {rolls: {side: total}, order: [sides]}
const PHASE_CHANGED := &"phase_changed"   # {phase}
const UNIT_MOVED := &"unit_moved"         # {unit_id, from: Vector3i, path: [Vector3i], mode, mp}
const ACTIVE_SIDE := &"active_side"       # {side}

var type: StringName
var data: Dictionary


func _init(t: StringName, d: Dictionary = {}) -> void:
	type = t
	data = d
