class_name CaptureMarker
extends Node3D
## Debug: a capture point's place on the blockout, drawn as a thin ring and a post standing on the ground. Marker only:
## no capture mechanic yet (`docs/plans/battlefield.md`, step 5).

const RING_RADIUS: float = 12.0
const POST_HEIGHT: float = 14.0


func _ready() -> void:
	add_to_group(&"capture_markers")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.1)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RING_RADIUS - 0.6
	torus.outer_radius = RING_RADIUS
	torus.rings = 24
	torus.ring_segments = 4
	torus.material = material
	ring.mesh = torus
	ring.position.y = 0.4
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	var post := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.4
	cylinder.bottom_radius = 0.4
	cylinder.height = POST_HEIGHT
	cylinder.material = material
	post.mesh = cylinder
	post.position.y = POST_HEIGHT * 0.5
	post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(post)
