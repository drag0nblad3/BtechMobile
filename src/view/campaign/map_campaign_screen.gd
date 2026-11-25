class_name MapCampaignScreen
extends Control
## The map campaign between battles: the region, your three lances and
## their orders, this turn's battles, and what happened. Saved by
## MapCampaignStore; separate from the Chaos Campaign company.

const INTRO := "Take a planetary region with a company of three lances, using the map campaign rules from Campaign Operations. Each turn is a day: give every lance an order, then fight the battles where lances meet. Damage carries over, cities and forts repair you, and holding 80% of the region's points wins."
const ORDER_TIP := {
	MapLance.ATTACK: "Seek a battle, here or one zone over.",
	MapLance.SCOUT: "Find the enemy without a full fight, and see 2 zones around you.",
	MapLance.DEFEND: "Hold here: +1 Initiative if attacked.",
	MapLance.MOVE: "Move one zone.",
	MapLance.FAST_MOVE: "Move two zones; no Move order next turn.",
	MapLance.REPAIR: "Stay and fix every 'Mech; Green recruits fill empty seats.",
	MapLance.DROPSHIP: "Fly anywhere: 2 days, or 1 to or from a DropPort you hold."}

var db: UnitDb
var mc: MapCampaign
var rng := RandomNumberGenerator.new()
var _list: VBoxContainer
var _chosen := ""  ## Selected lance id.
var _order := ""  ## Order waiting for a zone tap.
var _note := ""
var _confirm_quit := false
var _grid: MapZoneGrid
var _inspected := Vector2i(-1, -1)
var _layer := 0
var _panel := 0
var _setup_options := {"size": 0, "skill": 1, "company": 2, "goal": 1, "historical": false, "year": 3025, "player_faction": "mercenary", "enemy_faction": "draconis_combine"}
var _swap_mech := ""
var _swap_lance := ""
var _swap_pilots := false
var _moves: Array[Dictionary] = []
var _captures: Array[Vector2i] = []


func _ready() -> void:
	rng.randomize()
	if db == null:
		db = UnitDb.load_dir()
	mc = MapCampaignStore.load_campaign()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
	_list = UiKit.screen_body(self, "MAP CAMPAIGN", UiKit.close_overlay.bind(self))
	_build()


func _build() -> void:
	var zoom := _grid.zoom if is_instance_valid(_grid) else 1.0
	var pan := _grid.pan if is_instance_valid(_grid) else Vector2.ZERO
	_grid = null
	for ch in _list.get_children():  # out of the tree now, so new buttons keep their names
		_list.remove_child(ch)
		ch.queue_free()
	if mc == null:
		UiKit.label(_list, INTRO, UiKit.SMALL)
		MapCampaignPanels.setup(_list, _setup_options)
		if _note != "":
			UiKit.label(_list, _note, 18)
		UiKit.button(_list, "START A CAMPAIGN", _start, Vector2(0, 70), "primary").name = "StartMapCampaign"
		return
	var need := ceili(mc.region.total_points() * float(mc.rules.get("victory_share", 0.8)))
	var status := UiKit.label(_list, "OPERATION %d  ·  DAY %d/%d  ·  CONTROL %d/%d (%d total)" % [
			mc.operation, mc.turn, int(mc.rules.get("turn_limit", 20)), mc.region.points(0), need,
			mc.region.total_points()], UiKit.FONT)
	status.name = "MapStatus"
	var progress := ProgressBar.new()
	progress.name = "CaptureProgress"
	progress.custom_minimum_size.y = 14
	progress.max_value = maxi(1, need)
	progress.value = mc.region.points(0)
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", UiSkin.panel_style(UiSkin.SURFACE_HIGH, UiSkin.BORDER, 0, 5))
	progress.add_theme_stylebox_override("fill", UiSkin.panel_style(UiSkin.CYAN.darkened(0.25), UiSkin.CYAN, 0, 5))
	_list.add_child(progress)
	if mc.winner >= 0:
		UiKit.label(_list, "You took the region!" if mc.winner == 0 else "The campaign is lost.", 28)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_list.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 2.1
	row.add_child(left)
	var tools := HBoxContainer.new()
	left.add_child(tools)
	var layers := OptionButton.new()
	for label in ["Terrain", "Ownership", "Intelligence", "Logistics", "Readiness"]:
		layers.add_item(label)
	layers.select(_layer)
	layers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layers.item_selected.connect(func(i: int): _layer = i; _grid.overlay = i; _grid.queue_redraw())
	tools.add_child(layers)
	UiKit.button(tools, "−", func(): _grid.set_zoom(_grid.zoom - 0.25), Vector2(52, 44))
	UiKit.button(tools, "+", func(): _grid.set_zoom(_grid.zoom + 0.25), Vector2(52, 44))
	UiKit.button(tools, "FIT", func(): _grid.set_zoom(1.0), Vector2(65, 44))
	_grid = MapZoneGrid.make(left, mc, _tap_zone, mc.lance(_chosen), _order, _layer, _inspected)
	_grid.zoom = zoom
	_grid.pan = pan
	if not _moves.is_empty() or not _captures.is_empty():
		_grid.animate_changes(_moves, _captures)
		_moves = []
		_captures = []
	UiKit.label(left, "Blue: company  ·  Red: observed enemy  ·  Gold: selected / route  ·  Cyan: legal destination", 15)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 330
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var tabs := HBoxContainer.new()
	right.add_child(tabs)
	for i in 3:
		var idx := i
		var tab := UiKit.button(tabs, ["Orders", "HQ", "History"][i], func(): _panel = idx; _build(), Vector2(0, 44), "selected" if i == _panel else "subtle")
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 17)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 370
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(details)
	if _note != "":
		UiKit.label(details, _note, 17).modulate = Color(1.0, 0.85, 0.6)
	if _panel == 0:
		if not mc.battles.is_empty():
			MapLancePanel.battles(details, mc, _fight)
		MapLancePanel.lances(details, mc, _chosen, _select, _pick_order, mc.battles.is_empty() and mc.winner < 0)
		MapCampaignPanels.inspect(details, mc, _inspected, db)
	elif _panel == 1:
		MapCampaignPanels.company(details, mc, db, _hq_action, _swap_mech)
	else:
		MapCampaignPanels.history(details, mc)
	if mc.battles.is_empty() and mc.winner < 0:
		UiKit.button(right, "END DAY", _end_turn, Vector2(0, 56), "primary").name = "EndTurn"
	elif mc.winner == 0:
		UiKit.button(right, "NEXT OPERATION", _next_region, Vector2(0, 54), "primary")
	var quit := UiKit.button(right, "CONFIRM ABANDON" if _confirm_quit else "Abandon", _quit, Vector2(0, 40), "subtle")
	quit.name = "AbandonMapCampaign"


func _next_region() -> void:
	if MapOperations.next_region(mc, db, rng):
		_chosen = ""
		_order = ""
		_inspected = Vector2i(-1, -1)
		_note = "Company deployed to a new region. Damage and service records retained."
		MapCampaignStore.save(mc)
		_build()


func _hq_action(l: MapLance, id: String, pilots: bool) -> void:
	if _swap_mech == "" or _swap_pilots != pilots:
		_swap_pilots = pilots
		_swap_mech = id
		_swap_lance = l.id
		_note = "Select another co-located unit to exchange " + ("pilots." if pilots else "lance assignments.")
	else:
		var other := mc.lance(_swap_lance)
		var ok := false
		if other != null:
			ok = MapOperations.swap_pilots(mc, mc.player.mech(_swap_mech), mc.player.mech(id)) if pilots else MapOperations.swap_mechs(mc, other, _swap_mech, l, id)
		_note = "Assignment updated." if ok else "Exchange unavailable: units must be co-located, eligible and not in battle."
		_swap_mech = ""
		_swap_lance = ""
		if ok:
			MapCampaignStore.save(mc)
	_build()


func _start() -> void:
	var rules := MapCampaign.load_rules()
	var scale := int(_setup_options["size"])
	rules["width"] = [8, 10, 12][scale]
	rules["height"] = [6, 8, 9][scale]
	rules["enemy_skill"] = ["green", "regular", "veteran", "elite"][int(_setup_options["skill"])]
	rules["starting_company"] = rules["starting_company"].slice(0, 4 * (int(_setup_options["company"]) + 1))
	rules["victory_share"] = [0.6, 0.8, 1.0][int(_setup_options["goal"])]
	rules["historical"] = bool(_setup_options["historical"])
	rules["era_year"] = int(_setup_options["year"])
	rules["factions"] = [_setup_options["player_faction"], _setup_options["enemy_faction"]]
	if not MapOperations.historic_roster(db, rules, rng):
		_note = "No verified catalog designs for one of these factions and years. Choose another combination or disable strict history."
		_build()
		return
	mc = MapCampaign.create(db, rng, rules)
	MapCampaignStore.save(mc)
	_note = "Your company has landed on the south edge. Pick a lance, then an order."
	_build()


func _select(id: String) -> void:
	_chosen = id
	_inspected = mc.lance(id).zone
	_order = ""
	_note = ""
	_build()


func _pick_order(order: String) -> void:
	var l := mc.lance(_chosen)
	if l == null:
		return
	if order in [MapLance.DEFEND, MapLance.REPAIR]:
		_note = MapOrders.give(mc, l, order)
		_order = ""
		MapCampaignStore.save(mc)
	else:
		_order = order
		_note = "%s: tap the zone to go to. %s" % [MapLance.NAMES[order], ORDER_TIP[order]]
	_build()


func _tap_zone(z: Vector2i) -> void:
	_inspected = z
	_panel = 0
	var l := mc.lance(_chosen)
	if l != null and _order != "":
		_note = MapOrders.give(mc, l, _order, z)
		if _note == "":
			_order = ""
			MapCampaignStore.save(mc)
	else:
		for other in mc.lances_of(0):
			if other.zone == z:
				_chosen = other.id
				_note = ""
				break
	_build()


func _end_turn() -> void:
	var before := {}
	var owners := {}
	var seen := MapFog.seen(mc)
	for l in mc.lances:
		if l.on_map() and MapFog.shows(mc, l, seen):
			before[l.id] = l.zone
	for loc in mc.region.locations:
		owners[loc["id"]] = loc["owner"]
	MapBot.orders(mc, 1)
	MapTurn.start(mc, Dice.new(rng.randi()))
	if mc.battles.is_empty():
		var news := MapTurn.finish(mc, db)
		_note = "A quiet day." if news.is_empty() else " ".join(news)
	else:
		_note = "%d battle%s to fight." % [mc.battles.size(), "" if mc.battles.size() == 1 else "s"]
	var now := MapFog.seen(mc)
	for l in mc.lances:
		if before.has(l.id) and l.on_map() and MapFog.shows(mc, l, now) and before[l.id] != l.zone:
			_moves.append({"from": before[l.id], "to": l.zone, "side": l.side})
	for loc in mc.region.locations:
		if owners.get(loc["id"]) != loc["owner"]:
			_captures.append(loc["zone"])
	_chosen = ""
	_order = ""
	MapCampaignStore.save(mc)
	_build()


func _fight(index: int) -> void:
	var r := MapBattle.build(mc, mc.battles[index], db, rng.randi())
	if r.is_empty():
		_note = "That battle can't be set up."
		_build()
		return
	MapCampaignStore.save(mc, {"index": index, "rosters": r["rosters"]})
	BattleLaunch.pending = r["state"]
	BattleLaunch.bot_sides = [1]
	BattleLaunch.map_campaign = true
	get_tree().change_scene_to_file(BattleLaunch.BATTLE_SCENE)


func _quit() -> void:
	if not _confirm_quit:
		_confirm_quit = true
	else:
		MapCampaignStore.delete()
		mc = null
		_chosen = ""
		_order = ""
		_inspected = Vector2i(-1, -1)
		_confirm_quit = false
	_build()
