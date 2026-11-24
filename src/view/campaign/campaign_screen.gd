class_name CampaignScreen
extends Control
## The company between battles: its 'Mechs with their damage, its
## MechWarriors, the last after-action report, and the next battle.

const INTRO := "Lead a small mercenary company from battle to battle. Damage, wounds and experience carry over, and a 'Mech that loses its center torso is gone for good. These campaign rules are the app's own: the Core Rulebook leaves campaigns to other books, so the numbers will change when official rules are added."

var db: UnitDb
var company: Campaign
var _list: VBoxContainer
var _confirm_retire := false


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
	UiKit.label(_list, "Battles fought: %d" % company.battles, UiKit.SMALL)
	if not company.last_report.is_empty():
		UiKit.label(_list, "Last battle", 26).modulate = Color(0.75, 0.85, 1.0)
		UiKit.label(_list, "\n".join(company.last_report), UiKit.SMALL)
	UiKit.label(_list, "Roster", 26).modulate = Color(0.75, 0.85, 1.0)
	for m in company.mechs:
		_mech_row(m)
	var ready := company.ready_mechs().size()
	var fight := UiKit.button(_list, "FIGHT THE NEXT BATTLE" if ready > 0 else "NO 'MECH CAN FIGHT",
			_fight, Vector2(0, 70), "primary")
	fight.name = "FightButton"
	fight.disabled = ready == 0
	var retire := UiKit.button(_list, "TAP AGAIN TO RETIRE THE COMPANY" if _confirm_retire else "Retire company",
			_retire, Vector2(0, 52), "subtle")
	retire.name = "RetireButton"


func _mech_row(m: CampaignMech) -> void:
	var def := db.get_def(m.design)
	var p := company.pilot(m.pilot_id)
	var who := "no MechWarrior"
	if p != null:
		who = "%s%s (Gunnery %d, Piloting %d) · %d XP · %d kill%s" % [
			p.name, " (killed)" if p.dead else "", p.gunnery, p.piloting, p.xp, p.kills, "" if p.kills == 1 else "s"]
		if p.wounds > 0 and not p.dead:
			who += " · %d wound%s" % [p.wounds, "" if p.wounds == 1 else "s"]
	var name_label := UiKit.label(_list, ("%s %s" % [def.name, def.model]) if def != null else m.design, UiKit.FONT)
	name_label.modulate = Color(1.0, 0.9, 0.6)
	UiKit.label(_list, who, UiKit.SMALL)
	UiKit.label(_list, ConditionText.summary(m, db), UiKit.SMALL)
	var tip := ConditionText.weakest(m, db)
	if tip != "" and GameSettings.explain_level != ExplainLevel.OFF:
		UiSkin.label(UiKit.label(_list, tip, UiKit.SMALL), "muted")


func _start_company() -> void:
	company = Campaign.create(CampaignRules.load_file())
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


func _fight() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var state := CampaignLaunch.build(company, db, rng)
	if state == null:
		return
	BattleLaunch.pending = state
	BattleLaunch.bot_sides = [1]
	BattleLaunch.campaign = true
	get_tree().change_scene_to_file(BattleLaunch.BATTLE_SCENE)
