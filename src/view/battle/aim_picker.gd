class_name AimPicker
extends RefCounted
## Aimed shots in the weapon panel: against an immobile target, a button
## cycles the location to aim at (none, head, torsos, arms, legs). The
## chosen aim applies to every weapon fired at that target that may aim.

const ORDER := [-1, Location.HEAD, Location.CT, Location.LT, Location.RT,
		Location.LA, Location.RA, Location.LL, Location.RL]


static func available(attacker: Unit, target: Unit) -> bool:
	return target != null and (ToHitCalc.is_immobile(target) or TargetingComputer.working(attacker))


## The next location in ORDER that's still there.
static func next(target: Unit, aim: int) -> int:
	var i := ORDER.find(aim)
	for step in range(1, ORDER.size() + 1):
		var loc: int = ORDER[(i + step) % ORDER.size()]
		if loc < 0 or not target.is_location_destroyed(loc):
			return loc
	return -1


## Applies the aim to fire options (their ToHit) where the weapon may aim.
static func apply(state: GameState, target: Unit, options: Array, aim: int) -> void:
	if aim < 0:
		return
	for o: Dictionary in options:
		var th: ToHit = o["to_hit"]
		if th.possible() and AimedShot.problem(state, o["weapon"], target, aim, th) == "":
			AimedShot.adjust(th, aim, o["weapon"])


## Adds "aim" to shots at an aimed target.
static func tag(shot_list: Array, aims: Dictionary) -> Array:
	for sh: Dictionary in shot_list:
		if sh.has("target_id") and aims.get(sh["target_id"], -1) >= 0:
			sh["aim"] = aims[sh["target_id"]]
	return shot_list


## The panel with an aim button on top.
static func wrap(panel: Control, target: Unit, aim: int, on_press: Callable) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var b := Button.new()
	b.text = "Aim at: %s (tap to change)" % ("no location" if aim < 0 else Location.name_of(aim).to_lower())
	b.tooltip_text = "%s: aim at one location: 4+ on 1D6 after a hit puts it there. Head shots lose the -4 and get +3." % Names.unit(target)
	b.custom_minimum_size = Vector2(0, 54)
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(on_press)
	box.add_child(b)
	box.add_child(panel)
	return box
