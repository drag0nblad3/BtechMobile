class_name NameplateLayout
extends RefCounted
## Stable, bounded screen-space placement; no simulation or camera changes.

const GAP := 5.0
const RADIUS := 3
const SETTLE_SPEED := 9.0


## Entries arrive in priority order, each with an id and its preferred rect.
## Keep the first plate close to its anchor; choose the nearest clear position
## for each subsequent plate, falling back to least overlap on crowded screens.
static func solve(entries: Array[Dictionary], bounds: Rect2, previous: Dictionary = {}) -> Dictionary:
	var placed: Array[Rect2] = []
	var result := {}
	for entry: Dictionary in entries:
		var id: int = entry["id"]
		var preferred: Rect2 = entry["rect"]
		var base := fit(preferred, bounds)
		var best := base
		var score := _cost(base, preferred, placed)
		if _overlap(base, placed) > 0.0:
			var step := Vector2(maxf(24.0, preferred.size.x * 0.5), preferred.size.y + GAP)
			# A previous displacement is a candidate, not a permanent position.
			if previous.has(id):
				var prior := fit(Rect2(preferred.position + Vector2(previous[id]), preferred.size), bounds)
				var prior_cost := _cost(prior, preferred, placed)
				if prior_cost < score:
					best = prior
					score = prior_cost
			for y in range(-RADIUS, RADIUS + 1):
				for x in range(-RADIUS, RADIUS + 1):
					if x == 0 and y == 0:
						continue
					var candidate := fit(Rect2(preferred.position + Vector2(x, y) * step, preferred.size), bounds)
					var cost := _cost(candidate, preferred, placed)
					if cost < score:
						best = candidate
						score = cost
		result[id] = best.position - preferred.position
		placed.append(best)
	return result


static func fit(rect: Rect2, bounds: Rect2) -> Rect2:
	var end := bounds.end - rect.size
	return Rect2(Vector2(clampf(rect.position.x, bounds.position.x, maxf(bounds.position.x, end.x)),
		clampf(rect.position.y, bounds.position.y, maxf(bounds.position.y, end.y))), rect.size)


static func _overlap(rect: Rect2, placed: Array[Rect2]) -> float:
	var area := 0.0
	for other: Rect2 in placed:
		var intersection := rect.intersection(other.grow(GAP))
		area += intersection.size.x * intersection.size.y
	return area


static func _cost(rect: Rect2, preferred: Rect2, placed: Array[Rect2]) -> float:
	# Prioritize clearing overlaps, then small moves. A slight horizontal
	# penalty keeps nameplates above their own units when possible.
	var shift := rect.position - preferred.position
	var distance := Vector2(shift.x * 1.12, shift.y).length_squared()
	return distance + _overlap(rect, placed) * 1000.0


static func ease(current: Vector2, target: Vector2, delta: float) -> Vector2:
	if current.distance_squared_to(target) < 0.16:
		return target
	return current.lerp(target, 1.0 - exp(-SETTLE_SPEED * maxf(delta, 0.0)))
