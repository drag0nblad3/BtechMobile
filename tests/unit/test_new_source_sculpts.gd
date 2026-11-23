extends TestCase
## General face-connected mass and two-layer joint checks for newly hand-sculpted models.

const MODELS := ["yeoman", "jackrabbit", "hermit_crab", "garm", "hornet", "hussar"]
const AXES := [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP,
        Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]


func test_new_shape_studies_are_complete_and_connected() -> void:
    for name: String in MODELS:
        var path := "res://data/voxels/%s_shape.json" % name
        var m := VxModel.load_file(path)
        check(m.errors.is_empty(), name + ": parse " + str(m.errors))
        check(designs().get_def(m.unit_id) != null, name + ": official unit missing")
        for loc in Location.COUNT:
            check(not m.parts_at(loc).is_empty(), name + " lacks " + Location.code(loc))
        _assert_rooted_hierarchy(m, name)
        check_eq(_groups(_whole_model(m)), 1, name + " has a disconnected whole-mech voxel mass")
        for p: Dictionary in m.parts:
            var cells: Dictionary = p["cells"]
            check(not cells.is_empty(), name + "/" + p["name"] + " has no mass")
            check_eq(_groups(cells), 1, name + "/" + p["name"] + " has floating islands")
            var parent_name: String = p.get("parent", "")
            if parent_name.is_empty():
                continue
            var parent: Dictionary = m.part(parent_name)
            check(not parent.is_empty(), name + "/" + p["name"] + " missing parent")
            if not parent.is_empty():
                check(_solid_joint(cells, parent["cells"]),
                        name + "/" + p["name"] + " has no 2x2 backed joint")



func test_new_high_detail_models_preserve_connected_masses() -> void:
    for name: String in MODELS:
        var path := "res://data/voxels/%s.json" % name
        var m := VxModel.load_file(path)
        check(m.errors.is_empty(), name + " high detail: " + str(m.errors))
        check_eq(m.detail, 2, name + " should be a 2x detailed source sculpt")
        check(m.cell_count() > 30000, name + " detail count " + str(m.cell_count()))
        for p: Dictionary in m.parts:
            var cells: Dictionary = p["cells"]
            check_eq(_groups(cells), 1, name + " high/" + p["name"] + " islands")
            var parent_name: String = p.get("parent", "")
            if not parent_name.is_empty():
                var parent: Dictionary = m.part(parent_name)
                check(not parent.is_empty(), name + " high/" + p["name"] + " missing parent")
                if not parent.is_empty():
                    check(_solid_joint(cells, parent["cells"]),
                            name + " high/" + p["name"] + " weak joint")


func test_muzzles_are_at_real_openings() -> void:
    for name: String in MODELS:
        var m := VxModel.load_file("res://data/voxels/%s_shape.json" % name)
        for loc: int in m.muzzles:
            for point: Vector3 in m.muzzles[loc]:
                var at := Vector3i(floori(point.x), floori(point.y), floori(point.z))
                for p: Dictionary in m.parts_at(loc):
                    check(not (p["cells"] as Dictionary).has(at),
                            name + "/" + Location.code(loc) + " plugged muzzle " + str(at))
        if name == "yeoman":
            check_eq(m.muzzles[Location.LT].size(), 25)
            check_eq(m.muzzles[Location.RT].size(), 25)
        elif name == "jackrabbit":
            check_eq(m.muzzles[Location.LA].size(), 2)
            check_eq(m.muzzles[Location.RA].size(), 1)
        elif name == "garm":
            check_eq(m.muzzles[Location.LT].size(), 10)
            check_eq(m.muzzles[Location.RT].size(), 1)
        elif name == "hermit_crab":
            check_eq(m.muzzles[Location.LA].size(), 1)
            check_eq(m.muzzles[Location.RA].size(), 1)
        elif name == "hornet":
            check_eq(m.muzzles[Location.RT].size(), 5)
        elif name == "hussar":
            check_eq(m.muzzles[Location.CT].size(), 1)



## No limb may silently become another root. Every modeled segment must
## descend from the center torso through only valid, acyclic parent links.
func _assert_rooted_hierarchy(m: VxModel, name: String) -> void:
    var roots: Array[String] = []
    for p: Dictionary in m.parts:
        if String(p["parent"]).is_empty():
            roots.append(str(p["name"]))
        var seen := {}
        var current: Dictionary = p
        var steps := 0
        while not current.is_empty() and not String(current.get("parent", "")).is_empty():
            var pname: String = current["parent"]
            check(not seen.has(pname), name + " cycle in " + str(p["name"]))
            if seen.has(pname):
                break
            seen[pname] = true
            current = m.part(pname)
            steps += 1
            if steps > m.parts.size():
                break
        check(not current.is_empty(), name + " has unresolvable parent in " + str(p["name"]))
        if not current.is_empty():
            check_eq(str(current["name"]), "ct", name + " disconnected hierarchy for " + str(p["name"]))
    check_eq(roots.size(), 1, name + " must have exactly one rooted rigid hierarchy")
    check_eq(roots[0] if not roots.is_empty() else "", "ct", name + " root must be central torso")
    for side: String in ["l", "r"]:
        var forearm: String = side + "a_forearm"
        var calf: String = side + "l_calf"
        check(not m.part(forearm).is_empty(), name + " missing independently defined lower arm " + forearm)
        check(not m.part(calf).is_empty(), name + " missing independently defined lower shin " + calf)


func _whole_model(m: VxModel) -> Dictionary:
    var combined := {}
    for p: Dictionary in m.parts:
        for c: Vector3i in p["cells"]:
            combined[c] = true
    return combined

func test_primary_shoulder_mounts_are_substantial_and_backed() -> void:
    # A minimum 3x3 square with at least one full backing layer on BOTH
    # sides: a single 2x2 seam is not enough for a heavy shoulder shield.
    for name: String in MODELS:
        var m := VxModel.load_file("res://data/voxels/%s_shape.json" % name)
        for pname in ["lt", "rt", "la", "ra"]:
            var child: Dictionary = m.part(pname)
            var parent: Dictionary = m.part(child.get("parent", ""))
            check(not child.is_empty(), name + "/" + pname + " missing shoulder")
            if not child.is_empty() and not parent.is_empty():
                check(_large_joint(child["cells"], parent["cells"]),
                        name + "/" + pname + " lacks a 3x3 two-layer backed shoulder bearing")


func _large_joint(child: Dictionary, parent: Dictionary) -> bool:
    for cell: Vector3i in child:
        for normal: Vector3i in AXES:
            if not parent.has(cell + normal):
                continue
            var sides := _cross(normal)
            for u in [-2, -1, 0]:
                for v in [-2, -1, 0]:
                    var strong := true
                    for du in 3:
                        for dv in 3:
                            var c: Vector3i = cell + sides[0] * (u + du) + sides[1] * (v + dv)
                            if not child.has(c) or not child.has(c - normal) \
                                    or not parent.has(c + normal) or not parent.has(c + normal * 2):
                                strong = false
                                break
                        if not strong:
                            break
                    if strong:
                        return true
    return false


func _groups(cells: Dictionary) -> int:
    var pending := {}
    for c: Vector3i in cells:
        pending[c] = true
    var count := 0
    while not pending.is_empty():
        count += 1
        var first: Vector3i = pending.keys()[0]
        var queue: Array[Vector3i] = [first]
        pending.erase(first)
        var n := 0
        while n < queue.size():
            var cell: Vector3i = queue[n]
            n += 1
            for move: Vector3i in AXES:
                var next: Vector3i = cell + move
                if pending.erase(next):
                    queue.append(next)
    if count > 1:
        var remaining := {}
        for c: Vector3i in cells:
            remaining[c] = true
        while not remaining.is_empty():
            var sample: Vector3i = remaining.keys()[0]
            var frontier: Array[Vector3i] = [sample]
            remaining.erase(sample)
            var minimum: Vector3i = sample
            var maximum: Vector3i = sample
            var idx := 0
            while idx < frontier.size():
                var cell2: Vector3i = frontier[idx]
                idx += 1
                minimum = Vector3i(mini(minimum.x, cell2.x), mini(minimum.y, cell2.y), mini(minimum.z, cell2.z))
                maximum = Vector3i(maxi(maximum.x, cell2.x), maxi(maximum.y, cell2.y), maxi(maximum.z, cell2.z))
                for move2: Vector3i in AXES:
                    var n2: Vector3i = cell2 + move2
                    if remaining.erase(n2):
                        frontier.append(n2)
            print("SCULPT_COMPONENT|count=%d|lo=%s|hi=%s" % [frontier.size(), minimum, maximum])
    return count


func _solid_joint(child: Dictionary, parent: Dictionary) -> bool:
    for cell: Vector3i in child:
        for normal: Vector3i in AXES:
            if not parent.has(cell + normal):
                continue
            var sides := _cross(normal)
            for first_sign in [-1, 1]:
                for second_sign in [-1, 1]:
                    var a: Vector3i = sides[0] * first_sign
                    var b: Vector3i = sides[1] * second_sign
                    var sound := true
                    for shift in [Vector3i.ZERO, a, b, a + b]:
                        var c: Vector3i = cell + shift
                        if not child.has(c) or not child.has(c - normal) \
                                or not parent.has(c + normal) \
                                or not parent.has(c + normal * 2):
                            sound = false
                            break
                    if sound:
                        return true
    return false


func _cross(normal: Vector3i) -> Array[Vector3i]:
    if normal.x != 0:
        return [Vector3i.UP, Vector3i.FORWARD]
    if normal.y != 0:
        return [Vector3i.RIGHT, Vector3i.FORWARD]
    return [Vector3i.RIGHT, Vector3i.UP]
