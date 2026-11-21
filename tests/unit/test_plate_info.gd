extends TestCase
## Nameplate contents: who the selected 'Mech can see, health, best to-hit.


func _state(tokens: Array) -> GameState:
	var rows := []
	for t in tokens:
		rows.append("c0 %s c0" % t)
	return GameState.new(make_map(rows))


func test_plates_follow_line_of_sight() -> void:
	var s := _state(["c0", "c0", "c3", "c0", "c0"])  # a level 3 hill between
	var a := mech("griffin_grf1n", 0, hex_at(1, 0), 3, 1)
	var b := mech("wolverine_wvr6r", 1, hex_at(1, 4), 0, 2)
	var c := mech("jenner_jr7d", 1, hex_at(0, 1), 0, 3)
	for u in [a, b, c]:
		s.add_unit(u)
	var seen := PlateInfo.visible_from(s, a)
	check(seen.has(a), "own plate")
	check(not seen.has(b), "hill blocks the Wolverine")
	check(seen.has(c), "Jenner in sight")
	check(PlateInfo.visible_from(s, null).is_empty(), "no selection, no plates")
	c.destroyed = true
	check(not PlateInfo.visible_from(s, a).has(c), "wrecks get no plate")


func test_health_and_bar() -> void:
	var u := mech("griffin_grf1n", 0, Vector2i(0, 0))
	check_eq(PlateInfo.health(u), 1.0)
	check_eq(PlateInfo.bar(1.0), "■■■■■■■■■■ 100%")
	for loc in Location.COUNT:
		u.armor[loc] = 0
		u.rear_armor[loc] = 0
	var h := PlateInfo.health(u)
	check(h > 0.2 and h < 0.6, "structure only: %s" % h)
	check_eq(PlateInfo.bar(0.34), "■■■□□□□□□□ 34%")


func test_attack_line_for_enemies_only() -> void:
	var s := _state(["c0", "c0", "c0", "c0", "c0"])
	var a := mech("griffin_grf1n", 0, hex_at(1, 0), 3, 1)
	var b := mech("wolverine_wvr6r", 1, hex_at(1, 3), 0, 2)
	var f := mech("jenner_jr7d", 0, hex_at(0, 0), 3, 3)
	for u in [a, b, f]:
		s.add_unit(u)
	var atk := PlateInfo.attack(s, a, b)
	check(atk["weapons"] >= 1, "can shoot the Wolverine")
	check(atk["best"] >= 2 and atk["best"] <= 12, "a real to-hit")
	check(String(atk["text"]).begins_with("Hit %d+" % atk["best"]), atk["text"])
	check_eq(PlateInfo.attack(s, a, f)["text"], "", "no attack line on a friend")
	a.facing = 0  # facing away: nothing bears
	check_eq(PlateInfo.attack(s, a, b)["text"], "Out of reach")
