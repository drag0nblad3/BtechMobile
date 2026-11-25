class_name AbilityPanel
extends RefCounted
## Formation and Special Pilot Abilities on the campaign screen: the
## formation button above the contracts, and each MechWarrior's abilities
## with a "Learn an ability" list (SpaShop). `act` runs a call that returns
## "" or why not, then redraws, like SupportPanel.

const FORMATION_TIP := "A lance built to a Formation Type gets free special abilities in battle while 3 of its 'Mechs keep fighting. Which types fit depends on your ready 'Mechs' roles, weights and speeds."
const SPA_TIP := "Special abilities cost %d SP each. Green MechWarriors can't learn any; Regulars get one small one, Veterans and Elites two. One every %d months."

static var open := ""  ## Pilot id whose ability list is showing.


static func formation(list: VBoxContainer, c: Campaign, db: UnitDb, act: Callable, compact := false) -> void:
	var cur := CampaignFormation.current(c, db)
	var opts := CampaignFormation.options(c, db)
	var text := "FORMATION  •  %s" % (FormationTypes.name_of(cur) if cur != "" else "None")
	if opts.is_empty():
		text += "  (your ready 'Mechs don't fit one)"
	var b := UiKit.button(list, text, act.bind(CampaignFormation.cycle.bind(c, db)), Vector2(0, 52))
	b.name = "FormationButton"
	b.disabled = opts.is_empty()
	b.tooltip_text = FORMATION_TIP
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not compact and GameSettings.explain_level != ExplainLevel.OFF:
		UiSkin.label(UiKit.label(list, FORMATION_TIP, UiKit.SMALL), "muted")


static func pilot(list: VBoxContainer, row: Control, c: Campaign, p: CampaignPilot, def: UnitDef,
		rules: ChaosRules, act: Callable) -> void:
	if p == null or p.dead:
		return
	if not p.abilities.is_empty():
		var names := p.abilities.map(func(a: String) -> String: return _name(a))
		UiKit.label(list, "Abilities: " + ", ".join(names), UiKit.SMALL)
	var lim := SpaShop.limits(p, rules)
	if lim.x == 0 or p.abilities.size() >= lim.x:
		return
	SupportPanel.small_button(row, "Hide abilities" if open == p.id else "Learn an ability",
			act.bind(_toggle.bind(p.id))).name = "Learn_" + p.id
	if open != p.id:
		return
	if GameSettings.explain_level != ExplainLevel.OFF:
		UiSkin.label(UiKit.label(list, SPA_TIP % [rules.sp("spa"), int(rules.support().get("spa_months", 3))], UiKit.SMALL), "muted")
	var grid := SupportPanel.flow(list)
	for o: Dictionary in SpaShop.offers(p, def):
		if SpaShop.points(p) + int(o["cost"]) > lim.y:
			continue  # too big for this MechWarrior's rating
		var b := SupportPanel.small_button(grid, "%s (%d pt) · %d SP" % [o["name"], o["cost"], rules.sp("spa")],
				act.bind(SpaShop.learn.bind(c, p, o["entry"], rules)))
		b.tooltip_text = String(Spa.info(String(o["entry"]).get_slice(":", 0)).get("summary", ""))


static func _toggle(id: String) -> String:
	open = "" if open == id else id
	return ""


static func _name(entry: String) -> String:
	var n := Spa.name_of(entry.get_slice(":", 0))
	return n if not entry.contains(":") else "%s (%s)" % [n, entry.get_slice(":", 1).capitalize()]
