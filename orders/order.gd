class_name Order
extends RefCounted
## A command from a player or an AI, as plain data: unit ids and a target point or unit id, never node references,
## so it can go over the network and into saves later. Sent through `CommandIssuer.issue()`, the only way in.

enum Kind { MOVE, ATTACK, ATTACK_MOVE, STOP, PRODUCE, CANCEL, DELIVER, MARKER, CLEAR_MARKER, INHABIT, LEAVE, ABILITY, LAND, BUILD_EXPLORER, CANCEL_EXPLORER, LOAD_EXPLORER }

## How a carryall puts its cargo down. Only landing exists so far; para-drop falls back to it.
enum DeliveryMode { LAND, PARADROP }

var kind: Kind = Kind.STOP
## The issuing team; the issuer refuses units that aren't its own.
var team: int = 0
var unit_ids: PackedInt32Array = PackedInt32Array()
## Ground point for move and attack-move.
var target_position: Vector3 = Vector3.ZERO
## Unit id for attack; 0 for none.
var target_unit_id: int = 0
## Add after the orders already queued (a waypoint) instead of replacing them.
var queued: bool = false
## Produce: the squad to build.
var squad_spec: SquadSpec
## Produce: the production line (0 up) to queue it on; -1 picks the least busy one.
var line: int = -1
## Cancel: the ticket `produce` was given (`Production.queue`).
var ticket: int = 0
## Deliver: how the cargo is put down.
var mode: DeliveryMode = DeliveryMode.LAND
## A carryall's own land order back to a mothership pad after a delivery (not given by players).
var returning: bool = false
## Marker: what kind to put at `target_position`. Clear marker: `marker_id` names the marker to take away.
var marker_kind: MapMarker.Kind = MapMarker.Kind.ATTACK
var marker_id: int = 0
## Land: the airfield to land at (`Airfield.airfield_id`); 0 for the nearest own one with room.
var airfield_id: int = 0
## Load Explorer: the unit type (`UnitCatalog.id_of`) and how many to put aboard (negative: take off again).
var type_id: StringName = &""
var count: int = 0


static func move(by_team: int, ids: PackedInt32Array, point: Vector3, add_to_queue: bool = false) -> Order:
	return _make(Kind.MOVE, by_team, ids, point, 0, add_to_queue)


static func attack_move(by_team: int, ids: PackedInt32Array, point: Vector3, add_to_queue: bool = false) -> Order:
	return _make(Kind.ATTACK_MOVE, by_team, ids, point, 0, add_to_queue)


static func attack(by_team: int, ids: PackedInt32Array, target_id: int, add_to_queue: bool = false) -> Order:
	return _make(Kind.ATTACK, by_team, ids, Vector3.ZERO, target_id, add_to_queue)


static func stop(by_team: int, ids: PackedInt32Array) -> Order:
	return _make(Kind.STOP, by_team, ids, Vector3.ZERO, 0, false)


## Queue `spec` on a line of the team's mothership (`line` -1: the least busy).
static func produce(by_team: int, spec: SquadSpec, on_line: int = -1) -> Order:
	var order := _make(Kind.PRODUCE, by_team, PackedInt32Array(), Vector3.ZERO, 0, false)
	order.squad_spec = spec
	order.line = on_line
	return order


## Carryalls `ids` fly what they hold to `point`, land, put it down there and return to a mothership pad. A
## carryall's deploy ability is this at the spot it is over.
static func deliver(by_team: int, ids: PackedInt32Array, point: Vector3, delivery_mode: DeliveryMode = DeliveryMode.LAND) -> Order:
	var order := _make(Kind.DELIVER, by_team, ids, point, 0, false)
	order.mode = delivery_mode
	return order


## Units `ids` use their abilities now (never queued; their other orders stand). A targeted ability is aimed at
## `point` or the unit `target_id`.
static func ability(by_team: int, ids: PackedInt32Array, point: Vector3 = Vector3.ZERO, target_id: int = 0) -> Order:
	return _make(Kind.ABILITY, by_team, ids, point, target_id, false)


## Flyers `ids` land on a pad of the airfield `at_airfield` to repair, or with 0 of the nearest own airfield with
## room. For the unit its team's player is flying this switches the autopilot instead: on, to fly there and land, or
## off, to hand the controls back (after taking off, if it is on a pad).
static func land(by_team: int, ids: PackedInt32Array, at_airfield: int = 0, add_to_queue: bool = false) -> Order:
	var order := _make(Kind.LAND, by_team, ids, Vector3.ZERO, 0, add_to_queue)
	order.airfield_id = at_airfield
	return order


## The team's player takes over its unit `unit_id` (`PilotSeats`).
static func inhabit(by_team: int, unit_id: int) -> Order:
	return _make(Kind.INHABIT, by_team, PackedInt32Array([unit_id]), Vector3.ZERO, 0, false)


## The team's player leaves the unit they inhabit.
static func leave(by_team: int) -> Order:
	return _make(Kind.LEAVE, by_team, PackedInt32Array(), Vector3.ZERO, 0, false)


## Put a map marker of `kind` on the ground at `point` (no units involved).
static func place_marker(by_team: int, kind: MapMarker.Kind, point: Vector3) -> Order:
	var order := _make(Kind.MARKER, by_team, PackedInt32Array(), point, 0, false)
	order.marker_kind = kind
	return order


## Take the team's marker `id` off the map.
static func clear_marker(by_team: int, id: int) -> Order:
	var order := _make(Kind.CLEAR_MARKER, by_team, PackedInt32Array(), Vector3.ZERO, 0, false)
	order.marker_id = id
	return order


## Start an Explorer on the team's mothership pad.
static func build_explorer(by_team: int) -> Order:
	return _make(Kind.BUILD_EXPLORER, by_team, PackedInt32Array(), Vector3.ZERO, 0, false)


## Stop the Explorer being built and get the credits back.
static func cancel_explorer(by_team: int) -> Order:
	return _make(Kind.CANCEL_EXPLORER, by_team, PackedInt32Array(), Vector3.ZERO, 0, false)


## Put `how_many` units of a type into the Explorer on the team's pad, built or building (negative: take them off).
static func load_explorer(by_team: int, unit_type_id: StringName, how_many: int = 1) -> Order:
	var order := _make(Kind.LOAD_EXPLORER, by_team, PackedInt32Array(), Vector3.ZERO, 0, false)
	order.type_id = unit_type_id
	order.count = how_many
	return order


## Take the queued or building squad with `ticket` off its line and get the credits back.
static func cancel(by_team: int, production_ticket: int) -> Order:
	var order := _make(Kind.CANCEL, by_team, PackedInt32Array(), Vector3.ZERO, 0, false)
	order.ticket = production_ticket
	return order


## This order for one unit of the group, with its own target point (its place in a group move).
func for_unit(unit_id: int, point: Vector3) -> Order:
	var order := _make(kind, team, PackedInt32Array([unit_id]), point, target_unit_id, queued)
	order.mode = mode
	order.returning = returning
	order.airfield_id = airfield_id
	return order


func kind_name() -> String:
	return String(Kind.keys()[kind]).to_lower()


func to_dict() -> Dictionary:
	return {
		"kind": kind_name(), "team": team, "unit_ids": Array(unit_ids), "target_position": target_position,
		"target_unit_id": target_unit_id, "queued": queued,
		"squad": squad_spec.to_dict() if squad_spec else {}, "line": line, "ticket": ticket, "mode": DeliveryMode.keys()[mode],
		"marker": MapMarker.Kind.keys()[marker_kind], "marker_id": marker_id, "airfield": airfield_id,
		"type": String(type_id), "count": count,
	}


static func _make(new_kind: Kind, by_team: int, ids: PackedInt32Array, point: Vector3, target_id: int, add_to_queue: bool) -> Order:
	var order := Order.new()
	order.kind = new_kind
	order.team = by_team
	order.unit_ids = ids
	order.target_position = point
	order.target_unit_id = target_id
	order.queued = add_to_queue
	return order
