extends SceneTree
## Compact, genuine voxel-meshed review sheet: seven sculpts, each from
## front, side and three-quarter. One chassis at a time avoids GPU overload.
## xvfb-run -a godot --rendering-method gl_compatibility --resolution 1400x800 \
##   -s tools/capture_silhouette_review.gd -- /tmp/voxel-qa

const IDS := ["battleaxe","sagittaire","firestarter","phoenix_hawk","spartan","crockett","katana","quickdraw","cataphract","grizzly","akuma","merlin","excalibur","whitworth","ymir","albatross","exterminator","helios","hatamoto_chi","cyclops","clint","assassin","kintaro","starslayer","hellspawn","chimera","firefly","firebee","shockwave","malice","hermes_ii","howler","venom","dragon","ostroc","grasshopper","black_knight","shadow_hawk","griffin","javelin","commando"]
const VIEWS := ["front", "side"]
const TILE_W := 230
const TILE_H := 320
const COLUMNS := 4

var output_dir := "/tmp/silhouette-review"
var stage: Node3D
var camera: Camera3D
var name_label: Label
var active: VxMech
var center_local := Vector3.ZERO
var height_m := 1.0
var breadth_m := 1.0
var capture_index := 0
var frame := 0
var shots: Array[Image] = []


func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if not args.is_empty():
        output_dir = args[0]
    DirAccess.make_dir_recursive_absolute(output_dir)
    stage = Node3D.new()
    root.add_child(stage)
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("252d35")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("e4e8ed")
    env.ambient_light_energy = 0.85
    var world := WorldEnvironment.new()
    world.environment = env
    stage.add_child(world)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-45, -35, 0)
    key.light_energy = 1.5
    stage.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-25, 140, 0)
    fill.light_energy = 0.55
    stage.add_child(fill)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.current = true
    stage.add_child(camera)
    var overlay := CanvasLayer.new()
    root.add_child(overlay)
    name_label = Label.new()
    name_label.position = Vector2(430, 736)
    name_label.add_theme_font_size_override("font_size", 26)
    name_label.add_theme_color_override("font_color", Color("f6f8fa"))
    overlay.add_child(name_label)
    _load_chassis(0)
    _set_view()


func _load_chassis(index: int) -> void:
    if active != null:
        active.free()
    var id: String = IDS[index]
    var high := "res://data/voxels/%s_voxel.json" % id
    var path := high if VxRecipeStore.exists(high) else "res://data/voxels/%s.json" % id
    active = VxMech.from_file(path)
    if not active.model.errors.is_empty() or active.voxel_count() == 0:
        printerr("SILHOUETTE_RENDER_ERROR|invalid model|%s|%s" %
            [id, str(active.model.errors)])
        quit(1)
        return
    stage.add_child(active)
    active.position = Vector3.ZERO
    var lower := Vector3i(100000, 100000, 100000)
    var upper := Vector3i(-100000, -100000, -100000)
    for spec: Dictionary in active.model.parts:
        for cell: Vector3i in spec["cells"]:
            lower.x = mini(lower.x, cell.x)
            lower.y = mini(lower.y, cell.y)
            lower.z = mini(lower.z, cell.z)
            upper.x = maxi(upper.x, cell.x)
            upper.y = maxi(upper.y, cell.y)
            upper.z = maxi(upper.z, cell.z)
    var voxel := active.model.voxel_size
    center_local = (Vector3(lower) + Vector3(upper) + Vector3.ONE) * 0.5 * voxel
    height_m = maxf(0.1, float(upper.y - lower.y + 1) * voxel)
    breadth_m = maxf(float(upper.x - lower.x + 1),
        float(upper.z - lower.z + 1)) * voxel
    print("SILHOUETTE_REVIEW_MODEL|%s|%d voxels|%.2fm tall" %
        [id, active.voxel_count(), height_m])


func _set_view() -> void:
    var id: String = IDS[capture_index / VIEWS.size()]
    var view: String = VIEWS[capture_index % VIEWS.size()]
    active.rotation.y = PI * 0.5 if view == "side" else 0.0
    var center: Vector3 = active.to_global(center_local)
    camera.size = maxf(height_m * 1.30, breadth_m * 1.90)
    var distance := maxf(5.0, height_m * 4.5)
    var offset := Vector3(0, height_m * 0.04, -distance)
    if view == "three_quarter":
        offset.x = distance * 0.48
    camera.look_at_from_position(center + offset, center)
    name_label.text = "%s  /  %s" % [id.to_upper().replace("_", " "),
        view.to_upper().replace("_", " ")]


func _process(_delta: float) -> bool:
    frame += 1
    if frame < 9:
        return false
    if root.get_camera_3d() != camera:
        printerr("SILHOUETTE_RENDER_ERROR|camera not current")
        quit(1)
        return true
    var shot := root.get_texture().get_image()
    if shot == null or shot.get_width() < 500:
        printerr("SILHOUETTE_RENDER_ERROR|viewport empty")
        quit(1)
        return true
    var crop_width := mini(shot.get_width(),
        maxi(1, roundi(float(shot.get_height()) * float(TILE_W) / float(TILE_H))))
    var tile := shot.get_region(Rect2i((shot.get_width() - crop_width) / 2,
        0, crop_width, shot.get_height()))
    tile.convert(Image.FORMAT_RGBA8)
    tile.resize(TILE_W, TILE_H, Image.INTERPOLATE_LANCZOS)
    shots.append(tile)
    capture_index += 1
    if capture_index == IDS.size() * VIEWS.size():
        _finish()
        return true
    if capture_index % VIEWS.size() == 0:
        _load_chassis(capture_index / VIEWS.size())
    _set_view()
    frame = 0
    return false


func _finish() -> void:
    var rows := ceili(float(IDS.size()) / float(COLUMNS))
    var sheet := Image.create(COLUMNS * VIEWS.size() * TILE_W,
        rows * TILE_H, false, Image.FORMAT_RGBA8)
    sheet.fill(Color("252d35"))
    for i in shots.size():
        var mech_index := i / VIEWS.size()
        var view_index := i % VIEWS.size()
        var x := (mech_index % COLUMNS * VIEWS.size() + view_index) * TILE_W
        var y := (mech_index / COLUMNS) * TILE_H
        sheet.blit_rect(shots[i], Rect2i(0, 0, TILE_W, TILE_H), Vector2i(x, y))
    var path := output_dir.path_join("proportion_queue_front_side.png")
    if sheet.save_png(path) != OK:
        printerr("SILHOUETTE_RENDER_ERROR|failed writing " + path)
        quit(1)
        return
    print("SILHOUETTE_REVIEW_RENDER|" + path)
    quit(0)
