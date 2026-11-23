extends SceneTree
## Export real occupied-voxel orthographic silhouettes as ASCII mask grids.
## Godot 4.5: godot --headless --import
## godot --headless -s tools/export_reference_review_masks.gd -- /tmp/mech-masks
## Produces one set per distinct BattleMech recipe and support unit visual.

const MASK_SIZE := 64
var destination := "/tmp/mech-masks"
var stance_catalog: Dictionary = {}
var completed := 0
var failures: Array[String] = []


func _init() -> void:
    var args := OS.get_cmdline_user_args()
    if not args.is_empty():
        destination = args[0]
    if args.size() > 1:
        var file: Variant = JsonFile.read(args[1])
        if not file is Dictionary:
            printerr("MODEL_MASK_EXPORT: invalid stance file " + args[1])
            quit(1)
            return
        stance_catalog = file
    _mechs()
    _assets("assets", "archetype")
    _assets("vehicles", "vehicle")
    _assets("battle_armor", "battle_armor")
    print("MODEL_MASK_EXPORT|models=%d|failed=%d|%s" % [
        completed, failures.size(), destination])
    for failure: String in failures:
        printerr("MODEL_MASK_FAILURE|" + failure)
    quit(1 if not failures.is_empty() else 0)


func _mechs() -> void:
    var folder := "res://data/voxels/"
    var files := DirAccess.get_files_at(folder)
    files.sort()
    for file: String in files:
        if not file.ends_with("_shape.json"):
            continue
        _export(folder + file, file.trim_suffix("_shape.json"), true)
    for file: String in files:
        if not file.ends_with(".json"):
            continue
        if file.ends_with("_shape.json") or file.ends_with("_voxel.json"):
            continue
        var id := file.get_basename()
        if FileAccess.file_exists(folder + id + "_shape.json"):
            continue
        _export(folder + file, id, true)


func _assets(folder: String, prefix: String) -> void:
    var dir := "res://data/voxels/" + folder + "/"
    var files := DirAccess.get_files_at(dir)
    files.sort()
    for file: String in files:
        if file.ends_with(".json"):
            _export(dir + file, prefix + "/" + file.get_basename(), false)


func _export(path: String, id: String, mech: bool) -> void:
    var raw: Dictionary = JsonFile.read(path)
    var data: Dictionary = raw
    if mech and raw.has("source"):
        var base: Dictionary = JsonFile.read(String(raw["source"]))
        data = VxVariant.resolve(base, raw)
    data = data.duplicate(true)
    data["subdivide"] = 1
    var model: VxModel = VxModel.from_dict(data) if mech else VoxelAsset.model_from_dict(data)
    if model.cell_count() <= 0 or not model.errors.is_empty():
        failures.append("%s: %s" % [id, str(model.errors)])
        return
    var masks := {}
    for view: String in VxSilhouette.VIEWS:
        var pose := ReferenceStanceRig.profile(stance_catalog, id, view)
        if mech:
            var issues := ReferenceStanceRig.errors(model, pose)
            if not issues.is_empty():
                failures.append("%s/%s: %s" % [id, view, ", ".join(issues)])
                return
            masks[view] = ReferenceStanceRig.project(model, view, pose, MASK_SIZE)
        else:
            masks[view] = VxSilhouette.project(VxSilhouette.model_cells(model), view, MASK_SIZE)
    var folder := destination.path_join(id)
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        failures.append(id + ": cannot create output folder")
        return
    for view: String in VxSilhouette.VIEWS:
        var file := FileAccess.open(folder.path_join(view + ".txt"), FileAccess.WRITE)
        if file == null:
            failures.append(id + "/" + view + ": cannot write mask")
            return
        var occupied: Dictionary = masks[view]
        for y in MASK_SIZE:
            var line := ""
            for x in MASK_SIZE:
                line += "#" if occupied.has(Vector2i(x, y)) else "."
            file.store_line(line)
        file.close()
    completed += 1
