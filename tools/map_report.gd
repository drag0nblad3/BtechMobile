extends SceneTree
## Prints generated maps as text with their terrain mix, for tuning
## data/map_themes.json:
##   godot --headless -s tools/map_report.gd -- [theme] [seed] [sheets_wide] [sheets_high]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_value := int(args[1]) if args.size() > 1 else 1
	var sheets := Vector2i(int(args[2]) if args.size() > 2 else 2, int(args[3]) if args.size() > 3 else 1)
	var terrain := TerrainDb.load_file()
	for t in MapTheme.load_all():
		if args.size() > 0 and args[0] != "all" and args[0] != t.id:
			continue
		var d := MapGenerator.generate(t, sheets, seed_value)
		var m := MapLoader.from_dict(d, terrain)
		print("== %s, %s" % [d["name"], MapGenerator.size_name(sheets)])
		for row: String in d["rows"]:
			print(_compact(row))
		print(MapStats.new(m).summary())
	quit()


## One character per hex: terrain token, or B for a building, digit = level.
static func _compact(row: String) -> String:
	var out := ""
	for tok in row.split(" "):
		out += tok.substr(0, 2) + " "
	return out
