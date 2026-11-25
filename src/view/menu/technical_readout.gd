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
	_picker = OptionButton.new()
	_picker.fit_to_longest_item = false
	_picker.clip_text = true
	_picker.custom_minimum_size.y = 48
	left.add_child(_picker)
	_picker.item_selected.connect(_select)
	var info := _scroll_body(left)
	_name_line = UiKit.label(info, "", 25)
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
	var query := LineEdit.new()
	query.custom_minimum_size.y = 48
	query.clear_button_enabled = true
	query.placeholder_text = "Search weapons and ammunition"
	encyclopedia.add_child(query)
	_weapons = OptionButton.new()
	_weapons.fit_to_longest_item = false
	_weapons.clip_text = true
	_weapons.custom_minimum_size.y = 48
	encyclopedia.add_child(_weapons)
	_weapon_info = UiKit.label(_scroll_body(encyclopedia), "", 20)
	query.text_changed.connect(_filter_weapons)
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
		var role := d.role.get_slice(":", 0).strip_edges()
		if not role.is_empty() and role.length() <= 36:
			fields.append(role)
		fields.append("%d BV" % d.bv)
	return "  •  ".join(fields)


func _filter(query: String) -> void:
	_picker.clear()
	_matches.clear()
	var needle := query.strip_edges().to_lower()
	for d: UnitDef in _entries:
		if needle != "" and not (d.display_name() + " " + d.role + " " + ForceCatalogCard.weapons_line(d)).to_lower().contains(needle):
			continue
		_matches.append(d)
		_picker.add_item(design_heading(d))
	if not _matches.is_empty():
		_picker.select(0)
		_select(0)
	else:
		_selected = null
		_name_line.text = "No matching designs."
		_details.text = ""
		_viewer.select_design(null)
		_compare()


func _select(index: int) -> void:
	if index < 0 or index >= _matches.size():
		return
	_selected = _matches[index]
	var d := _selected
	_name_line.text = design_heading(d)
	if d.asset != null or d.vehicle != null or d.battle_armor != null:
		_details.text = "%s\n%s" % [ForceCatalogCard.description(d), ForceCatalogCard.weapons_line(d)]
	else:
		_details.text = "%s • %s\nWalk / run / jump  %d / %d / %d\nArmor  %d  •  Heat dissipation  %d\nWEAPONS  %s\n%s" % [d.weight_class(), d.tech_base.replace("_", " "), d.walk_mp, d.run_mp(), d.jump_mp, d.total_armor(), d.heat_sinks * d.heat_per_sink(), ForceCatalogCard.weapons_line(d), d.role.get_slice(":", 1).strip_edges()]
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
	_weapons.clear()
	_weapon_ids.clear()
	var ids := _db.weapons.by_id.keys()
	ids.sort()
	for id: String in ids:
		var w := _db.weapons.get_def(id)
		if not (w.name + " " + w.type + " " + id).to_lower().contains(query.to_lower()):
			continue
		_weapon_ids.append(id)
		_weapons.add_item(w.name)
	if not ids.is_empty() and not _weapon_ids.is_empty():
		_weapons.select(0)
		_weapon_selected(0)
	else:
		_weapon_info.text = "No matching weapons."


func _weapon_selected(index: int) -> void:
	if index < 0 or index >= _weapon_ids.size():
		return
	var w := _db.weapons.get_def(_weapon_ids[index])
	var compatible: Array[String] = []
	for d: UnitDef in _entries:
		if d.weapon_mounts.any(func(m: Dictionary) -> bool: return m["weapon"].id == w.id):
			compatible.append(d.display_name())
	_weapon_info.text = "%s • %s • %s\nDamage %d maximum • Heat %d • Range %s\n%.2f tons • %d slots • BV %d • Ammo/ton %d\nMounted on %d catalog designs: %s" % [w.name, w.type, w.tech, w.max_damage(), w.heat, w.range_text(), w.tons, w.slots, w.bv, w.ammo_per_ton, compatible.size(), ", ".join(compatible.slice(0, 24))]
