class_name Formation
## Spreads a group move into a loose block around the clicked point, facing the way the group travels, so units
## don't all head for one spot.


## One destination per unit, in the order of `from` (the units' positions). Rows run across the travel direction,
## front row first; the units nearest the goal take the front row, sorted left to right within each row, so paths
## cross little.
static func slots(from: PackedVector3Array, target: Vector3, spacing: float) -> PackedVector3Array:
	var count: int = from.size()
	var result := PackedVector3Array()
	result.resize(count)
	if count == 0:
		return result
	if count == 1:
		result[0] = target
		return result
	var centre := Vector3.ZERO
	for point: Vector3 in from:
		centre += point
	centre /= count
	var forward: Vector3 = target - centre
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD
	var right: Vector3 = forward.cross(Vector3.UP)
	var columns: int = ceili(sqrt(float(count)))
	var rows: int = ceili(float(count) / columns)
	# Units by how far forward they are, frontmost first.
	var order: Array = range(count)
	order.sort_custom(func(a: int, b: int) -> bool: return from[a].dot(forward) > from[b].dot(forward))
	var placed: int = 0
	for row: int in rows:
		var in_row: int = mini(columns, count - placed)
		var members: Array = order.slice(placed, placed + in_row)
		members.sort_custom(func(a: int, b: int) -> bool: return from[a].dot(right) < from[b].dot(right))
		var ahead: float = ((rows - 1) * 0.5 - row) * spacing
		for column: int in in_row:
			var across: float = (column - (in_row - 1) * 0.5) * spacing
			result[members[column]] = target + forward * ahead + right * across
		placed += in_row
	return result
