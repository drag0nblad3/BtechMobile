extends SceneTree
## Exact inherited physical and rigid fragments after the engine recipe loader.
const IDS := ["ostsol", "emperor", "hatamoto_chi", "mauler", "ostroc", "trebuchet",
	"dire_wolf", "executioner", "gargoyle", "orion", "stinger", "ice_ferret",
	"stormcrow", "wasp", "akuma", "mad_dog", "howler", "jenner_voxel", "mercury",
	"thunderbolt", "grasshopper", "mongoose", "warhammer", "blackjack", "jagermech",
	"marauder", "timber_wolf", "warhawk"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for id: String in IDS:
		var m := VxModel.load_file("res://data/voxels/" + id + ".json")
		var own := {}
		var rigs := {}
		for p: Dictionary in m.parts:
			var root_name := VxIntegrity._rig_root(m, p)
			if not rigs.has(root_name):
				rigs[root_name] = {}
			for c: Vector3i in p["cells"]:
				own[c] = p["name"]
				rigs[root_name][c] = true
		var physical := _summarize(VxIntegrity.components(own), own, m)
		var rigid := {}
		for name_: String in rigs:
			var groups := VxIntegrity.components(rigs[name_])
			if groups.size() > 1:
				rigid[name_] = _summarize(groups, own, m)
		print("INHERITED|%s|%s" % [id, JSON.stringify({"detail":m.detail,
			"physical":physical,"rigid":rigid,"errors":Array(m.errors)})])
	quit(0)

func _summarize(groups: Array[Dictionary], own: Dictionary, m: VxModel) -> Array:
	var rows := []
	for i in range(1, groups.size()):
		var g: Dictionary = groups[i]
		var parts := {}
		var mats := {}
		var low := Vector3i(100000, 100000, 100000)
		var high := -low
		for c: Vector3i in g:
			var p: Dictionary = m.part(own[c])
			parts[p["name"]] = int(parts.get(p["name"], 0)) + 1
			var mat: int = p["cells"][c]
			mats[str(mat)] = int(mats.get(str(mat), 0)) + 1
			low = Vector3i(mini(low.x,c.x),mini(low.y,c.y),mini(low.z,c.z))
			high = Vector3i(maxi(high.x,c.x),maxi(high.y,c.y),maxi(high.z,c.z))
		rows.append({"cells":g.size(),"parts":parts,"materials":mats,
			"low":[low.x,low.y,low.z],"high":[high.x,high.y,high.z]})
	return rows
