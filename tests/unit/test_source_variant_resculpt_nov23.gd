extends TestCase
## Variant overlays must follow the parent sculpt without leftover weapon noses.

static func _read(name: String) -> Dictionary:
    return VxRecipeStore.read("res://data/voxels/" + name + ".json")


func test_conjurer_7_uses_rebuilt_parent_pulse_gun_origin() -> void:
    var base := _read("hellhound_conjurer")
    var variant := _read("hellhound_conjurer_7")
    check_eq(variant["muzzles"]["RA"], base["muzzles"]["RA"],
        "variant uses same physical long gun as standard Conjurer")


func test_dominator_2_removes_all_of_replaced_ppc() -> void:
    var base := _read("dominator")
    var variant := _read("dominator_2")
    var body: Dictionary
    for p: Dictionary in base["parts"]:
        if p["name"] == "ra":
            body = p
    var nose := 0
    var tail := 0
    for s: Dictionary in body["shapes"]:
        if s.has("loft") and str(s["loft"].get("axis", "")) == "z":
            var stations: Array = s["loft"]["sections"]
            nose = int(stations.front()["at"])
            tail = int(stations.back()["at"])
    var eraser: Array
    for entry: Dictionary in variant["part_overlays"]:
        if entry["part"] == "ra":
            eraser = entry["shapes"][0]["erase"]
    check(not eraser.is_empty(), "variant must replace old PPC mass")
    if not eraser.is_empty():
        check(int(eraser[0][2]) <= nose and int(eraser[1][2]) >= tail,
            "variant cutout covers both the parent PPC muzzle and shoulder tube")
    check_eq(variant["muzzles"]["HD"], base["muzzles"]["HD"],
        "both Dominator variants have a rear-firing head laser")
    check((variant["muzzles"]["RA"] as Array).size() == 2,
        "variant retains both ER arm laser origins")


func test_variant_rig_and_joint_support_after_source_resculpt() -> void:
    for id in ["dominator_2", "hellhound_conjurer_7", "koshi_standard_2", "koshi_standard_3"]:
        var model := VxModel.load_file("res://data/voxels/" + id + ".json")
        check(model.errors.is_empty(), id + " still resolves parent and overlay")
        check_eq(int(model.quality_report.get("floating_islands", -1)), 0,
            id + " creates no floating remnants after overlay replacement")
        check_eq(int(model.quality_report.get("weak_joint_contacts", -1)), 0,
            id + " retains supported moving assemblies")
