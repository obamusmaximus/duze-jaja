class_name IslandLevel
extends SandboxLevel
## The green island level: a long map of sea with an island in the middle and a carrier (a team's main base) in the
## water at each end. On top of the sandbox's match wiring it hands the sea its shore: rectangles read from the
## terrain layout (the island) and from each carrier's footprint, so the foam and calm water follow them.

@onready var _water: WaterBody = $Water


func _ready() -> void:
	var shore: Array[Rect2] = _island_rects()
	for carrier: Node in get_tree().get_nodes_in_group(&"carriers"):
		shore.append((carrier as Carrier).footprint())
	_water.set_shore(shore)
	await super()


## The island as rectangles: each row of tiles is a run, and neighbouring rows with the same run join into one.
func _island_rects() -> Array[Rect2]:
	var terrain: TerrainMap = $Terrain
	var size: float = terrain.tile_size()
	var rows: Dictionary = {}
	for cell: Vector2i in terrain.layout.cells():
		var run: Vector2i = rows.get(cell.y, Vector2i(cell.x, cell.x))
		rows[cell.y] = Vector2i(mini(run.x, cell.x), maxi(run.y, cell.x))
	var keys: Array = rows.keys()
	keys.sort()
	var rects: Array[Rect2] = []
	var open: Rect2 = Rect2()
	var open_run := Vector2i.ZERO
	var open_row: int = 0
	for row: int in keys:
		var run: Vector2i = rows[row]
		if not open.has_area() or run != open_run or row != open_row + 1:
			if open.has_area():
				rects.append(open)
			open = Rect2(run.x * size, row * size, (run.y - run.x + 1) * size, size)
			open_run = run
		else:
			open.size.y += size
		open_row = row
	if open.has_area():
		rects.append(open)
	return rects
