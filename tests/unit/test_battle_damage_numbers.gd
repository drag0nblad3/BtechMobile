extends TestCase
## Damage feedback must remain packet-based, bounded and visual-only.


func test_damage_number_cap_and_nonpositive_amount() -> void:
	check_eq(BattleDamageNumbers.MAX_ACTIVE, 18)
	check(BattleDamageNumbers.allowed(5, 0))
	check(BattleDamageNumbers.allowed(5, 17))
	check(not BattleDamageNumbers.allowed(5, 18))
	check(not BattleDamageNumbers.allowed(0, 0))
	check(not BattleDamageNumbers.allowed(-1, 0))


func test_damage_feedback_does_not_modify_record_sheets() -> void:
	var node := BattleDamageNumbers.new()
	check_eq(node.get_child_count(), 0)
	check_eq(node._sequence, 0)
	node.free()
