class_name DeployStats
extends AbilityStats
## The deploy ability (F) of the Explorer and the carryall. Explorer: deploy (sink to a low hover, raise the bubble,
## unload, become a base area), or pack up again when deployed (`units/explorer.gd`). Carryall: land where it is,
## unload and fly back to a mothership pad (`units/carryall.gd`). The steps and timings are the unit's own stats; this
## only starts them. `tuning/ability_deploy_explorer.tres`, `tuning/ability_deploy_carryall.tres`.


func can_use(unit: Unit) -> bool:
	if unit.explorer != null:
		return unit.explorer.can_toggle()
	return unit.carryall != null and unit.carryall.can_deploy()


## The autopilot flies it, also when a player is at the controls.
func needs_autopilot() -> bool:
	return true


func start(unit: Unit, _point: Vector3, _target_id: int) -> void:
	if unit.explorer != null:
		unit.explorer.toggle()
	elif unit.carryall != null:
		unit.carryall.deploy()
