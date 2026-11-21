class_name Conditions
extends RefCounted
## Battlefield conditions covering the whole map (book pp. 120-121): extreme
## cold or heat (levels 1-3), gravity (in G, rounded to 0.1), low visibility,
## wind, rain, snowfall and night. Read from a scenario's "conditions" block,
## e.g. {"cold": 2, "gravity": 0.8, "wind": true}. Clear by default.

const MAX_TEMP := 3
const MIN_GRAVITY := 0.1

var cold: int = 0
var heat: int = 0
var gravity: float = 1.0
var low_visibility := false
var wind := false
var rain := false
var snowfall := false
var night := false


static func from_dict(d: Dictionary) -> Conditions:
	var c := Conditions.new()
	c.cold = clampi(int(d.get("cold", 0)), 0, MAX_TEMP)
	c.heat = clampi(int(d.get("heat", 0)), 0, MAX_TEMP)
	c.gravity = round_gravity(float(d.get("gravity", 1.0)))
	for k in ["low_visibility", "wind", "rain", "snowfall", "night"]:
		c.set(k, bool(d.get(k, false)))
	return c


func to_dict() -> Dictionary:
	var d := {}
	if cold > 0:
		d["cold"] = cold
	if heat > 0:
		d["heat"] = heat
	if odd_gravity():
		d["gravity"] = gravity
	for k in ["low_visibility", "wind", "rain", "snowfall", "night"]:
		if get(k):
			d[k] = true
	return d


## Gravity to the nearest 0.1 G (0.95-1.04 counts as Terran), at least 0.1.
static func round_gravity(g: float) -> float:
	return maxf(MIN_GRAVITY, roundi(g * 10.0) / 10.0)


## Gravity in tenths of a G, for exact integer math.
func gravity_tenths() -> int:
	return roundi(gravity * 10.0)


func odd_gravity() -> bool:
	return gravity_tenths() != 10


func is_clear() -> bool:
	return to_dict().is_empty()


## Combinations the book rules out; empty when the set is legal.
func problems() -> Array[String]:
	var out: Array[String] = []
	if cold > 0 and heat > 0:
		out.append("extreme cold and extreme heat can't both apply")
	if rain and (cold > 0 or heat > 0):
		out.append("rain can't be used with extreme temperatures")
	if snowfall and heat > 0:
		out.append("snowfall can't be used with extreme heat")
	if rain and snowfall:
		out.append("rain and snowfall can't both apply")
	return out


## Short names, e.g. ["Extreme Cold 2", "Gravity 0.8 G"].
func names() -> Array[String]:
	var out: Array[String] = []
	if cold > 0:
		out.append("Extreme Cold %d" % cold)
	if heat > 0:
		out.append("Extreme Heat %d" % heat)
	if odd_gravity():
		out.append("Gravity %.1f G" % gravity)
	var flags := {"low_visibility": "Low Visibility", "wind": "Wind", "rain": "Rain",
			"snowfall": "Snowfall", "night": "Night"}
	for k: String in flags:
		if get(k):
			out.append(flags[k])
	return out
