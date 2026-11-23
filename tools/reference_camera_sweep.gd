extends SceneTree
## Explore camera-only offsets around a photo-estimated reference viewpoint.
## It never changes joint poses, geometry, or approved scorecard ratings.

const SIZE := 64
var output := "/tmp/reference-qa/camera-sweep"
var results: Array[Dictionary] = []
var faults: Array[String] = []


func _init() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() < 3:
        printerr("Usage: -- output_dir stance_json photo_candidates_json")
        quit(1)
        return
    output = args[0]
    var profile: Dictionary = JsonFile.read(args[1])
    var registry: Dictionary = JsonFile.read(args[2])
    for candidate: Dictionary in registry.get("candidates", []):
        _score_camera_grid(profile, candidate)
    DirAccess.make_dir_recursive_absolute(output)
    var file := FileAccess.open(output.path_join("index.json"), FileAccess.WRITE)
    if file == null:
        quit(1)
        return
    file.store_string(JSON.stringify({"candidates": results, "faults": faults}, "  "))
    file.close()
    print("REFERENCE_CAMERA_SWEEP|candidates=%d|faults=%d" % [
        results.size(), faults.size()])
    for issue: String in faults:
        printerr("REFERENCE_CAMERA_SWEEP_ERROR|" + issue)
    quit(1 if not faults.is_empty() else 0)


func _score_camera_grid(profile: Dictionary, candidate: Dictionary) -> void:
    var model_id: String = candidate["model"]
    var view: String = candidate["view"]
    var asset := model_id.contains("/")
    var path := "res://data/voxels/%s_shape.json" % model_id
    if asset:
        var pair := model_id.split("/", false)
        var subfolder := {"archetype": "assets", "vehicle": "vehicles",
            "battle_armor": "battle_armor"}.get(pair[0], "")
        path = "res://data/voxels/%s/%s.json" % [subfolder, pair[1]]
    elif not FileAccess.file_exists(path):
        path = "res://data/voxels/%s.json" % model_id
    var raw: Dictionary = JsonFile.read(path)
    if not asset and raw.has("source"):
        raw = VxVariant.resolve(JsonFile.read(String(raw["source"])), raw)
    raw = raw.duplicate(true)
    raw["subdivide"] = 1
    var model: VxModel = VoxelAsset.model_from_dict(raw) if asset else VxModel.from_dict(raw)
    var pose := ReferenceStanceRig.profile(profile, model_id, view)
    var errors := ReferenceStanceRig.errors(model, pose)
    if not model.errors.is_empty() or not errors.is_empty():
        faults.append("%s: %s %s" % [model_id, model.errors, errors])
        return
    var initial: Dictionary = pose["camera"].duplicate(true)
    initial.merge(candidate.get("camera_guess", {}), true)
    var offsets: Dictionary = candidate.get("camera_search", {})
    var yaws: Array = offsets.get("yaw_offsets", [-10, 0, 10])
    var pitches: Array = offsets.get("pitch_offsets", [-8, 0, 8])
    var folder := output.path_join(model_id).path_join(view)
    DirAccess.make_dir_recursive_absolute(folder)
    var projections: Array = candidate.get("camera_projections",
        [initial.get("projection", "orthographic")])
    var index := 0
    for projection in projections:
        for yaw in yaws:
            for pitch in pitches:
                var camera := initial.duplicate(true)
                camera["projection"] = projection
                camera["yaw_deg"] = float(initial["yaw_deg"]) + float(yaw)
                camera["pitch_deg"] = float(initial["pitch_deg"]) + float(pitch)
                if not ReferenceCamera.settings_errors(camera).is_empty():
                    continue
                var calibrated := pose.duplicate(true)
                calibrated["camera"] = camera
                var pixels: Dictionary = ReferenceStanceRig.project(
                    model, view, calibrated, SIZE)
                var mask_path := folder.path_join("%02d.txt" % index)
                var file := FileAccess.open(mask_path, FileAccess.WRITE)
                if file == null:
                    faults.append("Cannot write " + mask_path)
                    return
                for y in SIZE:
                    var line := ""
                    for x in SIZE:
                        line += "#" if pixels.has(Vector2i(x, y)) else "."
                    file.store_line(line)
                file.close()
                results.append({"model": model_id, "view": view,
                    "path": mask_path, "camera": camera,
                    "yaw_offset": yaw, "pitch_offset": pitch,
                    "projection": projection})
                index += 1
