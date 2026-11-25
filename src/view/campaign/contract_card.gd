class_name ContractCard
extends RefCounted
## One compact, selectable contract summary with optional briefing details.

static func add(list: VBoxContainer, c: Campaign, k: Contract, rules: ChaosRules, index: int,
		on_toggle: Callable, on_select: Callable, selected: bool, expanded: bool) -> void:
	var info := StandardMissions.info(k.mission_id)
	var why := Warchest.cant_take(c, k, rules)
	var summary := "%s  ·  %d%% enemy BV  ·  %d WP cost  ·  %d WP max" % [
		info.get("name", k.mission_id), k.enemy_percent, k.cost(rules), k.max_reward(rules)]
	if not k.story.is_empty():
		summary = String(k.story["title"]) + " · " + summary
	if why != "":
		summary += "  ·  Unavailable"
	elif c.wp < k.cost(rules):
		summary += "  ·  Debt"
	var b := UiKit.button(list, summary + ("  ▴" if expanded else "  ▾"), on_select.bind(index),
		Vector2(0, 52), "selected" if selected else "subtle")
	b.name = "Contract_%d" % index
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 20)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.tooltip_text = why if why != "" else summary
	if not expanded:
		return
	var briefing := UiKit.panel(list)
	_details(briefing, k, rules, index, on_toggle)


static func _details(list: VBoxContainer, k: Contract, rules: ChaosRules, index: int, on_toggle: Callable) -> void:
	var info := StandardMissions.info(k.mission_id)
	if not k.story.is_empty():
		UiKit.label(list, String(k.story["briefing"]), UiKit.SMALL)
	UiSkin.label(UiKit.label(list, String(info.get("summary", "")), UiKit.SMALL), "muted")
	for id in k.objectives:
		var o := rules.objective(id)
		UiKit.label(list, "Objective: %s (%d WP). %s" % [o.get("title", id), int(o.get("wp", 0)), o.get("text", "")], UiKit.SMALL)
	for id in k.offered:
		var o := rules.option(id)
		var on := k.chosen.has(id)
		var b := UiKit.button(list, "%s Option: %s (+%d WP if any objective is met). %s" % [
				"☑" if on else "☐", o.get("title", id), int(o.get("wp", 0)), o.get("text", "")],
				on_toggle.bind(index, id), Vector2(0, 52), "selected" if on else "subtle")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", UiKit.SMALL)
