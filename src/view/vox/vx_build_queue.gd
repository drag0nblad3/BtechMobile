class_name VxBuildQueue
extends Node
## One low-priority worker, one unpublished model at a time. All cache
## queries, publication, scene construction and resource upload stay on main.


var jobs_started := 0
var jobs_completed := 0
var _paths: Array[String] = []
var _thread: Thread
var _active := ""


func begin(paths: Array[String]) -> void:
	_paths = paths.duplicate()
	_start_next()


func _start_next() -> void:
	while not _paths.is_empty():
		var path: String = _paths.pop_front()
		if VxRenderCache.ready(path):
			continue
		var worker := Thread.new()
		if worker.start(VxPreparedGeometry.prepare.bind(path), Thread.PRIORITY_LOW) == OK:
			_thread = worker
			_active = path
			jobs_started += 1
			return
		push_warning("Voxel worker unavailable; using synchronous fallback for " + path)
	_active = ""


func take(path: String) -> Dictionary:
	if path.is_empty() or path != _active or _thread == null:
		return {}
	while _thread.is_alive():
		await get_tree().process_frame
	var result: Variant = _thread.wait_to_finish()
	_thread = null
	_active = ""
	jobs_completed += 1
	_start_next()
	return result if result is Dictionary else {}


func _exit_tree() -> void:
	# Worker has no reference to this Node; join before dropping the Thread.
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null
