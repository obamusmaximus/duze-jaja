class_name Airfield
extends Node3D
## A team's airfield (`docs/mechanics/airfield.md`): a flat deck standing on the ground with six `Pad`s in two rows,
## a hangar behind each. It hands the pads out, first come first served; craft that find them all taken wait over its
## holding point. The deck is a platform of the air layer (flyers treat it as ground), its footprint blocks the map
## grid for ground units and the hangars are solid to a flown craft. It can't be damaged. Add it to the tree, then
## call `setup`. Simulation, except the model it adds (`AirfieldLook`). Group: `airfields`.

const PADS_PER_ROW: int = 3
const ROWS: int = 2
const BUILDING_LAYER: int = 1 << 2

## The pads are for carryalls; otherwise for the other flyers that use pads (fighters, VTOLs).
var for_carryalls: bool = false
## The owning team.
var team: int = 0
## Unique among the level's airfields, from 1; orders name an airfield by it.
var airfield_id: int = 0
var stats: AirfieldStats
var pads: Array[Pad] = []

## The deck's footprint on the ground (world x, z) and the height of its top.
var _area := Rect2()
var _deck: float = 0.0
## Ids of the units waiting for a pad, in the order they asked.
var _waiting: Array[int] = []


## Places the airfield with its middle over `spot` (world x, z) on the ground of `map` and joins it to the match.
func setup(spot: Vector2, map: MapGrid, registry: UnitRegistry) -> void:
	add_to_group(&"airfields")
	_area = footprint(stats, spot)
	var heights: Vector2 = _ground_range(map.air)
	_deck = heights.y + stats.deck_lift
	global_position = Vector3(spot.x, _deck, spot.y)
	_make_pads()
	_make_hangar_solids()
	map.air.add_platform(_area, _deck)
	map.set_blocked(_area, true)
	registry.unit_removed.connect(func(unit: Unit) -> void: release(unit.id))
	var look := AirfieldLook.new()
	look.name = "Look"
	add_child(look)
	look.build(self, _deck - heights.x)


## The deck's area (world x, z) for an airfield centred on `spot`.
static func footprint(layout: AirfieldStats, spot: Vector2) -> Rect2:
	var half := Vector2(layout.row_offset + layout.hangar_offset + layout.hangar_size.x * 0.5,
			layout.pad_spacing * (PADS_PER_ROW - 1) * 0.5 + maxf(layout.hangar_size.z, layout.pad_size) * 0.5)
	half += Vector2.ONE * layout.deck_margin
	return Rect2(spot - half, half * 2.0)


func deck_size() -> Vector2:
	return _area.size


## Where the hangar behind `pad` stands: its middle on the deck.
func hangar_position(pad: Pad) -> Vector3:
	return pad.position - pad.forward() * stats.hangar_offset


## Whether `unit` is the kind of craft these pads take.
func serves(unit: Unit) -> bool:
	return unit.landing != null and unit.explorer == null and (unit.carryall != null) == for_carryalls


## The airfield of `unit`'s team that takes it: `wanted` (an `airfield_id`), or with 0 the nearest one with a pad to
## spare (counting the pads `promised` to others, airfield to count), else the nearest of all, to wait at. A pad the
## unit already holds counts as spare. Null if there is none.
static func nearest_for(unit: Unit, wanted: int = 0, promised: Dictionary = {}) -> Airfield:
	var best: Airfield = null
	var best_score := Vector2(INF, INF)
	for node: Node in unit.get_tree().get_nodes_in_group(&"airfields"):
		var field := node as Airfield
		if field.team != unit.team or not field.serves(unit) or (wanted != 0 and field.airfield_id != wanted):
			continue
		var room: bool = field.pad_of(unit.id) != null or field.free_pads() > int(promised.get(field, 0))
		var score := Vector2(0.0 if room else 1.0, unit.global_position.distance_squared_to(field.global_position))
		if score < best_score:
			best = field
			best_score = score
	return best


## The pad `unit_id` holds, or null.
func pad_of(unit_id: int) -> Pad:
	for pad: Pad in pads:
		if pad.holder() == unit_id:
			return pad
	return null


## The pad for `unit_id`: the one it holds, else a free one if its turn has come. Null means wait (it keeps its place
## in the line until `release`).
func request_pad(unit_id: int) -> Pad:
	var held: Pad = pad_of(unit_id)
	if held != null:
		return held
	if not _waiting.has(unit_id):
		_waiting.append(unit_id)
	var free: Array[Pad] = []
	for pad: Pad in pads:
		if pad.is_free():
			free.append(pad)
	if _waiting.find(unit_id) >= free.size():
		return null
	_waiting.erase(unit_id)
	free[0].reserve(unit_id)
	return free[0]


## `unit_id` gives up its pad or its place in the line.
func release(unit_id: int) -> void:
	_waiting.erase(unit_id)
	for pad: Pad in pads:
		pad.release(unit_id)


## Pads neither held nor spoken for by a waiting craft.
func free_pads() -> int:
	var free: int = 0
	for pad: Pad in pads:
		if pad.is_free():
			free += 1
	return maxi(free - _waiting.size(), 0)


## Where craft wait while every pad is taken: toward the middle of the map, on the ground or sea there.
func holding_point() -> Vector3:
	var toward := Vector3(-global_position.x, 0.0, -global_position.z)
	toward = toward.normalized() if toward.length() > 1.0 else Vector3.FORWARD
	return global_position + toward * stats.holding_distance


## How far along a ray the deck (or the roof level of its hangars) is met, or INF: for picking, without physics.
func ray_distance(from: Vector3, direction: Vector3) -> float:
	if direction.y > -0.001:
		return INF
	for height: float in [_deck + stats.hangar_size.y, _deck]:
		var along: float = (height - from.y) / direction.y
		var at: Vector3 = from + direction * along
		if along > 0.0 and _area.has_point(Vector2(at.x, at.z)):
			return along
	return INF


## Pad rows run along z; each row's craft face the other row, backs to their hangars.
func _make_pads() -> void:
	for row: int in ROWS:
		var side: float = -1.0 if row == 0 else 1.0
		for i: int in PADS_PER_ROW:
			var offset := Vector3(side * stats.row_offset, 0.0, (i - (PADS_PER_ROW - 1) * 0.5) * stats.pad_spacing)
			pads.append(Pad.new(global_position + offset, side * PI * 0.5, stats.pad))


func _make_hangar_solids() -> void:
	var body := StaticBody3D.new()
	body.name = "Hangars"
	body.collision_layer = BUILDING_LAYER
	body.collision_mask = 0
	add_child(body)
	for pad: Pad in pads:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = stats.hangar_size
		shape.shape = box
		shape.position = hangar_position(pad) - global_position + Vector3.UP * stats.hangar_size.y * 0.5
		body.add_child(shape)


## The lowest (x) and highest (y) ground under the deck.
func _ground_range(air: AirLayer) -> Vector2:
	var out := Vector2(INF, -INF)
	var steps := Vector2i(ceili(_area.size.x / 2.0), ceili(_area.size.y / 2.0))
	for ix: int in steps.x + 1:
		for iz: int in steps.y + 1:
			var at: Vector2 = _area.position + _area.size * Vector2(float(ix) / steps.x, float(iz) / steps.y)
			var height: float = air.ground_height(Vector3(at.x, 0.0, at.y))
			out = Vector2(minf(out.x, height), maxf(out.y, height))
	return out
