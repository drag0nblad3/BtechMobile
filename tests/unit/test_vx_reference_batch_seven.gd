extends TestCase
## Twenty individually authored imported designs, reference-source batch seven.

const CHASSIS := [
	"enforcer_iii", "eris", "exhumer", "falcon_hawk", "falcon",
	"fireball", "flashfire", "gallowglas", "garm", "gravedigger",
	"grim_reaper", "ha_otoko", "hammerhands", "hatamoto_hi",
	"hatamoto_kaze", "hatamoto_ku", "hatamoto_mizo",
	"hercules", "hermes_iii", "hermit_crab"
]


func _data(chassis: String, suffix: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, suffix])


func _part(data: Dictionary, name: String) -> Dictionary:
	for p: Dictionary in data.get("parts", []):
		if p.get("name", "") == name:
			return p
	return {}


func _loft(part: Dictionary) -> Dictionary:
	for shape: Dictionary in part.get("shapes", []):
		if shape.has("loft"):
			return shape["loft"]
	return {}


func test_imported_source_is_authoritative_for_detailed_placement() -> void:
	for chassis: String in CHASSIS:
		var hi := _data(chassis, "")
		var low := _data(chassis, "_shape")
		if hi.has("source"):
			check_eq(hi["source"], "res://data/voxels/%s_shape.json" % chassis,
					"detached high-detail source %s" % chassis)
		else:
			check_eq(hi["unit"], low["unit"], "different unit %s" % chassis)
			for name: String in ["ct", "la", "ll_shin"]:
				check(_loft(_part(hi, name)) == _loft(_part(low, name)),
						"unpaired anatomy %s/%s" % [chassis, name])


func test_each_revised_loft_remains_an_actual_volume() -> void:
	for chassis: String in CHASSIS:
		var data := _data(chassis, "_shape")
		for name: String in ["ct", "la", "ll_shin"]:
			var l := _loft(_part(data, name))
			check(not l.is_empty(), "missing core volume %s/%s" % [chassis, name])
			for sec: Dictionary in l.get("sections", []):
				var pts: Array = sec.get("polygon", [])
				check(pts.size() >= 3, "collapsed ring %s/%s" % [chassis, name])
				if pts.size() < 3:
					continue
				var a := 0.0
				for i in pts.size():
					var p: Array = pts[i]
					var q: Array = pts[(i + 1) % pts.size()]
					a += float(p[0]) * float(q[1]) - float(q[0]) * float(p[1])
				check(absf(a) > 0.01, "zero area %s/%s" % [chassis, name])


func test_cannon_shell_shoulder_designs_and_unique_rigs_survive() -> void:
	for chassis: String in ["garm", "hermit_crab"]:
		var part := _part(_data(chassis, "_shape"), "lt")
		var has_shell := false
		for shape: Dictionary in part.get("shapes", []):
			if shape.has("shell"):
				has_shell = true
		check(has_shell, "replaceable-looking shoulder shell was lost: %s" % chassis)
	for chassis: String in CHASSIS:
		var data := _data(chassis, "_shape")
		for loc: String in ["hd", "ct", "lt", "rt", "la", "ra", "ll", "rl"]:
			check(not _part(data, loc).is_empty(), "lost articulated %s/%s" % [
					chassis, loc])
	for chassis: String in ["falcon", "hermit_crab"]:
		check_eq(_data(chassis, "_shape")["legs"], "digitigrade",
				"changed reverse-jointed leg rig: %s" % chassis)
