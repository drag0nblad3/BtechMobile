class_name ModsText
extends RefCounted
## Formats ToHit modifiers: one summary line (LIGHT) or one line per
## modifier with its reason (FULL). With `seen`, each reason is given once.


static func lines(mods: Array, level: int, seen: Dictionary = {}) -> String:
	if level == ExplainLevel.OFF or mods.is_empty():
		return ""
	if level == ExplainLevel.LIGHT:
		var th := ToHit.new()
		th.mods.assign(mods)
		return "\n  " + th.summary()
	var out := ""
	for m: Dictionary in mods:
		var v := int(m["value"])
		var sign := "" if out == "" else ("+" if v >= 0 else "")
		out += "\n  %s%d %s" % [sign, v, m["label"]]
		var key := "mod:" + _strip_digits(m["label"])
		if m.get("why", "") != "" and not seen.has(key):
			out += ": " + m["why"]
			seen[key] = true
	return out


static func _strip_digits(t: String) -> String:
	var out := ""
	for ch in t:
		if not ch.is_valid_int():
			out += ch
	return out
