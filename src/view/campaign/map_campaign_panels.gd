class_name MapCampaignPanels
extends RefCounted
## Compact strategic inspector, headquarters and campaign setup.


static func setup(parent: Control, options: Dictionary) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	parent.add_child(grid)
	for entry in [["size", "Region", ["Standard (8×6)", "Wide (10×8)", "Large (12×9)"]], ["skill", "Defender skill", ["Green", "Regular", "Veteran", "Elite"]], ["company", "Starting force", ["One lance", "Two lances", "Three lances"]], ["goal", "Victory threshold (GM option)", ["60%", "80% (standard)", "100%"]]]:
		UiKit.label(grid, entry[1], 20)
		var picker := OptionButton.new()
		picker.custom_minimum_size = Vector2(280, 50)
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for choice in entry[2]:
			picker.add_item(choice)
		var key: String = entry[0]
		picker.select(int(options[key]))
		picker.item_selected.connect(func(i: int): options[key] = i)
		grid.add_child(picker)


static func inspect(parent: Control, mc: MapCampaign, z: Vector2i, db: UnitDb) -> void:
	if not mc.region.has_zone(z):
		UiKit.label(parent, "Select a zone to inspect its terrain and facilities.", 17)
		return
	UiKit.label(parent, MapGeography.zone_label(mc.region, z), 22)
	var loc := mc.region.location_at(z)
	if not loc.is_empty():
		var benefit := String(loc.get("benefit", ""))
		var benefits := {"repair": "Full repair", "fortress": "Repair and initiative support", "supply": "Armor and ammunition", "factory": "Repair and one-time reinforcement", "dropport": "Faster DropShip transit", "seaport": "Sea route between held ports"}
		UiKit.label(parent, "%s control • %d points • %s" % ["Company" if int(loc["owner"]) == 0 else "Defender", int(loc["points"]), benefits.get(benefit, "Strategic objective")], 17)
	var seen := MapFog.seen(mc)
	if seen.has(z):
		var enemies := 0
		var fit := 0
		for l in mc.lances_of(1):
			if l.on_map() and l.zone == z:
				enemies += 1
				fit += mc.fit_mechs(l).size()
		UiKit.label(parent, "Observed: %d enemy lance(s), %d ready" % [enemies, fit], 17)
	else:
		var last: Dictionary = mc.intel.get(MapOperations.key(z), {})
		UiKit.label(parent, "Unobserved" if last.is_empty() else "Last seen day %d: %d lance(s), %d ready — stale" % [int(last["day"]), int(last["lances"]), int(last["ready"])], 17)
	UiKit.label(parent, "Battlefield: " + mc.region.terrain_at(z).capitalize() + " • fixed geography", 16)
	var preview := Button.new()
	preview.text = "Preview battlefield"
	preview.custom_minimum_size.y = 44
	parent.add_child(preview)
	preview.pressed.connect(func():
		if not is_instance_valid(preview):
			return
		var picture := MapPreview.new()
		picture.custom_minimum_size.y = 130
		parent.add_child(picture)
		picture.show_map(MapBattle.battlefield(mc, z, 0))
		preview.disabled = true)


static func company(parent: Control, mc: MapCampaign, db: UnitDb, action: Callable, selected: String) -> void:
	UiKit.label(parent, "%s • %d battles" % [mc.player.name, mc.player.battles], 21)
	UiKit.label(parent, "Select a unit, then another at the same location. Use matching exchange buttons.", 16)
	for l in mc.lances_of(0):
		UiKit.label(parent, "%s • %d/%d ready" % [l.name, mc.fit_mechs(l).size(), l.mech_ids.size()], 19)
		for id in l.mech_ids:
			var m := mc.player.mech(id)
			if m == null:
				continue
			var d := db.get_def(m.design)
			var p := mc.player.pilot(m.pilot_id)
			var title := d.display_name() if d != null else m.design
			var status := "Lost" if m.written_off else "Damaged" if m.damaged() else "Intact"
			UiKit.label(parent, "%s • %s%s" % [title, status, " • SELECTED" if id == selected else ""], 17)
			if p != null:
				UiKit.label(parent, "%s (%d/%d) • wounds %d • kills %d • missions %d" % [p.name, p.gunnery, p.piloting, p.wounds, p.kills, p.battles], 15)
			if not m.written_off and mc.battles.is_empty() and mc.winner < 0:
				var row := HBoxContainer.new()
				parent.add_child(row)
				var a := UiKit.button(row, "Exchange lance", action.bind(l, id, false), Vector2(0, 40))
				var b := UiKit.button(row, "Exchange pilot", action.bind(l, id, true), Vector2(0, 40))
				for button in [a, b]:
					button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					button.add_theme_font_size_override("font_size", 15)


static func history(parent: Control, mc: MapCampaign) -> void:
	UiKit.label(parent, "Operational history", 22)
	for i in range(mc.reports.size() - 1, -1, -1):
		var report: Dictionary = mc.reports[i]
		UiKit.label(parent, "Operation %d / Day %d • %s" % [int(report["operation"]), int(report["day"]), report["zone"]], 18)
		UiKit.label(parent, "\n".join(report["lines"]), 16)
	for i in range(mc.log.size() - 1, -1, -1):
		UiKit.label(parent, mc.log[i], 16)
