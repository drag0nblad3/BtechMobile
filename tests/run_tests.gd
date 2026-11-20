extends SceneTree
## Headless test runner:
##   godot --headless --import            (first run only, builds class cache)
##   godot --headless -s tests/run_tests.gd [-- filter]
## Runs every test_* method in tests/unit/test_*.gd. Exit code 1 on failure.


func _init() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filter = args[0]
	var total := 0
	var failed: Array[String] = []
	for f in DirAccess.get_files_at("res://tests/unit"):
		if not f.begins_with("test_") or not f.ends_with(".gd"):
			continue
		if filter != "" and not f.contains(filter):
			continue
		var script: GDScript = load("res://tests/unit/" + f)
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			var tc: TestCase = script.new()
			tc._current = "%s.%s" % [f.get_basename(), name]
			tc.call(name)
			total += 1
			failed.append_array(tc.failures)
	for msg in failed:
		printerr("FAIL ", msg)
	print("%d tests, %d failures" % [total, failed.size()])
	quit(1 if failed.size() > 0 else 0)
