extends SceneTree
## Check real Control rectangles at two landscape viewport sizes.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 720)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		root.add_child(viewport)
		for screen: Control in [GameLauncher.new(), BattlePauseMenu.new(), DrillScreen.new()]:
			viewport.add_child(screen)
			for frame in 4:
				await process_frame
			var bounds := Rect2(Vector2.ZERO, Vector2(dimensions))
			var count := 0
			for node in screen.find_children("*", "Button", true, false):
				var button := node as Button
				if not button.is_visible_in_tree():
					continue
				count += 1
				if not bounds.encloses(button.get_global_rect()):
					printerr("LAYOUT_FAILED ", dimensions, " ", screen.get_script().resource_path,
						" ", button.text, " ", button.get_global_rect())
					quit(1)
					return
			if count < 5:
				printerr("LAYOUT_FAILED: missing controls")
				quit(1)
				return
			if screen is GameLauncher:
				if screen.find_child("VoxelLabButton", true, false) != null or screen.find_child("VxShowcaseButton", true, false) != null:
					printerr("LAYOUT_FAILED: development labs exposed")
					quit(1)
					return
				var first := screen.find_child("TrainingButton", true, false) as Button
				var second := screen.find_child("CampaignButton", true, false) as Button
				if first == null or second == null or second.get_global_rect().position.x < first.get_global_rect().end.x:
					printerr("LAYOUT_FAILED: launcher not using two columns")
					quit(1)
					return
			screen.free()
		for screen: Control in [TrainingScreen.new(), CampaignScreen.new(), MapCampaignScreen.new(),
				TechnicalReadout.new(), SaveSlotScreen.new()]:
			viewport.add_child(screen)
			for frame in 4:
				await process_frame
			var back := screen.find_child("MenuBack", true, false) as Button
			var scroll := screen.find_child("ScreenScroll", true, false) as ScrollContainer
			var bounds := Rect2(Vector2.ZERO, Vector2(dimensions))
			if back == null or scroll == null or not bounds.encloses(back.get_global_rect()) \
					or scroll.size.x < dimensions.x * 0.9 or scroll.size.y < 400.0:
				printerr("LAYOUT_FAILED: narrow screen or inaccessible Back ", screen.get_script().resource_path)
				quit(1)
				return
			screen.free()
		viewport.free()
	print("landscape layout smoke ok")
	quit(0)
