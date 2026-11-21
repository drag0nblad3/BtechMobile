extends SceneTree
## Run without rendering: godot --headless -s tools/vx_count_report.gd

const FILES := [
	"res://data/voxels/atlas.json",
	"res://data/voxels/wolverine.json",
	"res://data/voxels/jenner.json",
]


func _init() -> void:
	var failure := false
	for path: String in FILES:
		var model := VxModel.load_file(path)
		var voxels := model.cell_count()
		print("VX_COUNT|%s|%d|%d" % [model.id, voxels, model.parts.size()])
		if not model.errors.is_empty() or voxels < 100000 or voxels > 150000:
			failure = true
	quit(1 if failure else 0)
