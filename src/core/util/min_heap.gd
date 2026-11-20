class_name MinHeap
extends RefCounted
## Binary min-heap of (priority, value) pairs. Used by path planners.

var _prio: Array[int] = []
var _vals: Array = []


func is_empty() -> bool:
	return _prio.is_empty()


func push(priority: int, value: Variant) -> void:
	_prio.append(priority)
	_vals.append(value)
	var i := _prio.size() - 1
	while i > 0:
		var p := (i - 1) / 2
		if _prio[p] <= _prio[i]:
			break
		_swap(i, p)
		i = p


## Returns [priority, value] of the smallest entry.
func pop() -> Array:
	var top := [_prio[0], _vals[0]]
	var last := _prio.size() - 1
	_swap(0, last)
	_prio.pop_back()
	_vals.pop_back()
	var i := 0
	var n := _prio.size()
	while true:
		var l := i * 2 + 1
		var r := l + 1
		var m := i
		if l < n and _prio[l] < _prio[m]:
			m = l
		if r < n and _prio[r] < _prio[m]:
			m = r
		if m == i:
			break
		_swap(i, m)
		i = m
	return top


func _swap(a: int, b: int) -> void:
	var tp := _prio[a]
	_prio[a] = _prio[b]
	_prio[b] = tp
	var tv: Variant = _vals[a]
	_vals[a] = _vals[b]
	_vals[b] = tv
