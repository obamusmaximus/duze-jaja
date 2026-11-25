class_name MapMarker
extends RefCounted
## One map marker as plain data: what the strategist wants done at a ground point (`docs/mechanics/orders.md`,
## "Map markers"). Only the kind and place are kept; what a marker makes squads do comes with the AI commander and
## squad jobs. Held by `MapMarkers`.

enum Kind { ATTACK, GUARD, GATHER, SCOUT, LZ }

var id: int = 0
var kind: Kind = Kind.ATTACK
var team: int = 0
var position: Vector3 = Vector3.ZERO


static func kind_label(of: Kind) -> String:
	return String(Kind.keys()[of])
