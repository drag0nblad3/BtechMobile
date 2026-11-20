class_name HeadHit
extends RefCounted
## Every hit that deals damage to the head also hurts the MechWarrior, even
## if the armor holds (book p. 117): three SRMs to the head are three hits.


static func check(dice: Dice, emit: Callable, u: Unit, steps: Array[Dictionary]) -> void:
	if steps.is_empty():
		return
	var st: Dictionary = steps[0]
	if int(st["loc"]) == Location.HEAD and int(st["armor"]) + int(st["structure"]) > 0:
		PilotDamage.wound(dice, emit, u, 1, "head hit")
