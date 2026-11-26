# Combat

Health, damage and armor, weapons, target finding, shots, how units fight under each order and the pilot's hand-fired weapon. Tunables, all on the Units tab: `WeaponStats` (`tuning/weapon_*.tres`), `DamageProfile` (`tuning/damage_*.tres`), `UnitStats` "Combat" (`max_health`, `armor`, `weapon`, `sight_range`, `leash_distance`, `scan_interval`, `aim_tilt_deg`, `pilot_turret`).

**Scripts:** `tuning/damage_profile.gd`; `combat/health.gd`, `weapon.gd`, `pilot_weapon.gd`, `unit_targeting.gd`, `shots.gd`, `shot_view.gd`, `health_bars.gd`; `units/order_brain.gd` (behaviour by order), `units/attack_run.gd` (fixed-wing passes).

## How it works
- **Damage and armor:** every type has the same hit points; toughness is its **armor type** (`UnitStats.ArmorType`: infantry, light vehicle (the rover), vehicle, tank, aircraft, carryall, Explorer). A weapon's **weapon type** is its `damage_profile`, a `DamageProfile` with one number per armor type, each starting at `DamageProfile.FALLBACK`; no profile does the fallback to everything. `Shots.damage_of` is the one lookup. Weapon types: rifle (`damage_rifle`, `weapon_default`), beam (`damage_beam`, `weapon_beam`), the commando's gun and seeker pellets (`damage_commando`, `damage_seeker`; `commando.md`); the rover and skiff guns have no profile. A new armor type needs an enum entry and a `DamageProfile` number.
- **Beam** (`weapon_beam`, fighter and VTOL): instant, one beam per `cooldown`. On their own, units fire it like any instant weapon (`max_range`, fire arc), with no aiming needed. A hover type with `aim_tilt_deg` standing to fight also tilts its nose onto the target when that is within the angle of level (`FlightAutopilot.tilt_toward`; look only, it fires either way).
- **Pilot's weapon** (`PilotWeapon`, on `PilotFlight.weapon`, stepped every tick; types whose weapon has `pilot_fire`): fires while `PilotInput.fire` is held, on the unit's `Weapon` cooldown. It points along the boresight, or along `PilotInput.view` for a `pilot_turret` type (VTOL). **Lock** (`PilotInput.lock`, on the press): the visible enemy nearest the view within `lock_pick_deg` and `lock_range`, air or ground; none in the cone unlocks. A lock holds until the unit dies or passes `lock_range`. With the locked target within `lock_fire_deg` of the weapon's axis (and within `pilot_range`) the beam hits it; otherwise it goes straight to `pilot_range` and hits the first unit, ground, building or the sea. Own units stop it unharmed; ground and buildings block lock and beam. It is sighted from the pilot's eyes and drawn from the nose.
- **`Health`:** `current`, `damage(amount, source_id)`, signals `damaged` and `died(killer_id)`; `Unit.die()` sets `alive = false`, turns off its collision, emits `died` and frees the unit at the end of the frame. Everything that holds units checks `alive`. `incoming` is damage from projectiles in flight; `is_doomed()` when it covers the remaining health.
- **Only known enemies** are targeted, returned fire on or locked (awareness, `vision.md`).
- **`UnitTargeting`:** a full search every `scan_interval`, staggered by unit id; between searches it only checks the current picks and drops them, searching on the next tick, when they die or leave range. Being hit by a unit other than the current target also triggers a search. `in_range` is the best enemy in weapon range: the last attacker first (return fire), then enemies not already doomed (no overkill), nearest first. `in_sight` is the nearest enemy within `sight_range`.
- **`Weapon`:** on its own, fires at the brain's `target` when it is in range (`max_range`, edge to edge), within `fire_arc_deg` of the unit's facing, and the `cooldown` is ready. A unit with no `weapon` stats never fires.
- **`Shots`:** every shot in the match as packed arrays, with no nodes or physics bodies. Instant shots hit at once and emit `fired` for tracers and beams (`fire_beam` is the hand-aimed one). Projectiles home on their target at `projectile_speed` and hit on arrival, or vanish where the target was if it died. Removal swaps in the last shot.
- **Behaviour by order (`OrderBrain`):**
  - Move: goes there and fires only at enemies that happen to be in its arc. It never stops or turns for them.
  - Attack: chases (navigator `follow`) into range, stands, faces the target and fires; done when the target is gone.
  - Attack-move: fights anything within `sight_range`, chasing at most `leash_distance` from where the fight began. An enemy it gave up on is ignored unless it comes into range. Then it carries on to the point.
  - Idle: holds its ground, faces and fires at `in_range`.
  - Fixed-wing flyers (`units.md`) can't stand: fighting (attack or attack-move), they make **attack passes** (`AttackRun`): run in, firing when the target is in range and arc; break off within `flight_pass_break_distance` (or once past it in weapon reach); fly straight out to `flight_pass_distance`; come round again. At the map edge the way out swings back inside. Their attack-move leash measures how far the **enemy** is from where the fight began, since the passes swing wide. Idle, they keep circling and fire only at what crosses their arc. Hover flyers (VTOL) stop in range and fire.
  - Stop: clears the queue, leaving the unit idle.
- **Views:** `ShotView` draws projectiles with one MultiMesh, tracers with one ImmediateMesh and beams with another (camera-facing ribbons, narrowed near the camera, the near end riding the shooter). `HealthBars` (in `RtsPlayer`) draws every damaged or selected unit's bar from one Control.
- **`WeaponStats.muzzle_flash`** off leaves out the flash (a weapon fired from a first-person view). `Shots.strike` delivers a hit from something that flies on its own (seeker pellets).
- **Signals for views:** `Shots.shot_fired(from, weapon)` and `shot_hit(at, weapon)` (every shot, instant or projectile) feed sound and particles (`audio.md`); `WeaponStats` names the cues and effect size.
- **Probe events:** `attack` (Shots: a unit opens fire on a new target), `death` (UnitRegistry: unit, team, killer).

## Settled
- Headless on the atoll: rifle, beam and fallback damage match the armor types; an RTS VTOL pitches about 25 degrees down onto a ground target while it fires; piloted, both flyers lock, fire once per cooldown and unlock on empty sky.
- Headless (a fighter on one tough ground target, 40 s): 6 passes, about 5 hits each, never farther out than `flight_pass_distance` plus the turn; a VTOL hovers in place and fires. A target at the map edge is still hit.
- Headless: 5 attack-moving units against 5 idle ones resolve in about 13 s; the idle side returns fire; the survivors carry on to the goal. A unit leashed off a fleeing enemy finishes its move.

## Tried and passed on

## Known issues
- No force-fire (Ctrl+click), no turrets on autonomous units (fire arc only), no splash.
- An unlocked beam needs an exact hit: at long range infantry is a very small target. There is no aim assist.
- `incoming` and target choice ignore how much a weapon does to a target's armor.
- Air: a flyer is a target only for units flagged `anti_air` (`UnitStats` "Combat"). Everything else ignores it (`Unit.can_attack`). Weapons themselves don't filter by air; the pilot's beam hits anything.
- Projectiles always hit (homing); there is no dodging or missing.
- Dead units vanish at once, with an explosion effect and sound (`audio.md`) but no wreck.
