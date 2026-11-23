extends TestCase
## Reference-led silhouette regressions for the Conjurer, Dominator,
## Koshi BattleMech and Solitaire. Checks relative structure, not absolute
## author coordinates, so genuine further resculpts remain possible.

const CHASSIS := [
    "hellhound_conjurer", "dominator", "solitaire", "koshi_standard"
]


static func _data(id: String) -> Dictionary:
    return JsonFile.read("res://data/voxels/" + id + ".json")


static func _part(recipe: Dictionary, name: String) -> Dictionary:
    for p: Dictionary in recipe.get("parts", []):
        if String(p.get("name", "")) == name:
            return p
    return {}


static func _peak(recipe: Dictionary) -> int:
    var highest := 0
    for part: Dictionary in recipe["parts"]:
        for shape: Dictionary in part.get("shapes", []):
            if shape.has("box"):
                highest = maxi(highest, int(shape["box"][1][1]))
            elif shape.has("loft") and String(shape["loft"].get("axis", "y")) == "y":
                for section: Dictionary in shape["loft"]["sections"]:
                    highest = maxi(highest, int(section["at"]))
    return highest


static func _part_peak(part: Dictionary) -> int:
    var highest := 0
    for shape: Dictionary in part.get("shapes", []):
        if shape.has("box"):
            highest = maxi(highest, int(shape["box"][1][1]))
        elif shape.has("loft") and String(shape["loft"].get("axis", "y")) == "y":
            for section: Dictionary in shape["loft"]["sections"]:
                highest = maxi(highest, int(section["at"]))
    return highest


func test_solitaire_and_koshi_keep_long_leg_proportions() -> void:
    for id in ["solitaire", "koshi_standard"]:
        var recipe := _data(id)
        var hip: float = float(_part(recipe, "ll")["pivot"][1])
        var entire: float = float(_peak(recipe))
        check(hip / entire > 0.44,
            id + " must not return to a squat body on short legs")


func test_dominator_has_one_sided_high_missile_shoulder() -> void:
    var recipe := _data("dominator")
    var launcher := _part(recipe, "lt")
    check(_part_peak(launcher) > _part_peak(_part(recipe, "rt")),
        "left missile rack rises higher than right laser shoulder")
    check(_part_peak(launcher) > _part_peak(_part(recipe, "hd")),
        "cockpit must sit below raised missile shoulder")
    check_eq((recipe["muzzles"]["LT"] as Array).size(), 6)


func test_koshi_rear_cooling_duct_is_genuinely_hollow() -> void:
    var recipe := _data("koshi_standard")
    var duct := _part(recipe, "lt")
    var peak: int = _part_peak(duct)
    var open_top := false
    var open_front := false
    for shape: Dictionary in duct["shapes"]:
        if shape.has("erase"):
            var lo: Array = shape["erase"][0]
            var hi: Array = shape["erase"][1]
            if int(lo[1]) < peak and int(hi[1]) >= peak:
                open_top = true
            if int(hi[1]) < peak and int(hi[2]) > int(lo[2]):
                open_front = true
    check(open_top and open_front,
        "hollow intake must have both roof cavity and front ventilation")


func test_conjurer_cannon_and_head_horns_are_not_generic_blocks() -> void:
    var recipe := _data("hellhound_conjurer")
    var head := _part(recipe, "hd")
    var horns := 0
    for shape: Dictionary in head["shapes"]:
        if shape.has("box") and shape.get("mat", "") == "cannon":
            horns += 1
    check(horns >= 6, "separate outward-raked paired sensor horns")
    var right_arm := _part(recipe, "ra")
    var tapered_tube := false
    for shape: Dictionary in right_arm["shapes"]:
        if shape.has("loft") and String(shape["loft"].get("axis", "")) == "z":
            tapered_tube = true
    check(tapered_tube, "Conjurer cannon profile must vary with depth")


func test_source_resculpts_keep_connected_articulated_parts() -> void:
    for id in CHASSIS:
        var data := _data(id)
        data["subdivide"] = 1
        var model := VxModel.from_dict(data)
        check(model.errors.is_empty(), id + ": " + ", ".join(model.errors))
        check_eq(int(model.quality_report.get("floating_islands", -1)), 0,
            id + ": no floating source geometry")
        check_eq(int(model.quality_report.get("weak_joint_contacts", -1)), 0,
            id + ": each moving joint needs real structural support")


func test_koshi_three_models_keep_separate_art_and_weapon_muzzles() -> void:
    for name in ["koshi_standard", "koshi_standard_2", "koshi_standard_3"]:
        var path := "res://data/voxels/" + name + ".json"
        var model := VxModel.load_file(path)
        check(model.errors.is_empty(), name + " overlay resolves cleanly")
        var d := _data(name)
        var left: Array = d["muzzles"]["LA"]
        var expected := 8 if name == "koshi_standard" else (6 if name == "koshi_standard_2" else 3)
        check_eq(left.size(), expected, name + " source laser/missile aperture count")
        check(not model.part("la").is_empty(), name + " keeps independent gun arm")

func test_solitaire_3_large_laser_is_in_right_torso() -> void:
    var recipe := _data("solitaire")
    var installed: Dictionary = JsonFile.read("res://data/units/solitaire_3.json")
    check("c_improved_heavy_large_laser" in installed["equipment"]["RT"],
        "right-torso heavy large laser is official variant equipment")
    check_eq((recipe["muzzles"]["LT"] as Array).size(), 2,
        "both left torso small lasers have separate visual origins")
    var main: Array = recipe["muzzles"]["RT"]
    check(float(main[2]) < float(recipe["muzzles"]["LT"][0][2]),
        "oversize RT gun extends farther forward than LT small emitters")
    check(_part_peak(_part(recipe, "rt")) > _part_peak(_part(recipe, "lt")),
        "main heavy-laser cooling jacket belongs to the right shoulder")


func test_dominator_head_laser_points_to_the_rear() -> void:
    var recipe := _data("dominator")
    var installed: Dictionary = JsonFile.read("res://data/units/dominator.json")
    check("c_er_small_laser@rear" in installed["equipment"]["HD"],
        "rear direction is based on the official record sheet")
    var origin: Array = recipe["muzzles"]["HD"]
    check(float(origin[2]) > 0.0,
        "head laser must visibly leave behind the cockpit, not forward")

