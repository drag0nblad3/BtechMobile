class_name CrashMonitor
extends Node
## App-lifetime diagnostics owner. All journal operations run on the main thread.
## Engine errors use Godot's own file logger; native OS kills may leave no stack.

const PERIOD := 2.0
static var journal: DiagnosticJournal
static var battle_active := false
var _elapsed := 0.0
var _background := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	journal = DiagnosticJournal.new()
	journal.start(_previous_engine_tail())
	note("DEVICE", "%s | %s | Godot %s | %s / %s | RAM=%d MiB" % [
		OS.get_name(), OS.get_version(), Engine.get_version_info().get("string", ""),
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version(),
		int(OS.get_memory_info().get("physical", 0)) / 1048576])
	note("RENDERER", "%s | %s | model=%s | screen=%s" % [
		RenderingServer.get_current_rendering_method(), RenderingServer.get_current_rendering_driver_name(),
		OS.get_model_name(), str(DisplayServer.screen_get_size())])


static func note(kind: String, detail: String = "") -> void:
	if journal != null:
		journal.append(kind, detail)


func _process(delta: float) -> void:
	if _background or not battle_active:
		return
	_elapsed += delta
	if _elapsed < PERIOD:
		return
	_elapsed = 0.0
	var camera := get_viewport().get_camera_3d()
	var pose := "no camera"
	if is_instance_valid(camera):
		pose = "camera=%s rotation=%s" % [str(camera.global_position), str(camera.global_rotation_degrees)]
	note("SAMPLE", "fps=%d static=%.1fMiB video=%.1fMiB objects=%d draw_calls=%d primitives=%d | %s" % [
		Engine.get_frames_per_second(), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), pose])


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_background = true
		note("SESSION_PAUSED")
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_background = false
		note("SESSION_RESUMED")


func _exit_tree() -> void:
	if journal != null:
		journal.close()
		journal = null


static func _previous_engine_tail() -> String:
	var path := String(ProjectSettings.get_setting("debug/file_logging/log_path", "user://logs/godot.log"))
	var dir := path.get_base_dir()
	var prefix := path.get_file().get_basename()
	var newest := ""
	var stamp := -1
	for file in DirAccess.get_files_at(dir):
		if file == path.get_file() or not file.begins_with(prefix) or not file.ends_with(".log"):
			continue
		var candidate := dir.path_join(file)
		var modified := FileAccess.get_modified_time(candidate)
		if modified > stamp or (modified == stamp and candidate > newest):
			newest = candidate
			stamp = modified
	return DiagnosticJournal.file_tail(newest) if not newest.is_empty() else ""


static func report(mode: int) -> String:
	if journal == null:
		return "Diagnostics are not initialized."
	match mode:
		0: return journal.read("last-interrupted.txt")
		1: return journal.read("previous.log")
		_: return journal.read("current.log") + "\n--- Current engine log tail ---\n" + DiagnosticJournal.file_tail(
			String(ProjectSettings.get_setting("debug/file_logging/log_path", "user://logs/godot.log")))
