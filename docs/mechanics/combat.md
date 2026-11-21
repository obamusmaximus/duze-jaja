# Combat

Health, weapons, target finding, shots and how units fight under each order. Tunables: `WeaponStats` (`tuning/weapon_default.tres`), `UnitStats` "Combat" (`max_health`, `weapon`, `sight_range`, `leash_distance`, `scan_interval`), both on the Units tab.

**Scripts:** `combat/health.gd`, `weapon.gd`, `unit_targeting.gd`, `shots.gd`, `shot_view.gd`, `health_bars.gd`; `units/order_brain.gd` (behaviour by order).

## How it works
- **`Health`:** `current`, `damage(amount, source_id)`, signals `damaged` and `died(killer_id)`; `Unit.die()` sets `alive = false`, turns off its collision, emits `died` and frees the unit at the end of the frame. Everything that holds units checks `alive`. `incoming` is damage from projectiles in flight; `is_doomed()` when it covers the remaining health.
- **`UnitTargeting`:** a full search every `scan_interval`, staggered by unit id; between searches it only checks the current picks and drops them, searching on the next tick, when they die or leave range. Being hit by a unit other than the current target also triggers a search. `in_range` is the best enemy in weapon range: the last attacker first (return fire), then enemies not already doomed (no overkill), nearest first. `in_sight` is the nearest enemy within `sight_range`.
- **`Weapon`:** fires at the brain's `target` when it is in range (`max_range`, edge to edge), within `fire_arc_deg` of the unit's facing, and the `cooldown` is ready. A unit with no `weapon` stats never fires.
- **`Shots`:** every shot in the match as packed arrays, with no nodes or physics bodies. Instant shots hit at once and emit `fired` for tracers. Projectiles home on their target at `projectile_speed` and hit on arrival, or vanish where the target was if it died. Removal swaps in the last shot.
- **Behaviour by order (`OrderBrain`):**
  - Move: goes there and fires only at enemies that happen to be in its arc. It never stops or turns for them.
  - Attack: chases (navigator `follow`) into range, stands, faces the target and fires; done when the target is gone.
  - Attack-move: fights anything within `sight_range`, chasing at most `leash_distance` from where the fight began. An enemy it gave up on is ignored unless it comes into range. Then it carries on to the point.
  - Idle: holds its ground, faces and fires at `in_range`.
  - Stop: clears the queue, leaving the unit idle.
- **Views:** `ShotView` draws projectiles with one MultiMesh and tracers with one ImmediateMesh. `HealthBars` (in `RtsPlayer`) draws every damaged or selected unit's bar from one Control.
- **Probe events:** `attack` (Shots: a unit opens fire on a new target), `death` (UnitRegistry: unit, team, killer).

## Settled
- Headless: 5 attack-moving units against 5 idle ones resolve in about 13 s; the idle side returns fire; the survivors carry on to the goal. A unit leashed off a fleeing enemy finishes its move.

## Tried and passed on

## Known issues
- No force-fire (Ctrl+click), no turrets (fire arc only), no armour types or splash.
- Projectiles always hit (homing); there is no dodging or missing.
- Dead units vanish at once: no death effect or wreck.
