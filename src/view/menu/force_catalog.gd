class_name ForceCatalog
extends RefCounted
## Searchable, paginated unit catalog. Only one unit category is built at once.

const TYPES := ["'Mechs", "Vehicles", "Battle Armor", "Support"]
const PAGE_SIZE := 12

var db: UnitDb
var builder: ForceBuilder
var mode := DesignFilter.Mode.ALL
var category := 0
var active_side := 0
var query := ""
var verified_only := false
var _on_add: Callable
var _config := {}
var _shown := PAGE_SIZE
var _cards: Array[Dictionary] = []
var _list: VBoxContainer
var _counter: Label
var _more: Button
var _tech: Button
var _historical: Button
var _tab_buttons: Array[Button] = []


func _init(unit_db: UnitDb, on_add: Callable, force_builder: ForceBuilder) -> void:
	db = unit_db
	builder = force_builder
	_on_add = on_add


func build(parent: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.25
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	scroll.add_child(outer)
	UiSkin.label(UiKit.label(outer, "UNIT CATALOG", 23), "section")
	var search := LineEdit.new()
	search.name = "UnitSearch"
	search.placeholder_text = "Search name, model, weapons…"
	search.clear_button_enabled = true
	search.custom_minimum_size.y = 52
	search.add_theme_font_size_override("font_size", 20)
	search.text_changed.connect(func(t: String): query = t; rebuild())
	outer.add_child(search)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	outer.add_child(tabs)
	for i in TYPES.size():
		var index := i
		var tab := UiKit.button(tabs, TYPES[i], func(): _change_type(index),
			Vector2(0, 49), "subtle")
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 16)
		tab.clip_text = true
		_tab_buttons.append(tab)
	_tech = UiKit.button(outer, "", func():
		mode = DesignFilter.next(mode)
		rebuild(), Vector2(0, 50), "subtle")
	_tech.add_theme_font_size_override("font_size", 18)
	_historical = UiKit.button(outer, "", func():
		verified_only = not verified_only
		rebuild(), Vector2(0, 50), "subtle")
	_historical.add_theme_font_size_override("font_size", 18)
	_counter = UiKit.label(outer, "", 17)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	outer.add_child(_list)
	_more = UiKit.button(outer, "SHOW MORE", func():
		_shown += PAGE_SIZE
		_draw(), Vector2(0, 58))
	rebuild()


func set_active_side(side: int) -> void:
	active_side = side
	rebuild()


func _change_type(next_type: int) -> void:
	category = next_type
	rebuild()


func rebuild() -> void:
	_shown = PAGE_SIZE
	_draw()


func _matches() -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	if category == 0:
		for g: Array in DesignFilter.groups(db, mode):
			var variants: Array = g.filter(func(d: UnitDef) -> bool:
				return ForceCatalogQuery.matches(d, query) and (
					not verified_only or builder.availability_for(active_side, d.id)["status"] == "available"))
			if variants.is_empty():
				continue
			var index := int(_config.get(g[0].chassis, 0)) % variants.size()
			matches.append({"def": variants[index], "group": variants})
	else:
		var source: Array = db.sorted_vehicles() if category == 1 else (
			db.sorted_battle_armor() if category == 2 else db.sorted_assets())
		for def: UnitDef in source:
			if DesignFilter.keeps(def, mode) and ForceCatalogQuery.matches(def, query) and (
					not verified_only or builder.availability_for(active_side, def.id)["status"] == "available"):
				matches.append({"def": def, "group": [def]})
	return matches


func _draw() -> void:
	if _list == null:
		return
	UiKit.clear(_list)
	_cards.clear()
	for i in _tab_buttons.size():
		UiSkin.button(_tab_buttons[i], "selected" if i == category else "subtle")
	_tech.text = "TECH: " + ["All technology", "Inner Sphere", "Clan"][mode] + "  ▸"
	_historical.text = "HISTORY: " + ("VERIFIED ONLY" if verified_only else "SHOW ALL") + "  ▸"
	var matches := _matches()
	var count := mini(_shown, matches.size())
	_counter.text = "%d of %d matches  •  Add to %s" % [
		count, matches.size(), Names.side(active_side)]
	if matches.is_empty():
		UiSkin.label(UiKit.label(_list, "No verified units here. Broaden your search or turn off the history filter." if verified_only else "No matching units. Try a different name or filter.", 19), "muted")
	for i in count:
		var entry: Dictionary = matches[i]
		var def: UnitDef = entry["def"]
		var group: Array = entry["group"]
		var group_key: String = def.chassis
		var card := ForceCatalogCard.build(_list, def, group,
			func(): _on_add.call(active_side, def.id),
			func():
				_config[group_key] = int(_config.get(group_key, 0)) + 1
				_draw())
		_cards.append(card)
	_more.visible = count < matches.size()
	refresh()


func refresh() -> void:
	if _list == null:
		return
	for card: Dictionary in _cards:
		var def: UnitDef = card["def"]
		var button: Button = card["button"]
		var why := builder.cant_add(active_side, def.id)
		var current := builder.bv(active_side)
		var proposed := builder.bv(active_side, def.id)
		(card["cost"] as Label).text = "+%d BV  •  %d left after" % [
			proposed - current, builder.budget - proposed]
		var warning := ""
		if builder.availability_mode != EraAvailability.Mode.OFF:
			var report := builder.availability_for(active_side, def.id)
			if report["status"] != "available":
				warning = "HISTORY: " + String(report["reason"])
		(card["info"] as Label).text = why if why != "" else (
			warning if warning != "" else "Ready to deploy")
		button.disabled = why != ""
		button.text = "ADD TO " + Names.side(active_side).to_upper()
		UiSkin.button(button, "primary" if why == "" else "subtle")
	_counter.text = _counter.text.get_slice("  •  ", 0) + "  •  Add to " + Names.side(active_side)
