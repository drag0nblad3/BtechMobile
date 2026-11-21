class_name WoodsFire
extends RefCounted
## Setting woods alight (book p. 123): a heat-causing weapon (a flamer) may
## shoot a woods hex directly. The hex can't dodge (-4). Hits dealing 4
## heat in total in one phase, from any number of attackers, set it on fire
## at the end of the phase (Fire), and it burns for the rest of the battle.
## A missed shot at a 'Mech standing there never lights the hex.
## TODO(rules): jungle, foliage and the ice/mud/snow/swamp and rain
## exceptions aren't on our maps.

const HEAT_TO_LIGHT := 4
const HEX_MOD := -4


## Woods that aren't burning yet.
static func can_light(tile: MapTile) -> bool:
	return tile != null and tile.building == null and tile.terrain.flammable \
			and not tile.is_water() and not tile.on_fire and tile.surface == ""


## Why `w` can't shoot this hex to light it ("" = it can).
static func problem(tile: MapTile, w: MountedWeapon) -> String:
	if not can_light(tile):
		return "Nothing there to burn" if tile == null or not tile.on_fire else "Already burning"
	if not w.def.heat_damage:
		return "Only heat-causing weapons (flamers) can set woods alight"
	return ""


## Adds the hex's own modifier to a shot at it.
static func add_mods(th: ToHit) -> void:
	th.add("woods hex", HEX_MOD, "A patch of woods can't move or dodge: -4. Hits totalling 4 heat this phase set it alight.")


## What a hex target is called in the log: the building, or the terrain.
static func noun(tile: MapTile) -> String:
	if tile == null:
		return "hex"
	if tile.building != null:
		return "building"
	return "bridge" if tile.bridge != null else tile.terrain.name.to_lower()
