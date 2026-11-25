class_name HotDog
extends RefCounted
## Hot Dog SPA (Campaign Operations p. 76): -1 to the rolls that avoid
## overheating effects (heat shutdown and ammo cook-off). Automatic
## results (no roll, or can't avoid) stay as they are.


static func need(u: Unit, n: int) -> int:
	return n - 1 if Spa.has(u, Spa.HOT_DOG) and n > 0 and n < 99 else n
