class_name Mothership
extends StaticBody3D
## A team's hovering main base (`docs/mechanics/battlefield.md`, `GAME_DESIGN.md` "Setting"): in the air, no ground
## footprint, nothing on the map grid. Its position is simulation state, set with `place()` (relocation comes later).
## The hull is the stats' model scene (`MothershipProto` for now); the collision is a few boxes on the Building layer.
## A soft shadow quad on the sea shows the hover when sun shadows are off. Any bob would be view-only. Group: `motherships`.

## Height of the light pool on the sea, clear of the wave crests.
const SEA_POOL_HEIGHT: float = 1.4

## The team that owns the mothership.
@export var team: int = 0
@export var stats: MothershipStats

var _model: MothershipProto
var _hull_shape: CollisionShape3D
var _prow_shape: CollisionShape3D
var _shadow: MeshInstance3D
var _shadow_material: StandardMaterial3D
## The team-colour pool of light on the sea under the hull.
var _pool: LightPool


func _ready() -> void:
	add_to_group(&"motherships")
	collision_layer = 1 << 2
	collision_mask = 0
	_hull_shape = _add_shape()
	_prow_shape = _add_shape()
	_make_shadow()
	_pool = LightPool.new()
	_pool.top_level = true
	add_child(_pool)
	MothershipProto.lamp_stats().changed.connect(rebuild)
	stats.changed.connect(rebuild)
	rebuild()


## Puts the mothership with its underside's middle at `at` (world), bow toward -z.
func place(at: Vector3) -> void:
	position = at
	_shadow.global_position = Vector3(at.x, 1.0, at.z)
	_pool.global_position = Vector3(at.x, SEA_POOL_HEIGHT, at.z)


## World position of the model's attachment point `marker_name` (a pad on the deck); the mothership's own position if
## it has none.
func marker_position(marker_name: String) -> Vector3:
	var marker := _model.get_node_or_null(marker_name) as Marker3D if _model != null else null
	return marker.global_position if marker != null else global_position


## Which way is out over the side of the hull toward the middle of the map (x only; the long side faces the atoll).
func side_direction() -> Vector3:
	return Vector3(-signf(global_position.x) if global_position.x != 0.0 else 1.0, 0.0, 0.0)


## A point `margin` metres beyond the hull's side, at the height of `from_y`: a deck pad's gate, or where craft wait.
func side_point(along_z: float, margin: float, from_y: float) -> Vector3:
	return Vector3(global_position.x, from_y, along_z) + side_direction() * (stats.beam * 0.5 + margin)


## Rebuilds the hull, the collision and the shadow from the stats.
func rebuild() -> void:
	if _model != null:
		remove_child(_model)
		_model.queue_free()
	_model = stats.model.instantiate() as MothershipProto
	add_child(_model)
	_model.build(stats, team)
	var prow: float = stats.beam * stats.prow_ratio
	(_hull_shape.shape as BoxShape3D).size = Vector3(stats.beam, stats.hull_height, stats.hull_length)
	_hull_shape.position.y = stats.hull_height * 0.5
	(_prow_shape.shape as BoxShape3D).size = Vector3(stats.beam * 0.5, stats.hull_height, prow)
	_prow_shape.position = Vector3(0.0, stats.hull_height * 0.5, -stats.hull_length * 0.5 - prow * 0.5)
	(_shadow.mesh as PlaneMesh).size = Vector2(stats.beam * 1.8, (stats.hull_length + prow) * 1.15)
	_shadow.position.z = -prow * 0.5
	_shadow_material.albedo_color.a = stats.shadow_strength
	var lamps: LampStats = MothershipProto.lamp_stats()
	_pool.setup(Vector2(stats.beam, stats.hull_length + prow) * lamps.ship_pool_scale,
			UiTokens.team_color(team), lamps.ship_pool)


func _add_shape() -> CollisionShape3D:
	var node := CollisionShape3D.new()
	node.shape = BoxShape3D.new()
	add_child(node)
	return node


## A flat quad with a radial fade, lying just over the sea. Top-level so the hull's tilt or bob never moves it.
func _make_shadow() -> void:
	_shadow = MeshInstance3D.new()
	_shadow.name = "GroundShadow"
	_shadow.top_level = true
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shadow.mesh = PlaneMesh.new()
	var fade := Gradient.new()
	fade.set_color(0, Color(0.0, 0.0, 0.0, 1.0))
	fade.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = fade
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_shadow_material = StandardMaterial3D.new()
	_shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadow_material.albedo_color = Color(1.0, 1.0, 1.0, 0.45)
	_shadow_material.albedo_texture = texture
	_shadow.material_override = _shadow_material
	add_child(_shadow)
