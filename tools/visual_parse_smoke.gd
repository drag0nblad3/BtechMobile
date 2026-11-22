extends SceneTree
## Imports and resolves the full battle view class dependency chain before
## scene-level tests. A broken class used to stall save/replay smoke indefinitely.


func _initialize() -> void:
	for path in ["res://src/view/units/unit_view.gd",
			"res://src/view/units/units_layer.gd",
			"res://src/view/battle/battle_scene.gd"]:
		var source: Variant = load(path)
		if source == null or not source is GDScript or not source.can_instantiate():
			printerr("VISUAL_PARSE_FAILED: ", path)
			quit(1)
			return
	print("visual parse smoke ok")
	quit(0)
