class_name SupportPanel
extends RefCounted
## Support Points controls on the campaign screen: converting WP, waiting
## a month, hiring, and the repair, heal, train and seat buttons on each
## 'Mech and MechWarrior. `act` runs a SupportShop call (a Callable that
## returns "" or why not) and redraws the screen.

const TIP := "Between contracts, turn up to 100 WP a month into Support Points (SP) and spend them on repairs, ammo, healing, training and new MechWarriors. Training costs three times as much for a MechWarrior who sat out the last contract. Waiting a month lets you convert more WP and heal another wound, but time is all it buys."


static func header(list: VBoxContainer, c: Campaign, rules: ChaosRules, act: Callable, note: String) -> void:
	UiKit.label(list, "Support", 26).modulate = Color(0.75, 0.85, 1.0)
	if GameSettings.explain_level != ExplainLevel.OFF:
		UiSkin.label(UiKit.label(list, TIP, UiKit.SMALL), "muted")
	UiKit.label(list, "Support Points: %d SP  ·  month %d" % [c.sp, c.month], UiKit.FONT).name = "SupportLabel"
	if note != "":
		UiKit.label(list, note, UiKit.SMALL).modulate = Color(1.0, 0.7, 0.5)
	var row := _row(list)
	var wp := SupportShop.convertible(c, rules)
	var conv := _button(row, "Convert %d WP → %d SP" % [wp, roundi(wp * SupportShop.rate(c, rules))],
			act.bind(SupportShop.convert.bind(c, rules, wp)), "primary")
	conv.name = "ConvertWp"
	conv.disabled = wp <= 0 or SupportShop.closed(c) != ""
	_button(row, "Wait a month", act.bind(_wait.bind(c))).name = "WaitMonth"
	row = _row(list)
	for level in ["green", "regular", "veteran"]:
		_button(row, "Hire %s MechWarrior · %d SP" % [level, SupportShop.hire_cost(level, rules)],
				act.bind(SupportShop.hire.bind(c, level, rules)))
	var free := c.free_pilots()
	if not free.is_empty():
		var names: Array[String] = []
		for p in free:
			names.append("%s (Gunnery %d, Piloting %d)" % [p.name, p.gunnery, p.piloting])
		UiKit.label(list, "Without a 'Mech: " + ", ".join(names), UiKit.SMALL)


static func mech_actions(list: VBoxContainer, c: Campaign, m: CampaignMech, def: UnitDef,
		rules: ChaosRules, act: Callable) -> void:
	var row := _row(list)
	var labels := {MechRepair.ARMOR: "Repair armor", MechRepair.STRUCTURE: "Repair structure", MechRepair.AMMO: "Rearm"}
	for job: String in MechRepair.JOBS:
		if MechRepair.needs(m, def, job):
			_button(row, "%s · %d SP" % [labels[job], MechRepair.cost(def, job, rules)],
					act.bind(SupportShop.repair.bind(c, m, def, job, rules))).name = "Repair_%s_%s" % [m.id, job]
	var p := c.pilot(m.pilot_id)
	if not m.written_off and (p == null or p.dead):
		for f in c.free_pilots():
			_button(row, "Seat " + f.name, act.bind(SupportShop.assign.bind(c, m, f, def)))
	if p != null and not p.dead:
		if p.wounds > 0:
			_button(row, "Heal a wound · %d SP" % rules.sp("heal_wound"), act.bind(SupportShop.heal.bind(c, p, rules)))
		for skill in ["gunnery", "piloting"]:
			_button(row, "Train %s · %d SP" % [skill, SupportShop.train_cost(p, skill, rules)],
					act.bind(SupportShop.train.bind(c, p, skill, rules)))


static func _wait(c: Campaign) -> String:
	if c.contract != null:
		return "Finish the current contract first."
	SupportShop.new_month(c)
	return ""


static func _row(list: VBoxContainer) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	list.add_child(row)
	return row


static func _button(row: Control, text: String, on_press: Callable, tone := "subtle") -> Button:
	var b := UiKit.button(row, text, on_press, Vector2(0, 52), tone)
	b.add_theme_font_size_override("font_size", UiKit.SMALL)
	return b
