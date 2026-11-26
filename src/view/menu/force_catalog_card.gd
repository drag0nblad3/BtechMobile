class_name ForceCatalogCard
extends RefCounted
## Compact, budget-aware catalog cards; all combat data comes from UnitDef.

static func build(parent: Control, def: UnitDef, variants: Array,
		on_add: Callable, on_variant: Callable, on_favorite: Callable = Callable()) -> Dictionary:
	var box := UiKit.panel(parent)
	box.add_theme_constant_override("separation", 2)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var name := UiKit.label(heading, def.display_name(), 21)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiSkin.label(name, "body")
	UnitFavorites.button(heading, def.id, on_favorite)
	var summary := UiKit.label(box, description(def) + "  •  " + weapons_line(def), 16)
	summary.autowrap_mode = TextServer.AUTOWRAP_OFF
	summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	summary.tooltip_text = weapons_line(def)
	UiSkin.label(summary, "muted")
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	actions.add_child(text)
	var cost := UiKit.label(text, "", 17)
	UiSkin.label(cost, "section")
	var info := UiKit.label(text, "", 15)
	UiSkin.label(info, "muted")
	if variants.size() > 1:
		var cycle := UiKit.button(actions, ("%sCONFIG %d/%d" % ["★ " if not UnitFavorites.first_favorite(variants).is_empty() and not UnitFavorites.has(def.id) else "", variants.find(def) + 1, variants.size()]),
			on_variant, Vector2(120, 48), "subtle")
		cycle.add_theme_font_size_override("font_size", 15)
	var add := UiKit.button(actions, "ADD", on_add, Vector2(150, 48), "primary")
	add.add_theme_font_size_override("font_size", 18)
	return {"def": def, "button": add, "cost": cost, "info": info}


static func description(def: UnitDef) -> String:
	if def.asset != null:
		return "SUPPORT  •  %d BSP  •  %s" % [def.asset.bsp, def.asset.motive_name()]
	if def.battle_armor != null:
		return "BATTLE ARMOR  •  %d troopers  •  %d/%d MP" % [
			def.battle_armor.troopers, def.battle_armor.ground_mp, def.battle_armor.jump_mp]
	if def.vehicle != null:
		return "VEHICLE  •  %d t  •  %s" % [def.tonnage, def.vehicle.motive_name()]
	return "%d t %s  •  %d/%d MP  •  %d armor%s" % [
		def.tonnage, def.weight_class(), def.walk_mp, def.run_mp(),
		def.total_armor(), "  •  CLAN" if def.is_clan() else ""]


static func weapons_line(def: UnitDef) -> String:
	if def.asset != null:
		return def.asset.summary()
	if def.battle_armor != null:
		var names: Array[String] = []
		for weapon: Dictionary in def.battle_armor.weapons:
			names.append(String(weapon.get("name", "")))
		return ", ".join(names)
	var counts := {}
	for mount: Dictionary in def.weapon_mounts:
		var name: String = (mount["weapon"] as WeaponDef).name
		counts[name] = counts.get(name, 0) + 1
	var names: Array[String] = []
	for name: String in counts:
		names.append(("%d× " % counts[name] if counts[name] > 1 else "") + name)
	return ", ".join(names)
