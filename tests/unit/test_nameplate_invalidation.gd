extends TestCase
## Pre-declaration UI edits must invalidate nameplate forecasts even without events.


func test_selection_key_detects_silent_attack_edits() -> void:
	var a := mech("wolverine_wvr6r", 0, Vector2i.ZERO, 0, 1)
	var b := mech("wolverine_wvr6r", 0, Vector2i.ZERO, 0, 2)
	var initial := Nameplates.selection_key(a)
	check_eq(Nameplates.selection_key(a), initial)
	check(Nameplates.selection_key(b) != initial)
	check(Nameplates.selection_key(null).is_empty())
	a.torso_twist = 1
	check(Nameplates.selection_key(a) != initial)
	a.torso_twist = 0
	a.arms_flipped = true
	check(Nameplates.selection_key(a) != initial)
	a.arms_flipped = false
	a.weapons[0].mode = "changed"
	check(Nameplates.selection_key(a) != initial)
