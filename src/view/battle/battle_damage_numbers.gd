class_name BattleDamageNumbers
extends Node3D
## Short-lived readable damage packets; display-only, never affects combat.
## Caps active labels for mobile and uses no gameplay RNG.

const MAX_ACTIVE := 18
const DURATION := 0.84
var _sequence := 0


static func allowed(amount: int, active: int) -> bool:
	return amount > 0 and active < MAX_ACTIVE


func spawn(at: Vector3, amount: int) -> void:
	if not allowed(amount, get_child_count()):
		return
	_sequence += 1
	var label := Label3D.new()
	label.text = "-%d" % amount
	label.font_size = 38
	label.pixel_size = 0.002
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true
	label.no_depth_test = true
	label.outline_size = 7
	label.outline_modulate = Color("#1b1920")
	label.modulate = Color("#ffc17a")
	add_child(label)
	var offset := float(posmod(_sequence * 7, 5) - 2) * 0.16
	label.global_position = at + Vector3(offset, 0.12, 0.0)
	var motion := label.create_tween().set_parallel(true)
	motion.tween_property(label, "position:y", label.position.y + 0.65, 0.68)
	motion.tween_property(label, "modulate:a", 0.0, 0.68).set_delay(0.12)
	var lifetime := label.create_tween()
	lifetime.tween_interval(DURATION)
	lifetime.tween_callback(label.queue_free)
