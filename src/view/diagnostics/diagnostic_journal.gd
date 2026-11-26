class_name DiagnosticJournal
extends RefCounted
## Local, bounded, flushed session breadcrumbs; no network or saved game data.

const ROOT := "user://diagnostics"
const LIMIT := 256 * 1024
const ENGINE_TAIL := 64 * 1024
var folder: String
var session: FileAccess


func _init(path: String = ROOT) -> void:
	folder = path


func start(engine_tail: String = "") -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var old := read("current.log")
	if not old.is_empty():
		_write("previous.log", old)
		var status := end_status(old)
		if status != "clean":
			_write("last-interrupted.txt", "PREVIOUS SESSION: " + status + "\n" + old +
				"\n--- Previous engine log tail (if available) ---\n" + engine_tail)
	session = FileAccess.open(folder.path_join("current.log"), FileAccess.WRITE)
	append("SESSION_START", "diagnostics active")


func append(kind: String, detail: String = "") -> void:
	if session == null:
		return
	var line := "%s +%dms | %s | %s" % [Time.get_datetime_string_from_system(true), Time.get_ticks_msec(),
		kind, detail.replace("\n", " ").replace("\r", " ").left(2048)]
	if session.get_position() >= LIMIT:
		# Keep the most recent half of the journal; preserve one previous
		# complete chunk if interrupted while rotating.
		session.flush()
		session = null
		var old := read("current.log")
		_write("overflow.log", old)
		var tail := old.right(LIMIT / 2)
		var newline := tail.find("\n")
		session = FileAccess.open(folder.path_join("current.log"), FileAccess.WRITE)
		if session == null:
			return
		session.store_string(tail.substr(newline + 1))
	session.store_line(line)
	session.flush()


func close(clean: bool = true) -> void:
	if clean:
		append("SESSION_CLEAN_EXIT")
	session = null


func read(name: String) -> String:
	var path := folder.path_join(name)
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


func _write(name: String, value: String) -> void:
	var f := FileAccess.open(folder.path_join(name), FileAccess.WRITE)
	if f != null:
		f.store_string(value)
		f.flush()


static func end_status(value: String) -> String:
	var lines := value.strip_edges().split("\n", false)
	if lines.is_empty():
		return "no session"
	var last := lines[-1].split(" | ", false, 2)
	var marker: String = last[1] if last.size() >= 2 else ""
	if marker == "SESSION_CLEAN_EXIT":
		return "clean"
	if marker == "SESSION_PAUSED":
		return "ended while backgrounded (may be normal Android process reclamation)"
	return "interrupted without a clean exit (possible crash, force stop or OS kill)"


## Read only a bounded tail, even if the engine log is large.
static func file_tail(path: String, limit: int = ENGINE_TAIL) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var offset := maxi(0, f.get_length() - limit)
	f.seek(offset)
	var result := f.get_buffer(mini(limit, f.get_length())).get_string_from_utf8()
	if offset > 0:
		result = result.substr(result.find("\n") + 1)
	return result
