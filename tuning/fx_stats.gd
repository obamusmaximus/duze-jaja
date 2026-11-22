class_name FxStats
extends Resource
## Tunable numbers for the combat particle effects (fx/): muzzle flashes, impact sparks and death explosions. Counts
## and times are per effect; sizes are metres at effect scale 1 (a weapon's or unit type's `effect_scale` multiplies).

@export_group("Muzzle flash")
## Particles per flash.
@export_range(1, 32, 1) var flash_count: int = 5
## Seconds a flash lasts.
@export_range(0.02, 0.5, 0.01) var flash_seconds: float = 0.09
## Size of a flash particle, in metres.
@export_range(0.05, 2.0, 0.05) var flash_size: float = 0.45

@export_group("Impact sparks")
## Sparks per impact.
@export_range(1, 64, 1) var spark_count: int = 10
## Seconds a spark lives.
@export_range(0.05, 2.0, 0.05) var spark_seconds: float = 0.35
## Top speed of a spark, in metres per second.
@export_range(1.0, 30.0, 0.5) var spark_speed: float = 7.0
## Size of a spark, in metres.
@export_range(0.02, 0.6, 0.01) var spark_size: float = 0.14

@export_group("Death explosion")
## Fireball particles.
@export_range(1, 64, 1) var fire_count: int = 8
## Seconds the fireball lasts.
@export_range(0.1, 3.0, 0.05) var fire_seconds: float = 0.55
## Fireball particle size at its biggest, in metres.
@export_range(0.2, 8.0, 0.1) var fire_size: float = 2.4
## Debris chunks thrown out.
@export_range(0, 64, 1) var debris_count: int = 14
## Top speed of debris, in metres per second.
@export_range(1.0, 30.0, 0.5) var debris_speed: float = 9.0
## Seconds debris flies.
@export_range(0.2, 4.0, 0.1) var debris_seconds: float = 1.1
## Smoke puffs left behind.
@export_range(0, 32, 1) var smoke_count: int = 6
## Seconds the smoke lingers.
@export_range(0.2, 6.0, 0.1) var smoke_seconds: float = 1.8
## Smoke puff size at its biggest, in metres.
@export_range(0.2, 10.0, 0.1) var smoke_size: float = 2.8

@export_group("Pools")
## Flashes and impacts that can show at once (the oldest is reused).
@export_range(4, 128, 1) var small_pool: int = 32
## Death explosions that can show at once.
@export_range(2, 32, 1) var death_pool: int = 10
