extends TestCase
## Source-contrast tests for measured Conjurer / Dominator likeness.
## Use relative contour dimensions and published weapon locations, not authored coordinates.


static func _recipe(id: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/" + id + ".json")


static func _part(d: Dictionary, name: String) -> Dictionary:
	for p: Dictionary in d["parts"]:
		if String(p.get("name", "")) == name:
			return p
	return {}


static func _max_height(part: Dictionary) -> float:
	var y := -INF
	for s: Dictionary in part.get("shapes", []):
		if s.has("box"):
			y = maxf(y, float(s["box"][1][1]))
		if s.has("loft") and String(s["loft"].get("axis", "y")) == "y":
			for st: Dictionary in s["loft"]["sections"]:
				y = maxf(y, float(st["at"]))
	return y


static func _front_depth(part: Dictionary) -> float:
	var front := INF
	for s: Dictionary in part.get("shapes", []):
		if s.has("box"):
			front = minf(front, float(s["box"][0][2]))
		if s.has("loft") and String(s["loft"].get("axis", "y")) == "z":
			for st: Dictionary in s["loft"]["sections"]:
				front = minf(front, float(st["at"]))
		if s.has("loft") and String(s["loft"].get("axis", "y")) == "y":
			for st: Dictionary in s["loft"]["sections"]:
				for vertex: Array in st["polygon"]:
					front = minf(front, float(vertex[1]))
	return front


func test_dominator_long_rt_laser_contrasts_conjurer_short_rt_emitters() -> void:
	var dominator := _recipe("dominator")
	var conjurer := _recipe("hellhound_conjurer")
	check(_front_depth(_part(dominator, "rt")) < _front_depth(_part(conjurer, "rt")),
		"Dominator shoulder laser needs a much longer forward side silhouette")
	var tip: Array = dominator["muzzles"]["RT"]
	check(float(tip[2]) < _front_depth(_part(conjurer, "rt")),
		"ER large laser muzzle must lie ahead of Conjurer's torso laser mouths")
	var official: Dictionary = JsonFile.read("res://data/units/dominator.json")
	check("c_er_large_laser" in official["equipment"]["RT"],
		"protrusion belongs to official RT laser, not invented shoulder armor")


func test_conjurer_horns_overhead_and_dominator_head_inset() -> void:
	var c := _recipe("hellhound_conjurer")
	var d := _recipe("dominator")
	check(_max_height(_part(c, "hd")) > _max_height(_part(c, "rt")),
		"Conjurer twin raked sensors clearly rise above armored shoulders")
	check(_max_height(_part(d, "hd")) < _max_height(_part(d, "lt")),
		"Dominator low visor is recessed beneath left missile shoulder")


func test_pair_sculpt_ports_remain_hollow_and_all_mass_supported() -> void:
	for id in ["hellhound_conjurer", "dominator"]:
		var data := _recipe(id)
		data["subdivide"] = 1
		var model := VxModel.from_dict(data)
		check(model.errors.is_empty(), id + " geometry loads")
		check_eq(int(model.quality_report.get("floating_islands", -1)), 0,
			id + " floating geometry is prohibited")
		check_eq(int(model.quality_report.get("weak_joint_contacts", -1)), 0,
			id + " moving joints require backed contacts")
	var m := VxModel.from_dict(_recipe("dominator"))
	var muzzle: Array = m.muzzles[Location.RT]
	check_eq(muzzle.size(), 1, "Dominator right torso laser has one muzzle")
	var center: Vector3i = Vector3i(floori(muzzle[0].x), floori(muzzle[0].y), floori(muzzle[0].z))
	check(not (m.parts_at(Location.RT)[0]["cells"] as Dictionary).has(center),
		"Dominator RT gun bore cannot be occluded by front face")
