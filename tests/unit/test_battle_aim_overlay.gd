extends TestCase
## LOS hue and firing arcs follow existing rule outputs, even with tips off.


func test_los_colors_follow_authoritative_results() -> void:
	check_eq(AimGuideData.status(LineOfSight.none(), []), "clear")
	var cover := LineOfSight.none()
	cover["woods"] = 1
	check_eq(AimGuideData.status(cover, []), "cover")
	cover["blocked"] = true
	check_eq(AimGuideData.status(cover, []), "blocked")
	check_eq(AimGuideData.color_for("blocked"), AimGuideData.BLOCKED)


func test_to_hit_partial_cover_tints_amber() -> void:
	var to_hit := ToHit.new()
	to_hit.add("partial cover", 1, "The hill covers the legs.")
	check_eq(AimGuideData.status(LineOfSight.none(), [{"to_hit": to_hit}]), "cover")
	to_hit.impossible = "No line of sight"
	check_eq(AimGuideData.status(LineOfSight.none(), [{"to_hit": to_hit}]), "blocked")


func test_authoritative_cover_hex_is_highlighted() -> void:
	var map := open_map(6, 6)
	var source := Vector2i(1, 1)
	var goal := Vector2i(4, 2)
	var cover := Vector2i(3, 2)
	var los := LineOfSight.none()
	los["cover"] = cover
	var cells := AimGuideData.modifier_hexes(map, source, goal, los, [])
	check(cells.has(cover), "LOS cover hex is highlighted")
	check(not cells.has(source), "attacker hex is not a modifier")


func test_arc_preview_uses_firing_arc_and_respects_off_explanations() -> void:
	var state := GameState.new(open_map(8, 8))
	var u := mech("hunchback_hbk4g", 0, Vector2i(3, 3))
	state.add_unit(u)
	var overlay := BattleAimOverlay.new()
	overlay.setup(state)
	var old := GameSettings.explain_level
	GameSettings.explain_level = ExplainLevel.OFF
	overlay.show_arcs(u, u.coord, u.facing)
	check(overlay._arc.multimesh.instance_count > 0,
			"firing arcs are shown even with explanations off")
	GameSettings.explain_level = old
	overlay.free()
