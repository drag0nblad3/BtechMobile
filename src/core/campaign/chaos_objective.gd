class_name ChaosObjective
extends RefCounted
## Checks a Chaos Campaign objective (Campaign Operations pp. 166-168) at the
## end of a battle. "Down" is destroyed, crippled or withdrawn; a loss is a
## 'Mech destroyed on the field (one that left the map isn't lost).
## TODO(rules): the book doesn't define "losses"; we count destroyed units.


static func met(obj: Dictionary, state: GameState, side: int) -> bool:
	var t := tally(state, side)
	var share := float(obj.get("share", 0.0))
	match String(obj.get("check", "")):
		"enemy_down":
			return _at_least(t["enemy_down"], t["enemy"], share)
		"own_operational":
			return _at_least(t["own"] - t["own_lost"] - t["own_crippled"], t["own"], share)
		"own_survives":
			return _at_least(t["own"] - t["own_lost"], t["own"], share)
		"own_losses_below":
			return t["own_lost"] < t["own"] * share
		"own_losses_at_most":
			return t["own_lost"] <= t["own"] * share + 0.0001
		"no_pilot_deaths":
			return t["pilots_lost"] == 0
		"trade":
			var own := float(obj.get("own", 0.5))
			var ok_own: bool = t["own_lost"] <= t["own"] * own + 0.0001 if obj.get("own_at_most", false) \
					else t["own_lost"] < t["own"] * own
			return _at_least(t["enemy_down"], t["enemy"], float(obj.get("enemy", 0.5))) and ok_own
	return false


## Counts of 'Mechs for `side` and its enemies at the end of a battle.
static func tally(state: GameState, side: int) -> Dictionary:
	var t := {"own": 0, "own_lost": 0, "own_crippled": 0, "pilots_lost": 0, "enemy": 0, "enemy_down": 0}
	for u in state.all_units():
		if u.is_asset():
			continue
		var left := state.mission.exited.has(u.id) or u.destroyed_reason in CampaignBattle.LEFT_MAP
		var lost := u.destroyed and not left
		var crippled := state.mission.is_crippled(u)
		if u.side == side:
			t["own"] += 1
			t["own_lost"] += 1 if lost else 0
			t["own_crippled"] += 1 if crippled and not lost else 0
			t["pilots_lost"] += 1 if CampaignBattle.pilot_killed(u) else 0
		else:
			t["enemy"] += 1
			var withdrew := String(state.mission.exited.get(u.id, "")) == "withdraw"
			var escaped := String(state.mission.exited.get(u.id, "")) == "mission"
			t["enemy_down"] += 1 if (u.destroyed or crippled or withdrew) and not escaped else 0
	return t


static func _at_least(n: int, total: int, share: float) -> bool:
	return total > 0 and float(n) >= float(total) * share - 0.0001
