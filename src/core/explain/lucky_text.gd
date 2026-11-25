class_name LuckyText
extends RefCounted
## " (Lucky reroll of 4)" after a roll the Lucky SPA replaced, else "".


static func note(d: Dictionary) -> String:
	return " (Lucky reroll of %d)" % int(d["lucky_first"]) if d.has("lucky_first") else ""
