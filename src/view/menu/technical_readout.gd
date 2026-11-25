class_name TechnicalReadout
extends Control
## Searchable official design catalog, weapon encyclopedia, and A/B comparison.
var _db: UnitDb
var _entries: Array[UnitDef] = []
var _matches: Array[UnitDef] = []
var _search: LineEdit
var _picker: OptionButton
var _name_line: Label
var _details: Label
var _comparison: Label
var _viewer: ReadoutModel
var _selected: UnitDef
var _pinned: UnitDef
var _weapons: OptionButton
var _weapon_ids: Array[String] = []
var _weapon_info: Label
var _unit_filters: Dictionary = {}
var _equipment_filters: Dictionary = {}
var _unit_count: Label
var _weapon_count: Label
var _weapon_search: LineEdit


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
	_db = UnitDb.load_dir()
	_entries = _db.sorted_defs()
	_entries.append_array(_db.sorted_vehicles())
	_entries.append_array(_db.sorted_battle_armor())
	_entries.append_array(_db.sorted_assets())
	var box := UiKit.screen_body(self, "TECHNICAL READOUT  /  FIELD DATABASE",
			UiKit.close_overlay.bind(self), 16)
	var tabs := TabContainer.new()
	tabs.name = "ReadoutTabs"
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size.y = 440
	box.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)
	var designs := HBoxContainer.new()
	designs.name = "Units & comparison"
	designs.add_theme_constant_override("separation", 12)
	tabs.add_child(designs)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	designs.add_child(left)
	_search = LineEdit.new()
	_search.placeholder_text = "Search chassis, variant, role or weapon"
	_search.custom_minimum_size.y = 48
	_search.clear_button_enabled = true
	left.add_child(_search)
	_search.text_changed.connect(_filter)
	_unit_filters = ReadoutFilters.unit_controls(left, _entries, func(_i: int): _filter(_search.text))
	var unit_tools := ReadoutFilters.row(left)
	_unit_count = UiKit.label(unit_tools, "", 18)
	_unit_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.button(unit_tools, "Reset filters", _reset_units, Vector2(0, 44), "subtle").add_theme_font_size_override("font_size", 18)
	_picker = OptionButton.new()
	_picker.fit_to_longest_item = false
	_picker.clip_text = true
	_picker.custom_minimum_size.y = 48
	left.add_child(_picker)
	_picker.item_selected.connect(_select)
	var info := _scroll_body(left)
	info.get_parent().name = "ReadoutDetailsScroll"
	_name_line = UiKit.label(info, "", 25)
	_name_line.name = "UnitHeading"
	_details = UiKit.label(info, "", 20)
	UiSkin.rule(info, UiSkin.BORDER)
	var pin := UiKit.button(info, "Pin selected unit for comparison", _pin, Vector2(0, 48))
	pin.name = "PinComparison"
	_comparison = UiKit.label(info, "", 18)
	_viewer = ReadoutModel.new()
	designs.add_child(_viewer)
	var encyclopedia := VBoxContainer.new()
	encyclopedia.name = "Equipment encyclopedia"
	tabs.add_child(encyclopedia)
	_weapon_search = LineEdit.new()
	_weapon_search.custom_minimum_size.y = 48
	_weapon_search.clear_button_enabled = true
	_weapon_search.placeholder_text = "Search weapons by name or type (optional)"
	encyclopedia.add_child(_weapon_search)
	_equipment_filters = ReadoutFilters.weapon_controls(encyclopedia, _db.weapons, func(_i: int): _filter_weapons(_weapon_search.text))
	var weapon_tools := ReadoutFilters.row(encyclopedia)
	_weapon_count = UiKit.label(weapon_tools, "", 18)
	_weapon_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.button(weapon_tools, "Reset filters", _reset_weapons, Vector2(0, 44), "subtle").add_theme_font_size_override("font_size", 18)
	UiKit.label(encyclopedia, "Browse all weapons below or narrow the list using search and filters.", 18)
	_weapons = OptionButton.new()
	_weapons.fit_to_longest_item = false
	_weapons.clip_text = true
	_weapons.custom_minimum_size.y = 48
	encyclopedia.add_child(_weapons)
	_weapon_info = UiKit.label(_scroll_body(encyclopedia), "", 20)
	_weapon_search.text_changed.connect(_filter_weapons)
	_weapons.item_selected.connect(_weapon_selected)
	_filter("")
	_filter_weapons("")


static func _scroll_body(parent: Control) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	parent.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)
	return body


static func design_heading(d: UnitDef) -> String:
	var fields := PackedStringArray([d.display_name()])
	if d.asset != null:
		fields.append("%d BSP" % d.asset.bsp)
	else:
		if d.tonnage > 0:
			fields.append("%d t" % d.tonnage)
		var role := ReadoutFilters.role(d)
		if not role.is_empty():
			fields.append(role)
		fields.append("%d BV" % d.bv)
	return "  •  ".join(fields)


func _filter(query: String) -> void:
	var previous := _selected
	_picker.clear()
	_matches.clear()
	var filters := ReadoutFilters.selected(_unit_filters, ["role"])
	for d: UnitDef in _entries:
		if ReadoutFilters.unit_matches(d, query, filters):
			_matches.append(d)
	ReadoutFilters.sort_units(_matches, int(filters.get("sort", 0)))
	for d: UnitDef in _matches:
		_picker.add_item(design_heading(d))
	_unit_count.text = "%d / %d designs" % [_matches.size(), _entries.size()]
	_picker.disabled = _matches.is_empty()
	if not _matches.is_empty():
		var index := maxi(0, _matches.find(previous))
		_picker.select(index)
		if previous != _matches[index]:
			_select(index)
	else:
		_selected = null
		_name_line.text = "No matching designs."
		_details.text = ""
		_viewer.select_design(null)
		_compare()


func _reset_units() -> void:
	ReadoutFilters.reset(_unit_filters)
	_search.clear()
	_filter("")


func _reset_weapons() -> void:
	ReadoutFilters.reset(_equipment_filters)
	_weapon_search.clear()
	_filter_weapons("")


func _select(index: int) -> void:
	if index < 0 or index >= _matches.size():
		return
	_selected = _matches[index]
	var d := _selected
	_name_line.text = design_heading(d)
	if d.asset != null or d.vehicle != null or d.battle_armor != null:
		_details.text = "%s\n%s" % [ForceCatalogCard.description(d), ForceCatalogCard.weapons_line(d)]
	else:
		_details.text = "%s • %s\nWalk / run / jump  %d / %d / %d\nArmor  %d  •  Heat dissipation  %d\nWEAPONS  %s\n%s" % [d.weight_class(), d.tech_base.replace("_", " "), d.walk_mp, d.run_mp(), d.jump_mp, d.total_armor(), d.heat_sinks * d.heat_per_sink(), ForceCatalogCard.weapons_line(d), d.role.substr(d.role.find(":") + 1).strip_edges() if ":" in d.role else d.role]
	_viewer.select_design(d)
	_compare()


func _pin() -> void:
	_pinned = _selected
	_compare()


func _compare() -> void:
	if _pinned == null or _selected == null:
		_comparison.text = "Pin one design, then select another."
		return
	var a := _pinned
	var b := _selected
	_comparison.text = "A: %s  /  B: %s\nTons %d / %d   •   BV %d / %d\nArmor %d / %d   •   Walk %d / %d   •   Jump %d / %d\nNominal alpha damage %d / %d   •   Weapon heat %d / %d" % [a.display_name(), b.display_name(), a.tonnage, b.tonnage, a.bv, b.bv, a.total_armor(), b.total_armor(), a.walk_mp, b.walk_mp, a.jump_mp, b.jump_mp, _alpha(a, false), _alpha(b, false), _alpha(a, true), _alpha(b, true)]


static func _alpha(d: UnitDef, heat: bool) -> int:
	var n := 0
	for mount: Dictionary in d.weapon_mounts:
		var w: WeaponDef = mount["weapon"]
		if not w.ams:
			n += w.heat if heat else w.max_damage()
	return n


func _filter_weapons(query: String) -> void:
	var previous := ""
	if _weapons.selected >= 0 and _weapons.selected < _weapon_ids.size():
		previous = _weapon_ids[_weapons.selected]
	_weapons.clear()
	_weapon_ids.clear()
	var filters := ReadoutFilters.selected(_equipment_filters, ["type"])
	var matches: Array[WeaponDef] = []
	for w: WeaponDef in _db.weapons.by_id.values():
		if ReadoutFilters.weapon_matches(w, query, filters):
			matches.append(w)
	matches.sort_custom(func(a: WeaponDef, b: WeaponDef) -> bool:
		return a.name.naturalnocasecmp_to(b.name) < 0 if a.name != b.name else a.id < b.id)
	for w: WeaponDef in matches:
		_weapon_ids.append(w.id)
		_weapons.add_item("%s  •  %s" % [w.name, w.tech.replace("_", " ").capitalize()])
	_weapon_count.text = "%d / %d weapons" % [_weapon_ids.size(), _db.weapons.by_id.size()]
	_weapons.disabled = _weapon_ids.is_empty()
	if not _weapon_ids.is_empty():
		var index := maxi(0, _weapon_ids.find(previous))
		_weapons.select(index)
		_weapon_selected(index)
	else:
		_weapon_info.text = "No matching weapons. Clear search or reset filters to browse all."


func _weapon_selected(index: int) -> void:
	if index < 0 or index >= _weapon_ids.size():
		return
	var w := _db.weapons.get_def(_weapon_ids[index])
	var compatible: Array[String] = []
	for d: UnitDef in _entries:
		if d.weapon_mounts.any(func(m: Dictionary) -> bool: return m["weapon"].id == w.id):
			compatible.append(d.display_name())
	_weapon_info.text = "%s • %s • %s\nDamage %d maximum • Heat %d • Range %s\n%.2f tons • %d slots • BV %d • Ammo/ton %d\nMounted on %d catalog designs: %s" % [w.name, w.type, w.tech, w.max_damage(), w.heat, w.range_text(), w.tons, w.slots, w.bv, w.ammo_per_ton, compatible.size(), ", ".join(compatible.slice(0, 24))]
