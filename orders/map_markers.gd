class_name MapMarkers
extends Node
## The markers each team has put on the map (`MapMarker`): attack, guard, gather, scout, and a single landing zone
## (LZ). Plain data on the simulation side, changed only by `CommandIssuer` (marker orders); views read it to draw
## them and the AI commander will read it later. A team over `max_per_team` loses its oldest. Group `map_markers`.

signal changed(team: int)

## Set by the level from `OrderStats.max_markers`.
var max_per_team: int = 12

var _by_team: Dictionary = {}
var _next_id: int = 1


func _ready() -> void:
	add_to_group(&"map_markers")


## Puts a marker down; returns its id. The LZ is unique per team: a new one replaces the old.
func place(team: int, kind: MapMarker.Kind, point: Vector3) -> int:
	var list: Array[MapMarker] = _list(team)
	if kind == MapMarker.Kind.LZ:
		for old: MapMarker in list.duplicate():
			if old.kind == kind:
				list.erase(old)
	var marker := MapMarker.new()
	marker.id = _next_id
	_next_id += 1
	marker.kind = kind
	marker.team = team
	marker.position = point
	list.append(marker)
	while list.size() > max_per_team:
		list.pop_front()
	changed.emit(team)
	return marker.id


func remove(team: int, id: int) -> bool:
	var list: Array[MapMarker] = _list(team)
	for marker: MapMarker in list:
		if marker.id == id:
			list.erase(marker)
			changed.emit(team)
			return true
	return false


func of_team(team: int) -> Array[MapMarker]:
	return _list(team)


func _list(team: int) -> Array[MapMarker]:
	if not _by_team.has(team):
		var fresh: Array[MapMarker] = []
		_by_team[team] = fresh
	return _by_team[team]
