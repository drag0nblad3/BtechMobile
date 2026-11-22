extends TestCase
## General face-connected mass and two-layer joint checks for newly hand-sculpted models.

const MODELS := ["yeoman", "jackrabbit", "hermit_crab", "garm"]
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
