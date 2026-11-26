class_name ExplorerStats
extends Resource
## Tunable numbers for the Explorer, the flying forward base (`units/explorer.gd`, `units/explorer_look.gd`,
## `tuning/explorer_default.tres`; `docs/mechanics/explorer.md`): deploying, the bubble and base area, unloading,
## and its look (searchlights, beacons). A unit type points at one from `UnitStats.explorer`; its hold is
## `UnitStats.cargo`, its flight the usual `UnitStats` flight group, its F the deploy ability (`DeployStats`).

@export_group("Deploy")
## Deployed hover height above the ground, as a share of its cruise height (`UnitStats.flight_height`; 0.5: half).
@export_range(0.1, 1.0, 0.05) var hover_fraction: float = 0.5
## Seconds to sink from cruise to the deployed hover.
@export_range(0.5, 30.0, 0.5) var descent_time: float = 5.0
## Seconds the beam takes to shoot up from the hull before the bubble opens.
@export_range(0.1, 10.0, 0.1) var beam_time: float = 1.2
## Seconds the bubble takes to unfurl from the beam's top down to the ground.
@export_range(0.1, 20.0, 0.1) var bubble_time: float = 3.0
## Seconds the bubble takes to fold away when it packs up.
@export_range(0.1, 20.0, 0.1) var pack_time: float = 2.0
## Seconds to climb back to cruise height after packing up.
@export_range(0.5, 30.0, 0.5) var climb_time: float = 5.0

@export_group("Bubble")
## Radius (metres) of the bubble: 35 makes it 70 m across.
@export_range(5.0, 200.0, 0.5) var bubble_radius: float = 35.0
## Height (metres) of the bubble's centre above the ground where it deployed. Above 0 it is more than a half dome,
## so the hull fits inside; the ground it covers (the base area) shrinks a little.
@export_range(0.0, 100.0, 0.5) var bubble_lift: float = 15.0

@export_group("Unload")
## Seconds between one unit leaving the hold and the next.
@export_range(0.05, 5.0, 0.05) var unload_interval: float = 0.25
## How far out the units are set down, as a share of the base area's radius.
@export_range(0.1, 1.0, 0.05) var unload_spread: float = 0.8

@export_group("Searchlights")
## Searchlights under the hull, sweeping the ground while it flies (off while deployed).
@export_range(0, 6, 1) var searchlight_count: int = 3
## How far (metres) from the point straight below a searchlight's spot wanders.
@export_range(0.0, 200.0, 1.0) var searchlight_reach: float = 45.0
## How fast the spots wander (sweeps per second, roughly).
@export_range(0.01, 2.0, 0.01) var searchlight_sweep: float = 0.12
## Half the cone's opening, in degrees.
@export_range(1.0, 45.0, 0.5) var searchlight_angle_deg: float = 10.0
## Brightness of the light on the ground (it doesn't fade with distance).
@export_range(0.0, 64.0, 0.1) var searchlight_energy: float = 4.0
## How far (metres) the light reaches.
@export_range(10.0, 600.0, 5.0) var searchlight_range: float = 160.0
## Opacity of the visible beam in the air.
@export_range(0.0, 1.0, 0.01) var searchlight_beam_opacity: float = 0.12
## Seconds for the searchlights to go out (deploy) or come on (flying again).
@export_range(0.1, 10.0, 0.1) var searchlight_fade_time: float = 1.5

@export_group("Beacons")
## Size (metres) of a beacon light's glow.
@export_range(0.1, 10.0, 0.1) var beacon_size: float = 2.2
## Seconds between flashes of the orange anti-collision beacons.
@export_range(0.2, 5.0, 0.05) var beacon_period: float = 1.4
## Seconds between double flashes of the white strobes.
@export_range(0.2, 5.0, 0.05) var strobe_period: float = 2.1

@export_group("Bubble look")
## Opacity of the bubble's skin (its rim glows brighter).
@export_range(0.0, 1.0, 0.01) var bubble_opacity: float = 0.08
## Width (metres) of the beam from the hull's top.
@export_range(0.1, 10.0, 0.1) var beam_width: float = 1.6
## How far (metres) the beam reaches above the bubble's top.
@export_range(0.0, 400.0, 5.0) var beam_overshoot: float = 120.0


## The radius of the ground the bubble covers (the base area).
func base_radius() -> float:
	return sqrt(maxf(bubble_radius * bubble_radius - bubble_lift * bubble_lift, 0.0))
