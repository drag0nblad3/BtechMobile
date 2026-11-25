class_name MapHistoryPanel
extends RefCounted
## Paged report archive, newest first. Only one page of UI nodes at a time.


static func build(parent: VBoxContainer, mc: MapCampaign, page: int, select: Callable) -> void:
	UiKit.label(parent, "OPERATIONAL HISTORY", 25)
	var total := maxi(1, ceili(mc.reports.size() / 6.0))
	var nav := HBoxContainer.new()
	parent.add_child(nav)
	UiKit.button(nav, "Newer", select.bind(maxi(0, page - 1)), Vector2(120, 48)).disabled = page == 0
	var label := UiKit.label(nav, "Page %d / %d" % [page + 1, total], 18)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.button(nav, "Older", select.bind(mini(total - 1, page + 1)), Vector2(120, 48)).disabled = page + 1 >= total
	for i in range(mc.reports.size() - 1 - page * 6, maxi(-1, mc.reports.size() - 7 - page * 6), -1):
		var report: Dictionary = mc.reports[i]
		UiSkin.rule(parent)
		UiKit.label(parent, "Region %d · Day %d · %s" % [int(report["operation"]),
			int(report["day"]), report["zone"]], 21)
		UiKit.label(parent, "\n".join(PackedStringArray(report["lines"])), 17)
	if mc.reports.is_empty():
		UiKit.label(parent, "No archived encounters yet.", 18)
	UiKit.label(parent, "Recent strategic events", 21)
	UiKit.label(parent, "\n".join(mc.log.slice(maxi(0, mc.log.size() - 20))), 17)
