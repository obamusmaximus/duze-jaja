class_name StrategyFigures
extends RefCounted
## View data shared by the strategy views' marks (`WarTableTokens`, `BirdsEyeBlips`): one figure per carryall, per
## mothership, per squad (at its members' centre) and per unit with no squad, with its team. Read from the unit
## registry and the `motherships` group; changes nothing.

enum Kind { UNIT, SQUAD, CARRYALL, MOTHERSHIP }

var positions := PackedVector3Array()
var kinds := PackedInt32Array()
var teams := PackedInt32Array()
## Members per figure (1 for a unit, carryall or mothership).
var counts := PackedInt32Array()
## The unit ids behind each figure (one for a unit or carryall, the members for a squad, none for a mothership).
var members: Array[PackedInt32Array] = []


func size() -> int:
	return positions.size()


func collect(units: UnitRegistry, tree: SceneTree) -> void:
	positions.clear()
	kinds.clear()
	teams.clear()
	counts.clear()
	members.clear()
	if units == null:
		return
	## Squad id to [position sum, members, team].
	var sums: Dictionary = {}
	for unit: Unit in units.all_units():
		if unit.carryall != null:
			_add(unit.global_position, Kind.CARRYALL, unit.team, 1, PackedInt32Array([unit.id]))
		elif unit.squad_id != 0:
			var entry: Array = sums.get(unit.squad_id, [Vector3.ZERO, 0, unit.team, PackedInt32Array()])
			(entry[3] as PackedInt32Array).append(unit.id)
			entry[0] = (entry[0] as Vector3) + unit.global_position
			entry[1] = int(entry[1]) + 1
			sums[unit.squad_id] = entry
		else:
			_add(unit.global_position, Kind.UNIT, unit.team, 1, PackedInt32Array([unit.id]))
	for entry: Array in sums.values():
		_add((entry[0] as Vector3) / float(entry[1]), Kind.SQUAD, int(entry[2]), int(entry[1]), entry[3])
	for node: Node in tree.get_nodes_in_group(&"motherships"):
		var ship := node as Mothership
		if ship != null:
			_add(ship.global_position, Kind.MOTHERSHIP, ship.team, 1, PackedInt32Array())


func _add(at: Vector3, kind: Kind, team: int, count: int, ids: PackedInt32Array) -> void:
	members.append(ids)
	positions.append(at)
	kinds.append(kind)
	teams.append(team)
	counts.append(count)
