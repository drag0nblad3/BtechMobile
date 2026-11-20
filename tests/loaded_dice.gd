class_name LoadedDice
extends Dice
## Dice for tests: returns queued d6 results (and pick indexes), then 6s.

var d6_queue: Array[int] = []
var pick_queue: Array[int] = []


func _init(rolls: Array = []) -> void:
	super(1)
	for r in rolls:
		d6_queue.append(int(r))


## Queue a 2d6 total (split into two dice).
func queue_2d6(total: int) -> void:
	var a := clampi(total - 1, 1, 6)
	d6_queue.append(a)
	d6_queue.append(total - a)


func d6() -> int:
	return d6_queue.pop_front() if not d6_queue.is_empty() else 6


func pick(n: int) -> int:
	return mini(pick_queue.pop_front(), n - 1) if not pick_queue.is_empty() else 0
