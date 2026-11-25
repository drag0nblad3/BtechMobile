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
var _map_mode := 0
var _zoom := 1.0
var _inspected := Vector2i(-1, -1)
var _map_scroll: ScrollContainer


func _ready() -> void:
	rng.randomize()
	mc = MapCampaignStore.load_campaign()
	if mc != null and db == null:
		db = UnitDb.load_dir()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
	_list = UiKit.screen_body(self, "MAP CAMPAIGN", UiKit.close_overlay.bind(self))
	_build()


func _build() -> void:
	var scroll_at := Vector2i.ZERO
	if is_instance_valid(_map_scroll):
		scroll_at = Vector2i(_map_scroll.scroll_horizontal, _map_scroll.scroll_vertical)
	for ch in _list.get_children():  # out of the tree now, so new buttons keep their names
		_list.remove_child(ch)
		ch.queue_free()
	if mc == null:
		UiKit.label(_list, INTRO, UiKit.SMALL)
		UiKit.button(_list, "START A CAMPAIGN", _start, Vector2(0, 70), "primary").name = "StartMapCampaign"
		return
	var need := ceili(mc.region.total_points() * float(mc.rules.get("victory_share", 0.8)))
	var status := UiKit.label(_list, "Day %d of %d  ·  your points %d of %d needed (%d in all)" % [
			mc.turn, int(mc.rules.get("turn_limit", 20)), mc.region.points(0), need,
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
	if _note != "":
		UiKit.label(_list, _note, UiKit.SMALL).modulate = Color(1.0, 0.85, 0.6)
	var toolbar := HBoxContainer.new()
	_list.add_child(toolbar)
	for i in 4:
		var mode := i
		UiKit.button(toolbar, ["Terrain", "Objectives", "Intel", "Readiness"][i],
			func(): _map_mode = mode; _build(), Vector2(0, 42), "selected" if i == _map_mode else "subtle")
	UiKit.button(toolbar, "−", func(): _zoom = maxf(0.75, _zoom - 0.25); _build(), Vector2(50, 42))
	UiKit.button(toolbar, "+", func(): _zoom = minf(2.0, _zoom + 0.25); _build(), Vector2(50, 42))
	var body := HBoxContainer.new()
	body.custom_minimum_size.y = 410
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_child(body)
	_map_scroll = ScrollContainer.new()
	_map_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_scroll.size_flags_stretch_ratio = 1.5
	_map_scroll.custom_minimum_size.x = 420
	body.add_child(_map_scroll)
	MapZoneGrid.make(_map_scroll, mc, _tap_zone, mc.lance(_chosen), _order, _map_mode, _zoom, _inspected)
	_map_scroll.set_deferred("scroll_horizontal", scroll_at.x)
	_map_scroll.set_deferred("scroll_vertical", scroll_at.y)
	var controls := ScrollContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	controls.custom_minimum_size.x = 330
	body.add_child(controls)
	var command := VBoxContainer.new()
	command.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(command)
	if mc.region.has_zone(_inspected):
		UiKit.label(command, MapZoneGrid.text_of(mc, _inspected), 17)
	MapLancePanel.lances(command, mc, _chosen, _select, _pick_order, mc.battles.is_empty() and mc.winner < 0)
	if not mc.battles.is_empty():
		MapLancePanel.battles(command, mc, _fight)
	elif mc.winner < 0:
		UiKit.button(_list, "END DAY", _end_turn, Vector2(0, 58), "primary").name = "EndTurn"
	if not mc.log.is_empty():
		UiKit.label(_list, "Log", 26).modulate = Color(0.75, 0.85, 1.0)
		UiKit.label(_list, "\n".join(mc.log.slice(maxi(0, mc.log.size() - 8))), UiKit.SMALL)
	var quit := UiKit.button(_list, "TAP AGAIN TO ABANDON THE CAMPAIGN" if _confirm_quit else "Abandon campaign",
			_quit, Vector2(0, 52), "subtle")
	quit.name = "AbandonMapCampaign"


func _start() -> void:
	if db == null:
		db = UnitDb.load_dir()
	mc = MapCampaign.create(db, rng)
	MapCampaignStore.save(mc)
	_note = "Your company has landed on the south edge. Pick a lance, then an order."
	_build()


func _select(id: String) -> void:
	_chosen = id
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
	MapBot.orders(mc, 1)
	MapTurn.start(mc, Dice.new(rng.randi()))
	if mc.battles.is_empty():
		var news := MapTurn.finish(mc, db)
		_note = "A quiet day." if news.is_empty() else " ".join(news)
	else:
		_note = "%d battle%s to fight." % [mc.battles.size(), "" if mc.battles.size() == 1 else "s"]
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
		_confirm_quit = false
	_build()
