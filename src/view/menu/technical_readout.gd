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
var _unit_filters: Dictionary = {}
var _unit_count: Label


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
	var encyclopedia := ReadoutEquipment.new()
	tabs.add_child(encyclopedia)
	encyclopedia.setup(_db.weapons, _entries)
	_filter("")


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

