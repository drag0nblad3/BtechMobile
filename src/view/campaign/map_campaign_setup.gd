class_name MapCampaignSetup
extends RefCounted
## GM-style region parameters, fixed for the duration of an operation chain.


static func build(parent: VBoxContainer, rules: Dictionary) -> void:
	_choice(parent, "Region size", ["Standard 8 × 6", "Large 10 × 8", "Extended 12 × 9"],
		[Vector2i(8, 6), Vector2i(10, 8), Vector2i(12, 9)],
		Vector2i(int(rules["width"]), int(rules["height"])),
		func(v: Vector2i): rules["width"] = v.x; rules["height"] = v.y)
	_choice(parent, "Defender skill", ["Green", "Regular", "Veteran"],
		["green", "regular", "veteran"], rules.get("enemy_skill", "regular"),
		func(v: String): rules["enemy_skill"] = v)
	_choice(parent, "Campaign victory target", ["60% of objectives", "80% of objectives", "All objectives"],
		[0.6, 0.8, 1.0], rules.get("victory_share", 0.8),
		func(v: float): rules["victory_share"] = v)
	_choice(parent, "Linked regions (optional)", ["One region", "Two regions", "Three regions"],
		[1, 2, 3], rules.get("operations", 1), func(v: int): rules["operations"] = v)
	_choice(parent, "Day limit", ["20 days", "30 days", "40 days"], [20, 30, 40],
		rules.get("turn_limit", 20), func(v: int): rules["turn_limit"] = v)


static func _choice(parent: VBoxContainer, caption: String, names: Array, values: Array,
		current: Variant, change: Callable) -> void:
	UiKit.label(parent, caption, 17)
	var select := OptionButton.new()
	select.custom_minimum_size.y = 52
	select.fit_to_longest_item = false
	for label: String in names:
		select.add_item(label)
	select.select(maxi(0, values.find(current)))
	select.item_selected.connect(func(i: int): change.call(values[i]))
	parent.add_child(select)
