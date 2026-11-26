class_name DeployStats
extends AbilityStats
## The Explorer's F: deploy (sink to a low hover, raise the bubble, unload, become a base area), or pack up again
## when deployed. The steps and their timings are the unit's `ExplorerStats` (`units/explorer.gd`); this only starts
## them. `tuning/ability_deploy_explorer.tres`.


func can_use(unit: Unit) -> bool:
	# Not from the cockpit: the deploy is flown by the autopilot.
	return unit.explorer != null and unit.explorer.can_toggle() and unit.pilot_flight() == null


func start(unit: Unit, _point: Vector3, _target_id: int) -> void:
	if unit.explorer != null:
		unit.explorer.toggle()
