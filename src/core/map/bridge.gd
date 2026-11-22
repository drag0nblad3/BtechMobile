class_name Bridge
extends Building
## One hex of a bridge (book pp. 53, 131): a deck at `level` over water or
## lower ground. It has a building class (default medium) and can be shot
## like a building, but nobody goes inside it: a 'Mech is either on the
## deck or underneath. All hexes of one bridge share `span`, so losing more
## than half of them brings the rest down.

var level := 0  ## Level of the deck surface.
var span: Array = []  ## Every hex (Vector2i) of this bridge, shared.


func _init(t: BuildingType, deck_level: int, hexes: Array) -> void:
	super(t, 1)
	level = deck_level
	span = hexes
