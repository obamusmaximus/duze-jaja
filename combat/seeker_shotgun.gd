class_name SeekerShotgun
extends RefCounted
## The commando's first-person weapon (`docs/mechanics/commando.md`): each press of the trigger sends `pellet_count`
## pellets in a cone at what the crosshair points at. Each pellet is given one of the tracked enemies (`JetTracking`),
## newest pickup first and round again. No fuel cost; locked out while the afterburner burns. Held by `PilotFlight`,
## stepped every tick. The pellets fly in `SeekerPellets`. Simulation.

## What the crosshair can point at: the World, Unit and Building layers.
const AIM_MASK: int = (1 << 0) | (1 << 1) | (1 << 2)

var stats: SeekerShotgunStats
var pellets: SeekerPellets

var _unit: Unit
var _tracking: JetTracking
## The trigger as of the last tick: a shot is a press.
var _fire_held: bool = false
var _refire: float = 0.0


func _init(unit: Unit, shotgun_stats: SeekerShotgunStats, tracking: JetTracking) -> void:
	_unit = unit
	stats = shotgun_stats
	_tracking = tracking
	pellets = SeekerPellets.new(unit, shotgun_stats)


## One tick. `eye` and `view` are the pilot's eyes and view; `can_fire` is false under the afterburner.
func step(delta: float, input: PilotInput, eye: Vector3, view: Basis, can_fire: bool) -> void:
	_refire = maxf(_refire - delta, 0.0)
	if input.fire and not _fire_held and can_fire and _refire <= 0.0:
		_fire(eye, view)
	_fire_held = input.fire
	pellets.step(delta)


func _fire(eye: Vector3, view: Basis) -> void:
	_refire = stats.refire_time
	var muzzle: Vector3 = eye + view * stats.muzzle_offset
	var aim: Vector3 = muzzle.direction_to(_aim_point(eye, -view.z))
	var targets: Array[Unit] = _tracking.targets()
	targets.reverse() # Newest pickup first.
	for i: int in stats.pellet_count:
		var target_id: int = targets[i % targets.size()].id if not targets.is_empty() else 0
		pellets.spawn(muzzle, _spread(aim) * stats.speed, target_id)
	_unit.registry.shots.shot_fired.emit(muzzle, stats.weapon, _unit)


## What the crosshair points at within `aim_range`, or the point that far along the view (the sea's surface stops it).
func _aim_point(eye: Vector3, forward: Vector3) -> Vector3:
	var far: Vector3 = eye + forward * stats.aim_range
	if far.y < MapGrid.SEA_LEVEL and eye.y > MapGrid.SEA_LEVEL:
		far = eye.lerp(far, (eye.y - MapGrid.SEA_LEVEL) / (eye.y - far.y))
	var query := PhysicsRayQueryParameters3D.create(eye, far, AIM_MASK, [_unit.get_rid()])
	var hit: Dictionary = _unit.get_world_3d().direct_space_state.intersect_ray(query)
	return hit["position"] if not hit.is_empty() else far


## A direction within `spread_degrees` of `forward`, spread evenly over the cone's disc.
func _spread(forward: Vector3) -> Vector3:
	var side: Vector3 = forward.cross(Vector3.UP if absf(forward.y) < 0.99 else Vector3.RIGHT).normalized()
	var up: Vector3 = side.cross(forward)
	var radius: float = tan(deg_to_rad(stats.spread_degrees)) * sqrt(randf())
	var angle: float = randf() * TAU
	return (forward + (side * cos(angle) + up * sin(angle)) * radius).normalized()
