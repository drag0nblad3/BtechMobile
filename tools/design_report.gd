extends SceneTree
## Prints weight and free critical slots of designs whose id contains the
## first argument: godot --headless -s tools/design_report.gd -- timber


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var filter := args[0] if args.size() > 0 else ""
	var db := UnitDb.load_dir()
	for def: UnitDef in db.sorted_defs():
		if not def.id.contains(filter):
			continue
		var u := Unit.new(1, def, 0, Vector2i.ZERO, 0)
		var free := []
		for loc in Location.COUNT:
			var n := 0
			for s: CritSlot in u.slots[loc]:
				if s.kind == CritSlot.Kind.EMPTY:
					n += 1
			free.append("%s%d" % [Location.code(loc), n])
		print("%s %.1f/%d t, armor %d, BV %d, free %s" % [def.id, DesignWeight.total(def), def.tonnage,
				def.total_armor(), BattleValue.of(def), " ".join(free)])
	quit()
