class_name FlightModeStats
extends AbilityStats
## The VTOL's F in the cockpit: switch between the hover and the jet control type
## (tuning/ability_flight_mode_vtol.tres). It needs a type with both `UnitStats.hover_flight` and `flight_model`, and
## does nothing outside the cockpit (the autopilot flies only one way).


func can_use(unit: Unit) -> bool:
	var flight: PilotFlight = unit.pilot_flight()
	return flight != null and flight.can_switch()


func start(unit: Unit, _point: Vector3, _target_id: int) -> void:
	var flight: PilotFlight = unit.pilot_flight()
	if flight != null:
		flight.switch_mode()
