extends SceneTree
## Per-chassis repair trials against actual fine geometry. Keep the lowest
## successful local hip socket and backed details; never delete a limb.
const IDS := ["ostsol", "emperor", "hatamoto_chi", "mauler", "ostroc", "trebuchet",
	"dire_wolf", "executioner", "gargoyle", "orion", "stinger", "ice_ferret",
	"stormcrow", "wasp", "akuma", "mad_dog", "howler", "jenner_voxel", "mercury",
	"thunderbolt", "grasshopper", "mongoose", "warhammer", "blackjack", "jagermech",
	"marauder", "timber_wolf", "warhawk"]
const ROOT := "res://data/voxels/"
var report := {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for id: String in IDS:
		var path := ROOT + id + ".json"
		var raw := VxFineCatalog.recipe(path)
		var original := VxModel.from_dict(raw)
		var before := _qa(original)
		var candidate: Dictionary = raw.duplicate(true)
		var current := original
		var sockets := []
		for side: String in ["ll", "rl"]:
			var hip: Dictionary = current.part(side)
			if hip.is_empty() or hip.get("joint") != "hip" or not _detached(current, side):
				continue
			var selected := _hip_trial(candidate, current, side)
			if not selected.is_empty():
				candidate = selected["recipe"]
				current = selected["model"]
				sockets.append(selected["shape"])
		var trims := _trim_trials(candidate, current)
		candidate = trims["recipe"]
		current = trims["model"]
		var after := _qa(current)
		var improved := int(after["physical"]) + int(after["rigid"]) < int(before["physical"]) + int(before["rigid"])
		if improved and _nonregression(before, after):
			_write(path, candidate)
			# Keep the existing low-tier primary lofts and all fine-grid cuts
			# intact; add only the same selected pelvis support operations.
			var shape_path := ROOT + id.trim_suffix("_voxel") + "_shape.json"
			if not sockets.is_empty() and VxRecipeStore.exists(shape_path):
				var shape: Dictionary = VxRecipeStore.read(shape_path)
				for socket: Dictionary in sockets:
					_append(shape, "ct", "add", socket)
				_write(shape_path, shape)
		else:
			after = before
			sockets.clear()
		report[id] = {"before":before, "after":after, "sockets":sockets,
			"trim_ops":trims["ops"] if improved else [], "accepted":improved and _nonregression(before, after)}
		print("FINE_REPAIR|%s|%s" % [id, JSON.stringify(report[id])])
	_write("res://docs/graphics/inherited-fine-repairs-20261124.json", report)
	quit(0)

func _qa(m: VxModel) -> Dictionary:
	return {"physical":VxIntegrity.physical_components(m)["islands"],
		"rigid":VxIntegrity.rigid_components(m)["unanchored"],
		"weak":m.quality_report.get("weak_joint_contacts", 0),
		"cells":m.cell_count(),"errors":Array(m.errors)}

func _nonregression(a: Dictionary, b: Dictionary) -> bool:
	return b["errors"].is_empty() and int(b["physical"]) <= int(a["physical"]) and int(b["rigid"]) <= int(a["rigid"]) and int(b["weak"]) <= int(a["weak"])

func _detached(m: VxModel, name_: String) -> bool:
	var cells := {}
	for p: Dictionary in m.parts:
		for c: Vector3i in p["cells"]:
			cells[c] = p["name"]
	var groups := VxIntegrity.components(cells)
	for i in range(1, groups.size()):
		for c: Vector3i in groups[i]:
			if cells[c] == name_:
				return true
	return false

func _hip_trial(raw: Dictionary, model: VxModel, side: String) -> Dictionary:
	var hip: Dictionary = model.part(side)
	var n := model.detail
	var pivot: Vector3 = hip["pivot"] / float(n)
	var x := roundi(pivot.x)
	var z := roundi(pivot.z)
	var top := -10000
	for c: Vector3i in hip["cells"]:
		top = maxi(top, c.y)
	var y := floori(float(top) / n)
	var ct := model.part("ct")
	if ct.is_empty():
		return {}
	# A transverse pelvis socket is part of the CT, with the hip remaining
	# articulated about its authored pivot. Try small backed sections first.
	var prior := _qa(model)
	var mat := "frame" if model._mat.has("frame") else "joint"
	for thickness: int in [2,3,4]:
		for dy: int in [0,1,-1]:
			var lo := [mini(0,x),y-1+dy,z-thickness/2]
			var hi := [maxi(-1,x),y+thickness-2+dy,z+thickness/2]
			var socket := {"box":[lo,hi],"mat":mat}
			var next := raw.duplicate(true)
			_append(next,"ct","add",socket)
			var m := VxModel.from_dict(next)
			var qa := _qa(m)
			if int(qa["physical"]) < int(prior["physical"]) and _nonregression(prior,qa) and not _detached(m,side):
				return {"recipe":next,"model":m,"shape":socket}
	return {}

func _trim_trials(raw: Dictionary, model: VxModel) -> Dictionary:
	var next := raw.duplicate(true)
	var owner := {}
	var rigs := {}
	for p: Dictionary in model.parts:
		var root_name := VxIntegrity._rig_root(model,p)
		if not rigs.has(root_name):
			rigs[root_name] = {}
		for c: Vector3i in p["cells"]:
			owner[c] = p["name"]
			rigs[root_name][c] = true
	var ops := []
	for name_: String in rigs:
		var groups := VxIntegrity.components(rigs[name_])
		for i in range(1,groups.size()):
			var g: Dictionary = groups[i]
			# Only micro-flakes (less than one coarse voxel), never a panel.
			if g.size() > 4:
				continue
			for c: Vector3i in g:
				var p: Dictionary = model.part(owner[c])
				var material: int = p["cells"][c]
				var mat_name := ""
				for key: String in model._mat:
					if int(model._mat[key]) == material:
						mat_name = key
						break
				if not mat_name in ["edge","trim","armor","plate"]:
					continue
				var v := [c.x,c.y,c.z]
				_append(next,p["name"],"detail",{"erase":[v,v]})
				ops.append({"part":p["name"],"cell":v,"material":mat_name})
	if ops.is_empty():
		return {"recipe":raw,"model":model,"ops":[]}
	var m := VxModel.from_dict(next)
	var a := _qa(model)
	var b := _qa(m)
	if _nonregression(a,b) and int(b["physical"])+int(b["rigid"]) < int(a["physical"])+int(a["rigid"]):
		return {"recipe":next,"model":m,"ops":ops}
	return {"recipe":raw,"model":model,"ops":[]}

func _append(raw: Dictionary, name_: String, key: String, op: Dictionary) -> void:
	for p: Dictionary in raw.get("parts", []):
		if p["name"] == name_:
			if not p.has(key):
				p[key] = []
			p[key].append(op)
			return

func _write(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		printerr("FINE_REPAIR_ERROR|cannot write " + path)
		return
	f.store_string(JSON.stringify(data,"  ")+"\n")
	f.close()
