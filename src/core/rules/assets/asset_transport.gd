class_name AssetTransport
extends RefCounted
## Armored Personnel Carriers (APC X Special, book p. 148). An APC carries
## X foot or jump infantry Assets (battle armor takes 2 points each).
## Battle armor with the Mechanized Special rides any friendly OmniMech
## as if it had APC2. Infantry boards or deploys in the APC's hex during
## the Movement Phase; riders aren't units for any purpose while aboard,
## can't fire the turn they deploy and have TMM 0 that turn. When the APC
## is destroyed its riders die, except mechanized battle armor on an
## OmniMech, which is set down in the 'Mech's last hex if it may be there.
## Record-sheet battle armor (Unit.ba) that is mechanized rides OmniMechs
## the same way, one squad per 'Mech; riders shield it (BaRiders).
## TODO(rules): starting the game aboard; the book times boarding at the
## end of the Movement Phase, here it happens when the infantry acts.
## Record-sheet squads follow Total Warfare from general knowledge.


## APC points `carrier` offers `rider`, 0 if it can't carry it at all.
static func capacity(carrier: Unit, rider: Unit) -> int:
	if rider.ba != null:
		return 2 if carrier.asset == null and carrier.def.omni and rider.def.battle_armor.mechanized() else 0
	if rider.asset == null or not rider.asset.card.is_infantry() or rider.asset.card.mechanized:
		return 0
	if carrier.asset == null:
		return 2 if carrier.def.omni and rider.asset.card.has("MECHANIZED") else 0
	return carrier.asset.card.special("APC")


static func cost(rider: Unit) -> int:
	return 2 if rider.ba != null or (rider.asset != null and rider.asset.card.kind == AssetCard.BATTLE_ARMOR) else 1


static func riders(state: GameState, carrier: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in state.units:
		if u.carrier_id() == carrier.id and not u.destroyed:
			out.append(u)
	return out


static func used(state: GameState, carrier: Unit) -> int:
	var n := 0
	for r in riders(state, carrier):
		n += cost(r)
	return n


## Why `rider` can't board `carrier` now, or "".
static func board_problem(state: GameState, rider: Unit, carrier: Unit) -> String:
	if carrier == null or carrier.destroyed or carrier.side != rider.side or carrier == rider:
		return "No friendly transport"
	if not AssetStacking.is_infantry(rider) or rider.carrier_id() >= 0:
		return "Only infantry on the ground can board"
	if carrier.coord != rider.coord:
		return "The transport must be in the same hex"
	var cap := capacity(carrier, rider)
	if cap == 0:
		return "%s can't carry %s" % [carrier.label(), rider.label()]
	if used(state, carrier) + cost(rider) > cap:
		return "%s is full" % carrier.label()
	return ""


static func board(state: GameState, emit: Callable, rider: Unit, carrier: Unit) -> void:
	rider.set_carrier(carrier.id)
	rider.has_moved = true
	emit.call(GameEvent.TRANSPORT, {"unit_id": rider.id, "carrier_id": carrier.id, "kind": "board"})


## Why a rider can't get off here, or "".
static func deploy_problem(state: GameState, rider: Unit) -> String:
	if rider.carrier_id() < 0:
		return "Not aboard a transport"
	var carrier := state.unit_by_id(rider.carrier_id())
	if not may_stand(rider, state.map.get_tile(carrier.coord)):
		return "Infantry can't get out in that terrain"
	if not AssetStacking.can_end(state, rider, carrier.coord):
		return "No room in that hex"
	return ""


static func deploy(state: GameState, emit: Callable, rider: Unit) -> void:
	var carrier := state.unit_by_id(rider.carrier_id())
	rider.set_carrier(-1)
	rider.coord = carrier.coord
	if rider.ba != null:
		rider.ba.deployed_turn = state.turn
	else:
		rider.asset.deployed_turn = state.turn
	rider.has_moved = true
	emit.call(GameEvent.TRANSPORT, {"unit_id": rider.id, "carrier_id": carrier.id, "kind": "deploy"})


## Riders go where their transport went.
static func follow(state: GameState, carrier: Unit) -> void:
	for r in riders(state, carrier):
		r.coord = carrier.coord
		r.facing = carrier.facing


## A destroyed transport takes its riders with it (p. 148).
static func check_losses(state: GameState, emit: Callable) -> void:
	for r in state.units:
		if r.carrier_id() < 0 or r.destroyed:
			continue
		var carrier := state.unit_by_id(r.carrier_id())
		if carrier != null and not carrier.destroyed:
			r.coord = carrier.coord  # shoved or displaced with it
			continue
		r.set_carrier(-1)
		var on_omni := carrier != null and carrier.asset == null
		if on_omni and may_stand(r, state.map.get_tile(r.coord)):
			emit.call(GameEvent.TRANSPORT, {"unit_id": r.id, "carrier_id": carrier.id, "kind": "thrown"})
			continue
		Damage.destroy_unit(r, "its transport was destroyed")
		Damage.announce(emit, r)


## May infantry `u` stand on `tile` once off its transport?
static func may_stand(u: Unit, tile: MapTile) -> bool:
	return BaMoveCost.may_enter(tile) if u.ba != null else AssetMoveCost.may_enter(u.asset.card, tile)
