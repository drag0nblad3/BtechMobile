extends SceneTree
## Headless interaction coverage for the reworked force assembly UI.


func _initialize() -> void:
	call_deferred("_check_builder")


func _check_builder() -> void:
	change_scene_to_file("res://scenes/menu.tscn")
	await process_frame
	await process_frame
	var screen := current_scene as ForceBuilderScreen
	if not _verify(screen != null, "menu scene did not load"):
		return
	var search := screen.find_child("UnitSearch", true, false) as LineEdit
	if not _verify(search != null, "unit search missing"):
		return
	search.text = "Jenner"
	search.text_changed.emit("Jenner")
	await process_frame
	if not _verify(screen.catalog._cards.size() > 0, "search returned no Jenners"):
		return
	var candidate: UnitDef = screen.catalog._cards[0]["def"]
	if not _verify(candidate.display_name().to_lower().contains("jenner"),
			"search returned unrelated design"):
		return
	var add := screen.catalog._cards[0]["button"] as Button
	if not _verify(not add.disabled, "regular Jenner should fit in a 3000 BV force"):
		return
	add.pressed.emit()
	if not _verify(screen.builder.rosters[0].size() == 1, "Red unit was not added"):
		return
	screen._select_side(1)
	if not _verify(screen.catalog.active_side == 1, "selecting Blue did not update catalog"):
		return
	(screen.catalog._cards[0]["button"] as Button).pressed.emit()
	if not _verify(screen.builder.rosters[1].size() == 1, "Blue unit was not added"):
		return
	if not _verify(not screen._start_button.disabled, "both legal sides should enable Start"):
		return
	screen.builder.budget = 200
	screen._refresh()
	if not _verify(screen._start_button.disabled, "overspent forces cannot launch"):
		return
	screen.builder.budget = 3000
	screen._on_remove(1, 0)
	if not _verify(screen.builder.rosters[1].is_empty() and screen._start_button.disabled,
			"removing Blue prevents launch"):
		return
	print("force builder smoke ok")
	quit(0)


func _verify(ok: bool, why: String) -> bool:
	if not ok:
		printerr("force builder smoke failed: ", why)
		quit(1)
	return ok
