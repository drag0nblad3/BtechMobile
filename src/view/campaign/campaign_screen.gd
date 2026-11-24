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
var _confirm_retire := false
var _note := ""  ## Why the last Support Points action didn't happen.


func _ready() -> void:
	if db == null:
		db = UnitDb.load_dir()
	company = CampaignStore.load_company()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_list = UiKit.panel(scroll)
	_list.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build()


func _build() -> void:
	UiKit.clear(_list)
	var head := HBoxContainer.new()
	_list.add_child(head)
	var title := UiKit.label(head, company.name if company != null else "Campaign", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiSkin.label(title, "heading")
	UiKit.button(head, "Back", queue_free, Vector2(140, 60))
	UiSkin.rule(_list)
	if company == null:
		UiKit.label(_list, INTRO, UiKit.SMALL)
		UiKit.button(_list, "START A COMPANY", _start_company, Vector2(0, 70), "primary").name = "StartCompany"
		return
	var wp := UiKit.label(_list, "Warchest: %d WP%s  ·  battles fought: %d" % [company.wp,
			"  (in debt)" if company.wp < 0 else "", company.battles], UiKit.FONT)
	wp.name = "WarchestLabel"
	if not company.last_report.is_empty():
		UiKit.label(_list, "Last battle", 26).modulate = Color(0.75, 0.85, 1.0)
		UiKit.label(_list, "\n".join(company.last_report), UiKit.SMALL)
	_contracts()
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
		MarketPanel.sell_button(SupportPanel.mech_actions(_list, company, m, def, chaos, _act), company, m, db, chaos, _act)


## Runs a SupportShop action, keeps why it failed, saves and redraws.
func _act(action: Callable) -> void:
	_note = String(action.call())
	CampaignStore.save(company)
	_build()


func _contracts() -> void:
	UiKit.label(_list, "Contracts", 26).modulate = Color(0.75, 0.85, 1.0)
	if GameSettings.explain_level != ExplainLevel.OFF:
		UiSkin.label(UiKit.label(_list, WP_TIP, UiKit.SMALL), "muted")
	if company.offers.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		company.offers = ContractBoard.offer(chaos, rng)
		CampaignStore.save(company)
	for i in company.offers.size():
		UiSkin.rule(_list)
		ContractCard.add(_list, company, company.offers[i], chaos, i, _toggle_option, _take)
	UiSkin.rule(_list)


func _toggle_option(index: int, id: String) -> void:
	var k := company.offers[index]
	if k.chosen.has(id):
		k.chosen.erase(id)
	else:
		k.chosen.append(id)
	CampaignStore.save(company)
	_build()


func _start_company() -> void:
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
