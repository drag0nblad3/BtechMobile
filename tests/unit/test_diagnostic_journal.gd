extends TestCase
## Simulate unclean exits and later normal launches without killing CI.

const DIR := "user://diagnostic_journal_test"


func test_interrupted_report_survives_normal_restarts() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	for name in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR.path_join(name)))
	var first := DiagnosticJournal.new(DIR)
	first.start()
	first.append("BATTLE_READY", "turn 1")
	first.append("SAMPLE", "camera=(1,2,3)")
	first.close(false)
	var second := DiagnosticJournal.new(DIR)
	second.start("engine error example")
	var report := second.read("last-interrupted.txt")
	check(report.contains("BATTLE_READY") and report.contains("camera=(1,2,3)"))
	check(report.contains("engine error example"))
	check(report.contains("possible crash"))
	second.close()
	var third := DiagnosticJournal.new(DIR)
	third.start()
	check_eq(third.read("last-interrupted.txt"), report)
	check_eq(DiagnosticJournal.end_status(third.read("previous.log")), "clean")
	third.close()
	for name in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR.path_join(name)))


func test_background_and_clean_markers_are_distinct() -> void:
	check_eq(DiagnosticJournal.end_status("time | SESSION_CLEAN_EXIT | "), "clean")
	check(DiagnosticJournal.end_status("time | SESSION_PAUSED | ").contains("backgrounded"))
	check(DiagnosticJournal.end_status("time | SAMPLE | fps=30").contains("interrupted"))
