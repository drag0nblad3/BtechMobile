class_name ForceCatalogCard
extends RefCounted
## Compact, budget-aware catalog cards; all combat data comes from UnitDef.

static func build(parent: Control, def: UnitDef, variants: Array,
		on_add: Callable, on_variant: Callable) -> Dictionary:
	var box := UiKit.panel(parent)
	var name := UiKit.label(box, def.display_name(), 23)
	UiSkin.label(name, "body")
	var summary := UiKit.label(box, description(def), 18)
	UiSkin.label(summary, "muted")
	var weapons := UiKit.label(box, weapons_line(def), 17)
	weapons.max_lines_visible = 2
	UiSkin.label(weapons, "muted")
	var cost := UiKit.label(box, "", 18)
	UiSkin.label(cost, "section")
	var info := UiKit.label(box, "", 16)
	UiSkin.label(info, "muted")
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var add := UiKit.button(actions, "ADD", on_add, Vector2(0, 52), "primary")
	add.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if variants.size() > 1:
		var cycle := UiKit.button(actions, "CONFIG %d/%d" % [variants.find(def) + 1, variants.size()],
			on_variant, Vector2(140, 52), "subtle")
		cycle.add_theme_font_size_override("font_size", 16)
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
