class_name ForceCatalog
extends RefCounted
## The force builder's 'Mech list: a technology filter, one panel per design
## or OmniMech chassis (a button cycles its configurations), add buttons.

var db: UnitDb
var mode := DesignFilter.Mode.ALL
var _on_add: Callable
var _list: VBoxContainer
var _filter_button: Button
var _config := {}  ## Chassis id -> index of the shown configuration.
var _bv_labels: Array = []  ## [Label, UnitDef] per shown panel.
var _assets: VBoxContainer
var _vehicles: VBoxContainer
var _squads: VBoxContainer
var _asset_tips: Array[Label] = []


func _init(unit_db: UnitDb, on_add: Callable) -> void:
	db = unit_db
	_on_add = on_add


func build(parent: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 2.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(outer)
	var heading := UiKit.label(outer, "UNIT CATALOG  /  'MECHS", 22)
	UiSkin.label(heading, "section")
	UiSkin.rule(outer)
	_filter_button = UiKit.button(outer, "", func(): mode = DesignFilter.next(mode); rebuild(), Vector2(0, 56))
	_list = VBoxContainer.new()
	outer.add_child(_list)
	UiSkin.label(UiKit.label(outer, "COMBAT VEHICLES", 21), "section")
	_vehicles = VBoxContainer.new()
	outer.add_child(_vehicles)
	UiSkin.label(UiKit.label(outer, "BATTLE ARMOR", 21), "section")
	_squads = VBoxContainer.new()
	outer.add_child(_squads)
	UiSkin.label(UiKit.label(outer, "BATTLEFIELD SUPPORT", 21), "section")
	_assets = VBoxContainer.new()
	outer.add_child(_assets)
	rebuild()


func rebuild() -> void:
	UiKit.clear(_list)
	_bv_labels.clear()
	_asset_tips.clear()
	_filter_button.text = "Show: " + DesignFilter.NAMES[mode]
	for g: Array in DesignFilter.groups(db, mode):
		_panel(g)
	UiKit.clear(_vehicles)
	for def in db.sorted_vehicles():
		if DesignFilter.keeps(def, mode):
			_vehicle_panel(def)
	UiKit.clear(_squads)
	for def in db.sorted_battle_armor():
		if DesignFilter.keeps(def, mode):
			_squad_panel(def)
	UiKit.clear(_assets)
	for def in db.sorted_assets():
		if DesignFilter.keeps(def, mode):
			_asset_panel(def)
	refresh()


## Re-reads the explanation level.
func refresh() -> void:
	for pair: Array in _bv_labels:
		var def: UnitDef = pair[1]
		var t := BvText.line(def, GameSettings.explain_level)
		if GameSettings.explain_level == ExplainLevel.FULL and DesignFilter.tech_tip(def) != "":
			t += ("\n" if t != "" else "") + DesignFilter.tech_tip(def)
		pair[0].text = t
		pair[0].visible = t != ""
	for l in _asset_tips:
		l.visible = GameSettings.explain_level == ExplainLevel.FULL


func _panel(g: Array) -> void:
	var def: UnitDef = g[_config.get(g[0].chassis, 0) % g.size()]
	var box := UiKit.panel(_list)
	var tag := " [Clan]" if def.is_clan() else ""
	UiKit.label(box, "%s%s  ·  BV %d  ·  %d t %s  ·  %d/%d MP  ·  %d armor" % [def.display_name(), tag,
			BattleValue.of(def), def.tonnage, def.weight_class(), def.walk_mp, def.run_mp(), def.total_armor()])
	UiKit.label(box, weapons_line(def), UiKit.SMALL)
	_bv_labels.append([UiKit.label(box, "", UiKit.SMALL), def])
	if def.role != "":
		UiKit.label(box, def.role, UiKit.SMALL).modulate = Color(0.8, 0.85, 0.75)
	var row := HBoxContainer.new()
	box.add_child(row)
	for side in 2:
		UiKit.button(row, "+ " + Names.side(side), _on_add.bind(side, def.id), Vector2(140, 56))
	if g.size() > 1:
		UiKit.button(row, "%s %d/%d ▸" % [def.config, g.find(def) + 1, g.size()], func():
				_config[def.chassis] = g.find(def) + 1
				rebuild(), Vector2(120, 56))


## One combat vehicle record sheet: BV, motive, MP, armor, weapons.
func _vehicle_panel(def: UnitDef) -> void:
	var v := def.vehicle
	var box := UiKit.panel(_vehicles)
	UiKit.label(box, "%s%s  ·  BV %d  ·  %d t %s  ·  %d/%d MP  ·  %d armor%s" % [def.name, " [Clan]" if def.is_clan() else "",
			def.bv, def.tonnage, v.motive_name().to_lower(), v.cruise_mp, v.flank_mp(), def.total_armor(),
			"  ·  turret" if v.turret else ""])
	UiKit.label(box, weapons_line(def), UiKit.SMALL)
	_asset_tips.append(UiKit.label(box, "Record-sheet vehicle: hit locations, motive damage and critical hits, no heat. Counts as support (4 per side).", UiKit.SMALL))
	var row := HBoxContainer.new()
	box.add_child(row)
	for side in 2:
		UiKit.button(row, "+ " + Names.side(side), _on_add.bind(side, def.id), Vector2(140, 56))


## One battle armor squad: BV, troopers, armor, MP, weapons.
func _squad_panel(def: UnitDef) -> void:
	var b := def.battle_armor
	var box := UiKit.panel(_squads)
	UiKit.label(box, "%s %s  ·  BV %d  ·  %d troopers, %d armor each  ·  %d/%d MP jump" % [def.name, def.model, def.bv,
			b.troopers, b.armor, b.ground_mp, b.jump_mp])
	var ws: Array[String] = []
	for w: Dictionary in b.weapons:
		ws.append(String(w["name"]))
	UiKit.label(box, ", ".join(ws) + (", battle claws" if b.claw else ""), UiKit.SMALL)
	_asset_tips.append(UiKit.label(box, "Armored infantry: each trooper fires, more troopers mean more hits. Hard to hit (+1). Counts as support (4 per side).", UiKit.SMALL))
	var row := HBoxContainer.new()
	box.add_child(row)
	for side in 2:
		UiKit.button(row, "+ " + Names.side(side), _on_add.bind(side, def.id), Vector2(140, 56))


## One Asset card: its numbers, role and add buttons.
func _asset_panel(def: UnitDef) -> void:
	var c := def.asset
	var box := UiKit.panel(_assets)
	UiKit.label(box, "%s%s  ·  BV %d (%d BSP)  ·  %s %s" % [def.name, " [Clan]" if def.is_clan() else "",
			def.bv, c.bsp, c.motive_name(), c.kind.replace("_", " ")])
	UiKit.label(box, c.summary(), UiKit.SMALL)
	if def.role != "":
		UiKit.label(box, def.role, UiKit.SMALL).modulate = Color(0.8, 0.85, 0.75)
	_asset_tips.append(UiKit.label(box, AssetCard.TIP, UiKit.SMALL))
	var row := HBoxContainer.new()
	box.add_child(row)
	for side in 2:
		UiKit.button(row, "+ " + Names.side(side), _on_add.bind(side, def.id), Vector2(140, 56))


static func weapons_line(def: UnitDef) -> String:
	var counts := {}
	for m in def.weapon_mounts:
		var n: String = m["weapon"].name
		counts[n] = counts.get(n, 0) + 1
	var parts: Array[String] = []
	for n: String in counts:
		parts.append(("%d× %s" % [counts[n], n]) if counts[n] > 1 else n)
	return ", ".join(parts) + "  ·  %d %sheat sinks" % [def.heat_sinks, "double " if def.double_heat_sinks else ""]
