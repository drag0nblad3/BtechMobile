extends TestCase
## Screen-space collision layout, independent of battle state and render hardware.

const BOUNDS := Rect2(10, 10, 1260, 700)


func _rows(rects: Array[Rect2]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in rects.size():
		result.append({"id": i, "rect": rects[i]})
	return result


func _assert_clear(rows: Array[Dictionary], offsets: Dictionary, bounds: Rect2) -> void:
	var placed: Array[Rect2] = []
	for row: Dictionary in rows:
		var r: Rect2 = row["rect"]
		r.position += Vector2(offsets[row["id"]])
		check(bounds.encloses(r), "Plate stays on screen")
		for other: Rect2 in placed:
			check(not r.intersects(other), "Plates must not overlap")
		placed.append(r)


func test_unobstructed_plates_keep_anchor() -> void:
	var rects: Array[Rect2] = [Rect2(100, 100, 150, 50), Rect2(500, 300, 170, 66)]
	var rows := _rows(rects)
	var offsets := NameplateLayout.solve(rows, BOUNDS)
	check_eq(offsets[0], Vector2.ZERO)
	check_eq(offsets[1], Vector2.ZERO)
	_assert_clear(rows, offsets, BOUNDS)


func test_dense_cluster_and_selected_priority() -> void:
	var rects: Array[Rect2] = []
	for i in 12:
		rects.append(Rect2(550 + i % 3 * 3, 300 + i % 4 * 2, 164, 66))
	var rows := _rows(rects)
	var offsets := NameplateLayout.solve(rows, BOUNDS)
	check_eq(offsets[0], Vector2.ZERO)
	_assert_clear(rows, offsets, BOUNDS)
	check_eq(NameplateLayout.solve(rows, BOUNDS), offsets, "Stable deterministic placement")


func test_edges_and_return_to_anchor() -> void:
	var rects: Array[Rect2] = [Rect2(-40, 5, 150, 50), Rect2(-30, 10, 150, 50), Rect2(1200, 690, 150, 50)]
	var rows := _rows(rects)
	var offsets := NameplateLayout.solve(rows, BOUNDS)
	_assert_clear(rows, offsets, BOUNDS)
	var separated: Array[Rect2] = [Rect2(200, 200, 150, 50), Rect2(800, 200, 150, 50)]
	var clear := NameplateLayout.solve(_rows(separated), BOUNDS, offsets)
	check_eq(clear[0], Vector2.ZERO)
	check_eq(clear[1], Vector2.ZERO)


func test_easing_is_gentle_and_frame_rate_independent() -> void:
	var target := Vector2(100, -50)
	var a := NameplateLayout.ease(Vector2.ZERO, target, 0.1)
	check(a.length() > 0.0 and a.length() < target.length())
	var b := NameplateLayout.ease(NameplateLayout.ease(Vector2.ZERO, target, 0.05), target, 0.05)
	check(a.distance_to(b) < 0.001)
	check_eq(NameplateLayout.ease(Vector2.ZERO, target, 0.0), Vector2.ZERO)
	check_eq(NameplateLayout.ease(target, target, 1.0), target)
