extends SceneTree
## godot --headless -s tools/map_quality_report.gd -- [seed_count] [external_board_root]
## Emits JSON lines for raw and screened generated maps, plus optional
## published-map transcriptions. Use a local mm-data/data/boards checkout.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds := clampi(int(args[0]), 1, 100) if not args.is_empty() else 3
	var terrain := TerrainDb.load_file()
	for theme in MapTheme.load_all():
		for seed_value in range(1, seeds + 1):
			var raw := MapGenerator.generate_raw(theme, Vector2i.ONE, seed_value)
			var selected := MapGenerator.generate(theme, Vector2i.ONE, seed_value, terrain)
			_report("raw", theme.id, raw, terrain)
			_report("screened", theme.id, selected, terrain)
	if args.size() >= 2:
		var refs: Dictionary = JsonFile.read("res://docs/map-reference-baseline.json")
		for entry: Dictionary in refs["boards"]:
			var path := args[1].path_join(String(entry["path"]))
			if not FileAccess.file_exists(path):
				printerr("Reference not found: ", path)
				continue
			var board := MapReferenceBoard.parse(FileAccess.get_file_as_string(path), String(entry["path"]))
			if board.is_empty():
				printerr("Unsupported reference board: ", path)
				continue
			_report("reference", String(entry["theme"]), board, terrain)
	quit()


func _report(kind: String, theme: String, board: Dictionary, terrain: TerrainDb) -> void:
	var m := MapLoader.from_dict(board, terrain)
	var report := MapTactics.assess(m)
	var mix := MapStats.new(m)
	print("MAP_QUALITY|", JSON.stringify({"kind": kind, "theme": theme, "name": m.name,
		"width": m.width, "height": m.height, "layout_seed": board.get("layout_seed", board.get("seed", -1)),
		"penalty": MapTactics.penalty(report), "tactics": report, "terrain": mix.summary()}))
