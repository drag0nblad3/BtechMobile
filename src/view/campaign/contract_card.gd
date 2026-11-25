class_name ContractCard
extends RefCounted
## Draws one contract on the campaign screen: mission, enemy size,
## objectives, toggleable options and cost, with a Take button.


static func add(list: VBoxContainer, c: Campaign, k: Contract, rules: ChaosRules, index: int,
		on_toggle: Callable, on_take: Callable) -> void:
	var info := StandardMissions.info(k.mission_id)
	var head := UiKit.label(list, "%s  ·  enemy %d%% of your BV" % [info.get("name", k.mission_id), k.enemy_percent], UiKit.FONT)
	head.modulate = Color(1.0, 0.9, 0.6)
	var why := Warchest.cant_take(c, k, rules)
	var cost := k.cost(rules)
	var text := "TAKE CONTRACT  ·  %d WP" % cost
	if why == "" and c.wp < cost:
		text += "  (on Warchest debt)"
	var take := UiKit.button(list, text if why == "" else why, on_take.bind(index), Vector2(0, 64), "primary")
	take.name = "TakeContract%d" % index
	take.disabled = why != ""

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
