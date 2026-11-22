extends TestCase
## Overlay colors represent distinct states; rules own LOS and MP arithmetic.


func test_tactical_states_are_distinct() -> void:
	check(HexHighlighter.SELECTED != HexHighlighter.TARGET)
	check(HexHighlighter.PATH != HexHighlighter.CONTESTED)
	check(HexHighlighter.LOS_BLOCKED != HexHighlighter.LOS_CLEAR)
	check(HexHighlighter.COVER != HexHighlighter.TARGET)


func test_move_heat_preview_uses_rules() -> void:
	check_eq(MoveMode.heat(MoveMode.Kind.WALK, 2), 1)
	check_eq(MoveMode.heat(MoveMode.Kind.RUN, 4), 2)
	check_eq(MoveMode.heat(MoveMode.Kind.JUMP, 5), JumpJets.heat(5, false))
