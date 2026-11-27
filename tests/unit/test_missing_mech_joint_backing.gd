extends TestCase
## Imported Mech joints must be backed masses, not floating or edge-touching.

const SAMPLE := ["arctic_wolf", "avatar", "bane", "battle_cobra",
	"glass_spider", "rattlesnake", "rattlesnake_ii", "tiburon"]


func test_imported_sculpts_have_backed_contacts_not_fake_welds() -> void:
	for id: String in SAMPLE:
		var m := VxModel.load_file("res://data/voxels/" + id + "_shape.json")
		var report: Dictionary = m.quality_report.get("joint_sculpt", {})
		check(not report.is_empty(), id + " geometry-backed socket audit")
		check(int(report.get("added", 100000)) < 240, id + " no bloated scaffold")
		var audit := VxConnectivity.audit(m)
		for fault: Dictionary in audit["faults"]:
			check(fault["type"] != "weak_joint", id + " unbacked joint: " + str(fault))
			check(fault["type"] != "island", id + " island: " + str(fault))


func test_imported_sculpts_preserve_muzzle_and_silhouette_anchors() -> void:
	for id: String in SAMPLE:
		var path := "res://data/voxels/" + id + "_shape.json"
		var raw: Dictionary = VxRecipeStore.read(path)
		var m := VxModel.load_file(path)
		check_eq(m.legs, raw.get("legs", "plantigrade"), id + " gait")
		check_eq(m.muzzles.size(), raw.get("muzzles", {}).size(), id + " mounts")
		check_eq(m.weapons.size(), raw.get("weapons", []).size(), id + " weapon recognition")
