class_name MapCampaignCodec
extends RefCounted
## A map campaign to and from JSON-ready dictionaries (saved by the view).


static func pack(mc: MapCampaign) -> Dictionary:
	var meets := []
	for b in mc.battles:
		var d := b.duplicate()
		d["zone"] = [b["zone"].x, b["zone"].y]
		meets.append(d)
	return {"version": 1, "turn": mc.turn, "winner": mc.winner, "region": mc.region.to_dict(),
		"player": mc.player.to_dict(), "enemy": mc.enemy.to_dict(),
		"lances": mc.lances.map(func(l: MapLance) -> Dictionary: return l.to_dict()),
		"battles": meets, "log": Array(mc.log)}


static func unpack(d: Dictionary, rules: Dictionary = {}) -> MapCampaign:
	var mc := MapCampaign.new()
	mc.rules = rules if not rules.is_empty() else MapCampaign.load_rules()
	mc.turn = int(d.get("turn", 1))
	mc.winner = int(d.get("winner", -1))
	mc.region = MapRegion.from_dict(d.get("region", {}))
	mc.player = Campaign.from_dict(d.get("player", {}))
	mc.enemy = Campaign.from_dict(d.get("enemy", {}))
	for l: Dictionary in d.get("lances", []):
		mc.lances.append(MapLance.from_dict(l))
	for b: Dictionary in d.get("battles", []):
		var m := b.duplicate()
		m["zone"] = Vector2i(int(b["zone"][0]), int(b["zone"][1]))
		mc.battles.append(m)
	for line in d.get("log", []):
		mc.log.append(String(line))
	return mc
