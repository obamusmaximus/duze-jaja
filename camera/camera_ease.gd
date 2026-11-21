class_name CameraEase
## Frame-rate independent easing shared by the camera rig's parts.


## The fraction of the remaining gap to close this frame, for a smoothing `rate` per second. A rate of 0 or less
## means instant.
static func weight(rate: float, delta: float) -> float:
	if rate <= 0.0:
		return 1.0
	return 1.0 - exp(-rate * delta)
