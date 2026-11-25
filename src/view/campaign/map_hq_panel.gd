class_name MapHqPanel
extends RefCounted
## Company personnel, damage and co-located formation transfers.


static func build(parent: VBoxContainer, mc: MapCampaign, db: UnitDb, refresh: Callable) -> void:
	UiKit.label(parent, "COMPANY HEADQUARTERS", 25)
	var a_select := OptionButton.new()
	var b_select := OptionButton.new()
	var entries: Array[Dictionary] = []
	for l in mc.lances_of(0):
		UiKit.label(parent, MapLancePanel.line(mc, l), 20)
		for id in l.mech_ids:
			var m := mc.player.mech(id)
			if m == null:
				continue
			var p := mc.player.pilot(m.pilot_id)
			var def := db.get_def(m.design)
			var design := def.display_name() if def != null else m.design
			var state := "Written off" if m.written_off else "Damaged" if m.damaged() else "Undamaged"
			UiKit.label(parent, "%s · %s\n%s" % [design, state,
				"%s · G%d/P%d · %d wounds · %d battles · %d kills" % [p.name, p.gunnery, p.piloting, p.wounds, p.battles, p.kills] if p != null else "Unassigned"], 17)
			if not m.written_off:
				entries.append({"lance": l, "mech": id})
				a_select.add_item(l.name + " / " + design)
				b_select.add_item(l.name + " / " + design)
	if entries.size() < 2:
		a_select.free()
		b_select.free()
		return
	UiKit.label(parent, "Reorganize co-located lances before issuing orders.", 17)
	for picker in [a_select, b_select]:
		picker.fit_to_longest_item = false
		picker.clip_text = true
		picker.custom_minimum_size.y = 52
		parent.add_child(picker)
	b_select.select(1)
	var note := UiKit.label(parent, "", 17)
	for pilots in [false, true]:
		var is_pilot: bool = pilots
		UiKit.button(parent, "SWAP PILOTS" if is_pilot else "SWAP MECHS", func():
			var a: Dictionary = entries[a_select.selected]
			var b: Dictionary = entries[b_select.selected]
			var ok := MapHeadquarters.swap_pilots(mc, a["lance"], b["lance"], a["mech"], b["mech"]) if is_pilot else MapHeadquarters.swap_mechs(mc, a["lance"], b["lance"], a["mech"], b["mech"])
			if ok:
				MapCampaignStore.save(mc)
				refresh.call()
			else:
				note.text = "Transfer unavailable: check location, orders, combat status and personnel."
			, Vector2(0, 52), "secondary")
	UiKit.label(parent, "PERSONNEL RECORD", 20)
	for p in mc.player.pilots:
		UiKit.label(parent, "%s · %s · %d battles · %d kills" % [p.name, "KIA" if p.dead else "Active", p.battles, p.kills], 17)
