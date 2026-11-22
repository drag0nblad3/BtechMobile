class_name GenPath
extends RefCounted
## Cheapest path across the generator grid, from any start hex to the
## first hex `is_goal` accepts. Rivers and roads use it with their own
## step costs (`cost.call(from, to)`, at least 1).


static func find(g: GenGrid, starts: Array, is_goal: Callable, cost: Callable) -> Array:
	var dist := {}
	var prev := {}
	var heap := MinHeap.new()
	for s: int in starts:
		dist[s] = 0
		heap.push(0, s)
	while not heap.is_empty():
		var top := heap.pop()
		var d: int = top[0]
		var i: int = top[1]
		if d > dist[i]:
			continue
		if is_goal.call(i):
			return _walk_back(prev, i)
		for n in g.neighbors(i):
			var nd := d + maxi(1, int(cost.call(i, n)))
			if nd < int(dist.get(n, 1 << 30)):
				dist[n] = nd
				prev[n] = i
				heap.push(nd, n)
	return []


static func _walk_back(prev: Dictionary, last: int) -> Array:
	var out: Array = [last]
	while prev.has(out[-1]):
		out.append(prev[out[-1]])
	out.reverse()
	return out


## Every hex along one edge: "top", "bottom", "left" or "right".
static func edge(g: GenGrid, side: String) -> Array:
	var out: Array = []
	match side:
		"top", "bottom":
			var r := 0 if side == "top" else g.h - 1
			for c in g.w:
				out.append(g.idx(c, r))
		_:
			var c := 0 if side == "left" else g.w - 1
			for r in g.h:
				out.append(g.idx(c, r))
	return out


static func opposite(side: String) -> String:
	return {"top": "bottom", "bottom": "top", "left": "right", "right": "left"}[side]
