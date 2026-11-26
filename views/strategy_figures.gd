class_name StrategyFigures
extends RefCounted
## View data for the bird's-eye view's marks (`BirdsEyeBlips`, `StrategyOverlay`): one figure per carryall, per
## mothership, per squad (at its members' centre) and per unit with no squad, with its team. Read from the unit
## registry and the `motherships` group; changes nothing. Only units in view (`FogView`): a squad is its drawn members.

enum Kind { UNIT, SQUAD, CARRYALL, MOTHERSHIP }

## A squad's members as they are gathered. An object, so appends reach the stored array (a packed array taken out of
## an `Array` with `as` is a copy).
class SquadSum:
	var position_sum := Vector3.ZERO
	var team: int = 0
	var ids := PackedInt32Array()
	var level: float = 0.0
	var known: bool = false


var positions := PackedVector3Array()
var kinds := PackedInt32Array()
var teams := PackedInt32Array()
## Members per figure (1 for a unit, carryall or mothership).
var counts := PackedInt32Array()
## How much of each figure is drawn, 0 to 1 (a squad's most visible member), and whether it can be picked.
var levels := PackedFloat32Array()
var knowns: Array[bool] = []
## The unit ids behind each figure (one for a unit or carryall, the members for a squad, none for a mothership).
var members: Array[PackedInt32Array] = []


func size() -> int:
	return positions.size()


func collect(units: UnitRegistry, tree: SceneTree) -> void:
	positions.clear()
	kinds.clear()
	teams.clear()
	counts.clear()
	levels.clear()
	knowns.clear()
	members.clear()
	if units == null:
		return
	## Squad id to its `SquadSum`.
	var sums: Dictionary = {}
	for unit: Unit in units.all_units():
		if not unit.is_drawn():
			continue
		if unit.carryall != null:
			_add(unit.global_position, Kind.CARRYALL, unit.team, 1, PackedInt32Array([unit.id]), unit.view_level,
					unit.in_view)
		elif unit.squad_id != 0:
			var sum: SquadSum = sums.get(unit.squad_id)
			if sum == null:
				sum = SquadSum.new()
				sum.team = unit.team
				sums[unit.squad_id] = sum
			sum.ids.append(unit.id)
			sum.position_sum += unit.global_position
			sum.level = maxf(sum.level, unit.view_level)
			sum.known = sum.known or unit.in_view
		else:
			_add(unit.global_position, Kind.UNIT, unit.team, 1, PackedInt32Array([unit.id]), unit.view_level, unit.in_view)
	for sum: SquadSum in sums.values():
		_add(sum.position_sum / float(sum.ids.size()), Kind.SQUAD, sum.team, sum.ids.size(), sum.ids, sum.level,
				sum.known)
	for node: Node in tree.get_nodes_in_group(&"motherships"):
		var ship := node as Mothership
		if ship != null:
			_add(ship.global_position, Kind.MOTHERSHIP, ship.team, 1, PackedInt32Array(), 1.0, true)


func _add(at: Vector3, kind: Kind, team: int, count: int, ids: PackedInt32Array, level: float, known: bool) -> void:
	levels.append(level)
	knowns.append(known)
	members.append(ids)
	positions.append(at)
	kinds.append(kind)
	teams.append(team)
	counts.append(count)
