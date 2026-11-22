class_name BaState
extends RefCounted
## A battle armor squad's live troopers (Unit.ba): armor left on each, or
## DEAD once a trooper is down.

const DEAD := -1

var troopers: Array[int] = []
var carried_by := -1     ## Unit id of the OmniMech it rides (AssetTransport), -1 if on foot.
var deployed_turn := -1  ## Turn it climbed down: it can't fire that turn.


func _init(spec: BaSpec = null) -> void:
	if spec != null:
		for i in spec.troopers:
			troopers.append(spec.armor)


func alive() -> int:
	return troopers.filter(func(a: int) -> bool: return a != DEAD).size()


func is_alive(i: int) -> bool:
	return i >= 0 and i < troopers.size() and troopers[i] != DEAD
