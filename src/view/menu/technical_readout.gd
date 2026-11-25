class_name TechnicalReadout
extends Control
## Searchable official design catalog, weapon encyclopedia, and A/B comparison.
var _db: UnitDb
var _entries: Array[UnitDef] = []
var _matches: Array[UnitDef] = []
var _search: LineEdit
var _picker: OptionButton
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
	var scroll := UiKit.landscape_scroll(self, 16)
	var box := UiKit.panel(scroll)
	box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := HBoxContainer.new()
	box.add_child(head)
	UiKit.button(head, "Back", queue_free, Vector2(110, 48))
	UiKit.label(head, "TECHNICAL READOUT  /  FIELD DATABASE", 30)
	var tabs := TabContainer.new()
	box.add_child(tabs)
	var designs := HBoxContainer.new()
	designs.name = "Units & comparison"
	tabs.add_child(designs)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	designs.add_child(left)
	_search = LineEdit.new()
	_search.placeholder_text = "Search chassis, variant, role or weapon"
	left.add_child(_search)
	_search.text_changed.connect(_filter)
	_picker = OptionButton.new()
	_picker.fit_to_longest_item = false
	_picker.clip_text = true
	_picker.custom_minimum_size.y = 48
	left.add_child(_picker)
	_picker.item_selected.connect(_select)
	_details = UiKit.label(left, "", 20)
	var pin := UiKit.button(left, "Pin selected unit for comparison", _pin, Vector2(0, 48))
	pin.name = "PinComparison"
	_comparison = UiKit.label(left, "", 18)
	_viewer = ReadoutModel.new()
	designs.add_child(_viewer)
	var encyclopedia := VBoxContainer.new()
	encyclopedia.name = "Equipment encyclopedia"
	tabs.add_child(encyclopedia)
	var query := LineEdit.new()
	query.placeholder_text = "Search weapons and ammunition"
	encyclopedia.add_child(query)
	_weapons = OptionButton.new()
	_weapons.fit_to_longest_item = false
	_weapons.clip_text = true
	_weapons.custom_minimum_size.y = 48
	encyclopedia.add_child(_weapons)
	_weapon_info = UiKit.label(encyclopedia, "", 20)
	query.text_changed.connect(_filter_weapons)
	_weapons.item_selected.connect(_weapon_selected)
	_filter("")
	_filter_weapons("")


func _filter(query: String) -> void:
	_picker.clear()
	_matches.clear()
	var needle := query.strip_edges().to_lower()
	for d: UnitDef in _entries:
		if needle != "" and not (d.display_name() + " " + d.role + " " + ForceCatalogCard.weapons_line(d)).to_lower().contains(needle):
			continue
		_matches.append(d)
		_picker.add_item(d.display_name())
	if not _matches.is_empty():
		_picker.select(0)
		_select(0)
	else:
		_details.text = "No matching designs."


func _select(index: int) -> void:
	_selected = _matches[index]
	var d := _selected
	_details.text = "%s\n%s • %d BV • %s\nWalk/run/jump %d/%d/%d • Armor %d\nHeat dissipation %d • %s\n%s" % [d.display_name(), ForceCatalogCard.description(d), d.bv, d.tech_base.replace("_", " "), d.walk_mp, d.run_mp(), d.jump_mp, d.total_armor(), d.heat_sinks * d.heat_per_sink(), d.role, ForceCatalogCard.weapons_line(d)]
	_viewer.show_design(d)
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
	var w := _db.weapons.get_def(_weapon_ids[index])
	var compatible: Array[String] = []
	for d: UnitDef in _entries:
		if d.weapon_mounts.any(func(m: Dictionary) -> bool: return m["weapon"].id == w.id):
			compatible.append(d.display_name())
	_weapon_info.text = "%s • %s • %s\nDamage %d maximum • Heat %d • Range %s\n%.2f tons • %d slots • BV %d • Ammo/ton %d\nMounted on %d catalog designs: %s" % [w.name, w.type, w.tech, w.max_damage(), w.heat, w.range_text(), w.tons, w.slots, w.bv, w.ammo_per_ton, compatible.size(), ", ".join(compatible.slice(0, 24))]
