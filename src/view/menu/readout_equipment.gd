class_name ReadoutEquipment
extends VBoxContainer
## Populated two-pane equipment encyclopedia with searchable, filterable results.
var _catalog: Array[Dictionary] = []
var _usage: Dictionary = {}
var _matches: Array[Dictionary] = []
var _weapons: ItemList
var _weapon_info: Label
var _equipment_filters: Dictionary = {}
var _weapon_count: Label
var _weapon_search: LineEdit


func setup(db: WeaponDb, entries: Array[UnitDef]) -> void:
	_usage = ReadoutEquipmentUsage.index(entries)
	_catalog = ReadoutEquipmentCatalog.build(db, _usage)
	name = "Equipment encyclopedia"
	_weapon_search = LineEdit.new()
	_weapon_search.custom_minimum_size.y = 48
	_weapon_search.clear_button_enabled = true
	_weapon_search.placeholder_text = "Search equipment, weapons, ammunition (optional)"
	add_child(_weapon_search)
	var filters := ReadoutFilters.row(self)
	var change := func(_i: int): _filter_weapons(_weapon_search.text)
	_equipment_filters = {"category": ReadoutFilters.choice(filters, ReadoutEquipmentCatalog.categories(_catalog), change),
		"tech": ReadoutFilters.choice(filters, ReadoutFilters.TECH.slice(0, 3), change),
		"ammo": ReadoutFilters.choice(filters, ["Any equipment", "Ammo-fed weapons", "Ammo-free weapons"], change)}
	var tools := ReadoutFilters.row(self)
	_weapon_count = UiKit.label(tools, "", 18)
	_weapon_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.button(tools, "Reset filters", _reset_weapons, Vector2(0, 44), "subtle").add_theme_font_size_override("font_size", 18)
	UiKit.label(self, "Select an item to view its details. Search and category filters are optional.", 18)
	var panes := ReadoutFilters.row(self)
	panes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_weapons = ItemList.new()
	_weapons.name = "EquipmentResults"
	_weapons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_weapons.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_weapons.add_theme_font_size_override("font_size", 20)
	_weapons.add_theme_constant_override("v_separation", 16)
	UiSkin.list_control(_weapons)
	panes.add_child(_weapons)
	var panel := UiKit.panel(panes)
	panel.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_weapon_info = UiKit.label(scroll, "", 22)
	_weapon_info.name = "EquipmentDetails"
	_weapon_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_weapon_search.text_changed.connect(_filter_weapons)
	_weapons.item_selected.connect(_weapon_selected)
	_filter_weapons("")


func _selected_index() -> int:
	var selected := _weapons.get_selected_items()
	return selected[0] if not selected.is_empty() else -1


func _reset_weapons() -> void:
	ReadoutFilters.reset(_equipment_filters)
	_weapon_search.clear()
	_filter_weapons("")


func _filter_weapons(query: String) -> void:
	var previous := ""
	var selected := _selected_index()
	if selected >= 0 and selected < _matches.size():
		previous = String(_matches[selected]["id"])
	_weapons.clear()
	_matches.clear()
	var filters := ReadoutFilters.selected(_equipment_filters, ["category"])
	var index := 0
	for item: Dictionary in _catalog:
		if not ReadoutEquipmentCatalog.matches(item, query, filters):
			continue
		if item["id"] == previous:
			index = _matches.size()
		_matches.append(item)
		_weapons.add_item("%s  •  %s" % [item["name"], _tech_label(String(item["tech"]))])
	_weapon_count.text = "%d / %d equipment entries" % [_matches.size(), _catalog.size()]
	if not _matches.is_empty():
		_weapons.select(index)
		_weapons.ensure_current_is_visible()
		_weapon_selected(index)
	else:
		_weapon_info.text = "No matching equipment. Clear search or reset filters to browse all."


static func _tech_label(tech: String) -> String:
	return "General" if tech == "both" else tech.replace("_", " ").capitalize()


func refresh_usage() -> void:
	_weapon_selected(_selected_index())


func _weapon_selected(index: int) -> void:
	if index < 0 or index >= _matches.size():
		return
	var item := _matches[index]
	var users: Array = _usage.get(item["id"], [])
	var names: Array[String] = []
	for d: UnitDef in UnitFavorites.prioritized(users, UnitFavorites.design_id).slice(0, 24):
		names.append(UnitFavorites.caption(d.id, d.display_name()))
	var suffix := " (first 24 shown)" if users.size() > 24 else ""
	_weapon_info.text = "%s\n%s • %s\n\n%s\n\nInstalled on %d catalog designs%s" % [item["name"], item["category"], _tech_label(String(item["tech"])), item["about"], users.size(), suffix]
	if not names.is_empty():
		_weapon_info.text += "\n" + "\n".join(names)
