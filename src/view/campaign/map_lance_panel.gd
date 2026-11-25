class_name MapLancePanel
extends RefCounted
## Map campaign rows: your lances with their orders (and the order buttons
## for the chosen one), and this turn's battles with FIGHT buttons.


static func lances(list: VBoxContainer, mc: MapCampaign, chosen: String, on_select: Callable,
		on_order: Callable, can_order: bool) -> void:
	UiKit.label(list, "Your lances", 26).modulate = Color(0.75, 0.85, 1.0)
	for l in mc.lances_of(0):
		var id := l.id
		var b := UiKit.button(list, line(mc, l), func(): on_select.call(id), Vector2(0, 76),
				"selected" if id == chosen else "subtle")
		b.name = "Lance_" + id
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 19)
		b.tooltip_text = line(mc, l)
		if id == chosen and can_order:
			var row := HFlowContainer.new()
			list.add_child(row)
			for order: String in MapLance.ORDERS:
				var o := order
				var ob := UiKit.button(row, MapLance.NAMES[o], func(): on_order.call(o), Vector2(150, 54),
						"primary" if l.order == o else "secondary")
				ob.name = "Order_" + o
				ob.disabled = MapOrders.can_take(mc, l, o) != ""


## "Alpha Lance · Riverside · 4 of 4 fit · Attack → Hills".
static func line(mc: MapCampaign, l: MapLance) -> String:
	var at := where(mc, l.zone) if l.on_map() else "in the air"
	var s := "%s · %d/%d fit\n%s · %s" % [l.name, mc.fit_mechs(l).size(),
			l.mech_ids.size(), at, MapLance.NAMES[l.order]]
	var heading := l.reach() > 0 or l.order == MapLance.DROPSHIP
	if heading and l.target != l.zone and mc.region.has_zone(l.target):
		s += " → " + where(mc, l.target)
	return s


static func where(mc: MapCampaign, z: Vector2i) -> String:
	var loc := mc.region.location_at(z)
	return String(loc["name"]) if not loc.is_empty() else "%s (%d,%d)" % [mc.region.terrain_at(z).capitalize(), z.x + 1, z.y + 1]


static func battles(list: VBoxContainer, mc: MapCampaign, on_fight: Callable) -> void:
	UiKit.label(list, "Battles today", 26).modulate = Color(1.0, 0.8, 0.55)
	for i in mc.battles.size():
		var b := mc.battles[i]
		var mine := mc.lance(String(b["attacker"]) if String(b["attacker"]).begins_with("p") else String(b["defender"]))
		var attacking := String(b["attacker"]).begins_with("p")
		var row := HBoxContainer.new()
		list.add_child(row)
		var text := UiKit.label(row, "%s at %s: %s, you %s  (roll %d%+d, %s column)" % [
				ScenarioTable.name_of(b["scenario"]), where(mc, b["zone"]),
				mine.name if mine != null else "your lance", "attack" if attacking else "defend",
				int(b["roll"]), int(b["mod"]), String(b["column"])], UiKit.SMALL)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx := i
		UiKit.button(row, "FIGHT", func(): on_fight.call(idx), Vector2(150, 60), "primary").name = "Fight_%d" % i
