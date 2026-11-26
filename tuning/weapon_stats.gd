class_name WeaponStats
extends Resource
## Tunable numbers for a weapon (combat/). A unit type points at one from its UnitStats `weapon`; weapon variants
## are more .tres files (tuning/weapon_default.tres).

@export_group("Shot")
## Reach, in metres from the unit's edge to the target's edge.
@export_range(0.5, 200.0, 0.5) var max_range: float = 12.0
## Seconds between shots.
@export_range(0.05, 20.0, 0.05) var cooldown: float = 1.0
## What a hit does to each armor type. None: `DamageProfile.FALLBACK` to everything.
@export var damage_profile: DamageProfile
## Fire only at targets within this angle of where the unit faces, in degrees either side (180 fires all round).
## Units turn to face what they fight when standing; moving units fire only at what is ahead.
@export_range(1.0, 180.0, 1.0) var fire_arc_deg: float = 30.0

@export_group("Projectile")
## On: the shot flies to its target and hits on arrival (homing). Off: the shot hits at once (a tracer shows it).
@export var projectile: bool = true
## Flight speed of the projectile, in metres per second.
@export_range(1.0, 300.0, 1.0) var projectile_speed: float = 40.0

@export_group("Beam")
## Drawn as a laser beam instead of a thin tracer. Instant weapons only.
@export var beam: bool = false
## Width of the drawn beam, in metres.
@export_range(0.02, 2.0, 0.01) var beam_width: float = 0.16
## How long a beam stays on screen, fading, in seconds.
@export_range(0.02, 1.0, 0.01) var beam_seconds: float = 0.18

@export_group("First person")
## A player flying the unit fires it by hand (left mouse) and can lock targets (R). Off: it is silent in first person.
@export var pilot_fire: bool = false
## First person: how far the beam reaches, metres. `max_range` is only the reach of the unit fighting on its own.
@export_range(10.0, 1000.0, 5.0) var pilot_range: float = 150.0
## First person: a target can be locked, and stays locked, within this distance, metres.
@export_range(10.0, 1000.0, 5.0) var lock_range: float = 150.0
## First person: R locks the enemy nearest the crosshair within this angle of it, degrees.
@export_range(1.0, 90.0, 1.0) var lock_pick_deg: float = 30.0
## First person: the beam bends onto a locked target within this angle of where the weapon points (the boresight, or
## the view for a turret), degrees. Outside it the beam fires straight.
@export_range(0.0, 90.0, 1.0) var lock_fire_deg: float = 30.0

@export_group("Sound and effects")
## Shows a muzzle flash where it fires. Off for a weapon fired from a first-person view (the flash would cover it).
@export var muzzle_flash: bool = true
## Sound cue played at the muzzle when it fires (a `SfxCue` id, see tuning/sfx_library.tres). Empty: silent.
@export var fire_cue: StringName = &"laser_small"
## Sound cue played where a shot lands.
@export var hit_cue: StringName = &"hit_spark"
## Size of the muzzle flash and impact sparks, as a multiple of the normal size.
@export_range(0.2, 4.0, 0.05) var effect_scale: float = 1.0
