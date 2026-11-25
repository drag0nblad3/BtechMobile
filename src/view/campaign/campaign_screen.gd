class_name CampaignScreen
extends Control
## The company between battles: its Warchest, the contracts on offer, the
## last after-action report, and its 'Mechs and MechWarriors.

const INTRO := "Lead a small mercenary company from contract to contract using the Chaos Campaign rules from Campaign Operations. Damage and wounds carry over, and a 'Mech that loses its center torso is gone for good. Contracts cost Warchest Points (WP) to take and pay WP for each objective you meet."
const WP_TIP := "Warchest Points stand for money, contacts and reputation. A contract costs three-quarters of everything it could pay, so meeting only one objective rarely covers it. Options make the fight harder but pay extra if you meet any objective."

var db: UnitDb
var company: Campaign
var chaos := ChaosRules.load_file()
var _list: VBoxContainer
var _footer: HBoxContainer
var _selected_contract := 0
var _expanded_contract := -1
var _confirm_retire := false
var _note := ""  ## Why the last Support Points action didn't happen.


func _ready() -> void:
	company = CampaignStore.load_company()
	if company != null and db == null:
		db = UnitDb.load_dir()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
	_list = UiKit.screen_body(self, "CAMPAIGN", UiKit.close_overlay.bind(self))
	_footer = UiKit.screen_footer(_list)
	_build()


func _build() -> void:
	UiKit.clear(_footer)
	_footer.visible = company != null
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var head := HBoxContainer.new()
	_list.add_child(head)
	var title := UiKit.label(head, company.name if company != null else "Campaign", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiSkin.label(title, "heading")
	UiSkin.rule(_list)
	if company == null:
		UiKit.label(_list, INTRO, UiKit.SMALL)
		UiKit.button(_list, "START A COMPANY", _start_company, Vector2(0, 70), "primary").name = "StartCompany"
		return
	var dashboard := HBoxContainer.new()
	_list.add_child(dashboard)
	var company_card := UiKit.panel(dashboard)
	company_card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var wp := UiKit.label(company_card, "Warchest %d WP%s  ·  %d SP  ·  Month %d" % [
		company.wp, " (debt)" if company.wp < 0 else "", company.sp, company.month], 26)
	wp.name = "WarchestLabel"
	UiKit.label(company_card, "%d/%d ready · %d battles fought" % [
		company.ready_mechs().size(), company.mechs.size(), company.battles], 18)
	var formation_card := VBoxContainer.new()
	formation_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard.add_child(formation_card)
	AbilityPanel.formation(formation_card, company, db, _act, true)
	_contracts()
	if not company.last_report.is_empty():
		var report := UiKit.panel(_list)
		UiKit.label(report, "Last battle", 26)
		UiKit.label(report, "\n".join(company.last_report), UiKit.SMALL)
	SupportPanel.header(_list, company, chaos, _act, _note)
	UiSkin.rule(_list)
	MarketPanel.market(_list, company, db, chaos, _act)
	UiSkin.rule(_list)
	UiKit.label(_list, "Roster", 26).modulate = Color(0.75, 0.85, 1.0)
	for m in company.mechs:
		_mech_row(m)
	var retire := UiKit.button(_list, "TAP AGAIN TO RETIRE THE COMPANY" if _confirm_retire else "Retire company",
			_retire, Vector2(0, 52), "subtle")
	retire.name = "RetireButton"


func _mech_row(m: CampaignMech) -> void:
	var def := db.get_def(m.design)
	var p := company.pilot(m.pilot_id)
	var who := "no MechWarrior"
	if p != null:
		who = "%s%s (Gunnery %d, Piloting %d) · %d battle%s · %d kill%s" % [
			p.name, " (killed)" if p.dead else "", p.gunnery, p.piloting, p.battles,
			"" if p.battles == 1 else "s", p.kills, "" if p.kills == 1 else "s"]
		if p.wounds > 0 and not p.dead:
			who += " · %d wound%s" % [p.wounds, "" if p.wounds == 1 else "s"]
	var name_label := UiKit.label(_list, (("%s %s" % [def.name, def.model]) if def != null else m.design) + ("  (salvage)" if m.salvage else ""), UiKit.FONT)
	name_label.modulate = Color(1.0, 0.9, 0.6)
	UiKit.label(_list, who, UiKit.SMALL)
	UiKit.label(_list, ConditionText.summary(m, db), UiKit.SMALL)
	var tip := ConditionText.weakest(m, db)
	if tip != "" and GameSettings.explain_level != ExplainLevel.OFF:
		UiSkin.label(UiKit.label(_list, tip, UiKit.SMALL), "muted")
	if def != null:
		var row := SupportPanel.mech_actions(_list, company, m, def, chaos, _act)
		MarketPanel.sell_button(row, company, m, db, chaos, _act)
		AbilityPanel.pilot(_list, row, company, p, def, chaos, _act)


## Runs a SupportShop action, keeps why it failed, saves and redraws.
func _act(action: Callable) -> void:
	_note = String(action.call())
	CampaignStore.save(company)
	_build()


func _contracts() -> void:
	UiKit.label(_list, "Contracts", 26).modulate = Color(0.75, 0.85, 1.0)
	if company.offers.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		company.offers = ContractBoard.offer(chaos, rng)
		CampaignStore.save(company)
	_selected_contract = clampi(_selected_contract, 0, maxi(0, company.offers.size() - 1))
	for i in company.offers.size():
		ContractCard.add(_list, company, company.offers[i], chaos, i, _toggle_option,
			_select_contract, i == _selected_contract, i == _expanded_contract)
	_build_next_action()
	UiSkin.rule(_list)


func _select_contract(index: int) -> void:
	_expanded_contract = -1 if _expanded_contract == index else index
	_selected_contract = index
	_build()


func _build_next_action() -> void:
	if company.offers.is_empty():
		return
	var k := company.offers[_selected_contract]
	var why := Warchest.cant_take(company, k, chaos)
	var info := StandardMissions.info(k.mission_id)
	var note := "%s · %d WP" % [info.get("name", k.mission_id), k.cost(chaos)]
	if why != "":
		note = why
	elif company.wp < k.cost(chaos):
		note += " · Warchest debt"
	var status := UiKit.label(_footer, note, 18)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var take := UiKit.button(_footer, "TAKE CONTRACT", _take.bind(_selected_contract),
		Vector2(240, 58), "primary")
	take.name = "TakeContract%d" % _selected_contract
	take.disabled = why != ""
	take.tooltip_text = WP_TIP if why == "" else why


func _toggle_option(index: int, id: String) -> void:
	var k := company.offers[index]
	if k.chosen.has(id):
		k.chosen.erase(id)
	else:
		k.chosen.append(id)
	CampaignStore.save(company)
	_build()


func _start_company() -> void:
	if db == null:
		db = UnitDb.load_dir()
	_selected_contract = 0
	_expanded_contract = -1
	company = Campaign.create(CampaignRules.load_file(), chaos)
	CampaignStore.save(company)
	_build()


func _retire() -> void:
	if not _confirm_retire:
		_confirm_retire = true
		_build()
		return
	CampaignStore.delete()
	company = null
	_confirm_retire = false
	_build()


func _take(index: int) -> void:
	var k := company.offers[index]
	if Warchest.cant_take(company, k, chaos) != "":
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	Warchest.take(company, k, chaos)
	var state := CampaignLaunch.build(company, db, rng, k, chaos)
	if state == null:
		company = CampaignStore.load_company()
		return
	BattleLaunch.pending = state
	BattleLaunch.bot_sides = [1]
	BattleLaunch.campaign = true
	get_tree().change_scene_to_file(BattleLaunch.BATTLE_SCENE)
