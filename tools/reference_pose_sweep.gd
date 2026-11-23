extends SceneTree
## Candidate pose projections at the best photographic camera from stage one.
## No game rig, model JSON, or approved source score is changed.

const MASK_SIZE := 64
var output := "/tmp/reference-qa/pose-candidates"
var stance_catalog: Dictionary = {}
var records: Array[Dictionary] = []
var failures: Array[String] = []


func _init() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() < 3:
        printerr("Usage: -- output_directory pose_catalog stage1_photo_fit.json")
        quit(1)
        return
    output = args[0]
    stance_catalog = JsonFile.read(args[1])
    var report: Dictionary = JsonFile.read(args[2])
    for trial: Dictionary in report.get("candidates", []):
        _export_candidates(trial)
    DirAccess.make_dir_recursive_absolute(output)
    var file := FileAccess.open(output.path_join("index.json"), FileAccess.WRITE)
    if file == null:
        quit(1)
        return
    file.store_string(JSON.stringify({"candidates": records,
        "failures": failures}, "  "))
    file.close()
    print("REFERENCE_POSE_SWEEP|candidates=%d|failures=%d" % [
        records.size(), failures.size()])
    for issue: String in failures:
        printerr("REFERENCE_POSE_ERROR|" + issue)
    quit(1 if not failures.is_empty() else 0)


func _model_for(id: String) -> VxModel:
    var asset := id.contains("/")
    var path := "res://data/voxels/%s_shape.json" % id
    if asset:
        var pieces := id.split("/", false)
        var subfolder := {"archetype": "assets", "vehicle": "vehicles",
            "battle_armor": "battle_armor"}.get(pieces[0], "")
        path = "res://data/voxels/%s/%s.json" % [subfolder, pieces[1]]
    elif not FileAccess.file_exists(path):
        path = "res://data/voxels/%s.json" % id
    var raw: Dictionary = JsonFile.read(path)
    if not asset and raw.has("source"):
        raw = VxVariant.resolve(JsonFile.read(String(raw["source"])), raw)
    raw = raw.duplicate(true)
    raw["subdivide"] = 1
    return VoxelAsset.model_from_dict(raw) if asset else VxModel.from_dict(raw)


func _export_candidates(trial: Dictionary) -> void:
    var camera: Dictionary = trial.get("best_camera_provisional", {})
    if camera.is_empty():
        return
    var id: String = trial["model"]
    var view: String = trial["view"]
    var model := _model_for(id)
    if not model.errors.is_empty():
        failures.append("%s: %s" % [id, model.errors])
        return
    var pose := ReferenceStanceRig.profile(stance_catalog, id, view)
    pose["camera"] = camera
    var options := ReferencePoseCandidates.candidates(model, pose)
    var folder := output.path_join(id).path_join(view)
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        failures.append("Cannot create " + folder)
        return
    for index in options.size():
        var candidate: Dictionary = options[index]
        var pixels := ReferenceStanceRig.project(model, view, candidate, MASK_SIZE)
        var filename := folder.path_join("%02d.txt" % index)
        var file := FileAccess.open(filename, FileAccess.WRITE)
        if file == null:
            failures.append("Cannot write " + filename)
            return
        for y in MASK_SIZE:
            var line := ""
            for x in MASK_SIZE:
                line += "#" if pixels.has(Vector2i(x, y)) else "."
            file.store_line(line)
        file.close()
        records.append({"model": id, "view": view,
            "candidate_id": candidate["candidate_id"],
            "path": filename, "camera": camera,
            "joints": candidate.get("joints", {}),
            "body_rotation_deg": candidate.get("body_rotation_deg", [0, 0, 0]),
            "status": "UNVERIFIED_ARTICULATED_POSE_CANDIDATE"})
