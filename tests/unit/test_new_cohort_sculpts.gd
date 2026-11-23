extends TestCase
## New original chassis must have roots, substantial actual mass, no floating
## pieces, and open gun ports. No silhouette tests are coordinate-pinned.

const IDS := ["apollo","bandersnatch","battle_hawk","bombard","cestus","daedalus","daikyu","daimyo","dart","duan_gung","eagle","enfield","enforcer_iii","falcon","falcon_hawk","imp","rakshasa","thorn","wraith","ha_otoko","hammerhands","lightray","wolf_trap","watchman","fireball","gallowglas","night_hawk","kabuto","warlord","flashfire","grim_reaper","hatamoto_hi","hatamoto_kaze","hatamoto_ku","hatamoto_mizo","hercules","jackal","juggernaut","koto","lineholder","lynx","nexus","onslaught","raijin","salamander","sentry","shootist","snake","striker","talon","tsunami","werewolf","wyvern","alfar","behemoth","blade","brigand","cobra","cossack","cronus","dragoon","eisenfaust","eris","exhumer","gravedigger","hermes_iii","hound","initiate","jagermech_iii","koschei","marshal","orochi","phoenix","rampage","razorback","rook","swordsman","talos","titan","verfolger","von_rohrs_hebi","yu_huang"]
const DIRS := [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP,
        Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]


func test_cohort_82_are_real_rooted_location_complete_models() -> void:
    for name: String in IDS:
        var m := VxModel.load_file("res://data/voxels/%s_shape.json" % name)
        check(m.errors.is_empty(), name + " parser " + str(m.errors))
        check(designs().get_def(m.unit_id) != null, name + " official unit not found " + m.unit_id)
        check(m.parts.size() >= 15, name + " missing primary segmentation")
        var roots := 0
        for loc in Location.COUNT:
            check(not m.parts_at(loc).is_empty(), name + " missing " + Location.code(loc))
        for p: Dictionary in m.parts:
            if String(p["parent"]).is_empty():
                roots += 1
                check_eq(str(p["name"]), "ct", name + " bad root")
            else:
                check(not m.part(p["parent"]).is_empty(), name + "/" + p["name"] + " orphan parent")
        check_eq(roots, 1, name + " should have one connected rig")


func test_cohort_82_all_parts_are_real_solid_connected_masses() -> void:
    for name: String in IDS:
        var m := VxModel.load_file("res://data/voxels/%s_shape.json" % name)
        var all_cells := {}
        for p: Dictionary in m.parts:
            var cells: Dictionary = p["cells"]
            check(not cells.is_empty(), name + "/" + p["name"] + " empty")
            var groups := _groups(cells)
            if groups > 1:
                print("COHORT_COMPONENTS|", name, "|", p["name"], "|", _component_report(cells))
            check_eq(groups, 1, name + "/" + p["name"] + " floating mass")
            for c: Vector3i in cells:
                all_cells[c] = true
            var parent_name: String = p.get("parent", "")
            if not parent_name.is_empty():
                var parent: Dictionary = m.part(parent_name)
                if not parent.is_empty():
                    check(_supported(cells, parent["cells"]),
                        name + "/" + p["name"] + " no backed 2x2 mechanical joint")
        check_eq(_groups(all_cells), 1, name + " disjoint whole mech")


func test_cohort_82_open_muzzles() -> void:
    for name: String in IDS:
        var m := VxModel.load_file("res://data/voxels/%s_shape.json" % name)
        check(not m.muzzles.is_empty(), name + " missing weapon ports")
        for loc: int in m.muzzles:
            for point: Vector3 in m.muzzles[loc]:
                var c := Vector3i(floori(point.x), floori(point.y), floori(point.z))
                for p: Dictionary in m.parts_at(loc):
                    check(not (p["cells"] as Dictionary).has(c),
                        name + " plugged " + Location.code(loc) + " muzzle at " + str(c))



func _component_report(cells: Dictionary) -> String:
    var left := {}
    for c: Vector3i in cells:
        left[c] = true
    var report: Array[String] = []
    while not left.is_empty():
        var start: Vector3i = left.keys()[0]
        var queue: Array[Vector3i] = [start]
        left.erase(start)
        var lo := start
        var hi := start
        var i := 0
        while i < queue.size():
            var p: Vector3i = queue[i]
            i += 1
            lo = Vector3i(mini(lo.x,p.x),mini(lo.y,p.y),mini(lo.z,p.z))
            hi = Vector3i(maxi(hi.x,p.x),maxi(hi.y,p.y),maxi(hi.z,p.z))
            for d: Vector3i in DIRS:
                var next: Vector3i = p + d
                if left.erase(next):
                    queue.append(next)
        report.append("%d voxels: %s to %s" % [queue.size(),lo,hi])
    return "; ".join(report)


func _groups(cells: Dictionary) -> int:
    var left := {}
    for c: Vector3i in cells:
        left[c] = true
    var groups := 0
    while not left.is_empty():
        groups += 1
        var seed: Vector3i = left.keys()[0]
        var queue: Array[Vector3i] = [seed]
        left.erase(seed)
        var i := 0
        while i < queue.size():
            var c: Vector3i = queue[i]
            i += 1
            for d: Vector3i in DIRS:
                var next: Vector3i = c + d
                if left.erase(next):
                    queue.append(next)
    return groups


func _supported(child: Dictionary, parent: Dictionary) -> bool:
    for c: Vector3i in child:
        for norm: Vector3i in DIRS:
            if not parent.has(c + norm):
                continue
            var sides := [Vector3i.UP, Vector3i.FORWARD] if norm.x != 0 else (
                    [Vector3i.RIGHT, Vector3i.FORWARD] if norm.y != 0 else (
                    [Vector3i.RIGHT, Vector3i.UP]))
            for su in [-1, 1]:
                for sv in [-1, 1]:
                    var a: Vector3i = sides[0] * su
                    var b: Vector3i = sides[1] * sv
                    var strong := true
                    for step in [Vector3i.ZERO, a, b, a + b]:
                        var p: Vector3i = c + step
                        if not child.has(p) or not child.has(p - norm) \
                                or not parent.has(p + norm) or not parent.has(p + norm * 2):
                            strong = false
                            break
                    if strong:
                        return true
    return false
