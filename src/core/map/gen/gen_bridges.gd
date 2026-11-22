class_name GenBridges
extends RefCounted
## Turns each patch of water that roads cross into one bridge. The deck sits
## level with the highest road bank, but never more than 2 levels above the
## lowest one (so both ends can be walked onto) and never below the water.


static func apply(g: GenGrid, t: MapTheme) -> void:
	var seen := {}
	for start: int in g.bridged:
		if seen.has(start):
			continue
		var span: Array = [start]
		seen[start] = true
		var banks: Array[int] = []
		var surface := g.level[start]
		var k := 0
		while k < span.size():
			for n in g.neighbors(span[k]):
				if g.bridged.has(n):
					if not seen.has(n):
						seen[n] = true
						span.append(n)
				elif g.token[n] == "p":
					banks.append(g.level[n])
			surface = maxi(surface, g.level[span[k]])
			k += 1
		var deck := surface
		if not banks.is_empty():
			deck = maxi(surface, mini(banks.max(), banks.min() + GenElevation.MAX_STEP))
		span.sort()
		g.bridges.append({"hexes": span, "type": t.bridge_type, "level": deck})
