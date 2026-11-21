class_name Order
extends RefCounted
## A command from a player or an AI, as plain data: unit ids and a target point or unit id, never node references,
## so it can go over the network and into saves later. Sent through `CommandIssuer.issue()`, the only way in.

enum Kind { MOVE, ATTACK, ATTACK_MOVE, STOP }

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


static func move(by_team: int, ids: PackedInt32Array, point: Vector3, add_to_queue: bool = false) -> Order:
	return _make(Kind.MOVE, by_team, ids, point, 0, add_to_queue)


static func attack_move(by_team: int, ids: PackedInt32Array, point: Vector3, add_to_queue: bool = false) -> Order:
	return _make(Kind.ATTACK_MOVE, by_team, ids, point, 0, add_to_queue)


static func attack(by_team: int, ids: PackedInt32Array, target_id: int, add_to_queue: bool = false) -> Order:
	return _make(Kind.ATTACK, by_team, ids, Vector3.ZERO, target_id, add_to_queue)


static func stop(by_team: int, ids: PackedInt32Array) -> Order:
	return _make(Kind.STOP, by_team, ids, Vector3.ZERO, 0, false)


## This order for one unit of the group, with its own target point (its place in a group move).
func for_unit(unit_id: int, point: Vector3) -> Order:
	return _make(kind, team, PackedInt32Array([unit_id]), point, target_unit_id, queued)


func kind_name() -> String:
	return String(Kind.keys()[kind]).to_lower()


func to_dict() -> Dictionary:
	return {
		"kind": kind_name(), "team": team, "unit_ids": Array(unit_ids), "target_position": target_position,
		"target_unit_id": target_unit_id, "queued": queued,
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
