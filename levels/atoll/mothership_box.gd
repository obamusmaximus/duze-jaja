class_name MothershipBox
extends Node3D
## Placeholder for a hovering mothership on the scale reference level: a hull box and a team-colour stripe on top,
## floating at `mothership_altitude` with nothing under it. Visual only (no collision, no map grid footprint); step 6
## of `docs/plans/battlefield.md` replaces it with the real `Mothership`.

## The team the mothership belongs to.
@export var team: int = 0
@export var stats: BattlefieldStats


func _ready() -> void:
	add_to_group(&"mothership_boxes")
	refresh()


## Rebuilds the box from the stats, at its side of the map (team 0 west, team 1 east).
func refresh() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var side: float = -1.0 if team == 0 else 1.0
	position = Vector3(side * stats.mothership_standoff, stats.mothership_altitude + stats.mothership_size.y * 0.5, 0.0)
	var hull := MeshInstance3D.new()
	var body := BoxMesh.new()
	body.size = stats.mothership_size
	body.material = WorldMaterials.role(WorldMaterials.Role.HULL_MID)
	hull.mesh = body
	add_child(hull)
	var stripe := MeshInstance3D.new()
	var strip := BoxMesh.new()
	strip.size = Vector3(stats.mothership_size.x * 0.8, 1.0, stats.mothership_size.z * 0.2)
	strip.material = WorldMaterials.role(WorldMaterials.Role.LIVERY, team)
	stripe.mesh = strip
	stripe.position.y = stats.mothership_size.y * 0.5 + 0.5
	add_child(stripe)
