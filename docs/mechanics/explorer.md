# Explorer (flying forward base)

A huge, slow flying ship that carries an army and, on F, deploys as a forward base: it sinks to a low hover, raises an energy bubble and sets its hold down inside; the bubble's ground becomes a base area. Build order: `docs/plans/explorer.md`. Tunables: `ExplorerStats` (`tuning/explorer_default.tres`, Units tab), `DeployStats` (`tuning/ability_deploy_explorer.tres`), the unit type `tuning/unit_explorer.tres` (flight group, size, model) and its hold `tuning/cargo_explorer.tres`.

**Scripts:** `units/explorer.gd` (behaviour, simulation), `units/explorer_look.gd` (+ `explorer_bubble.gdshader`, `explorer_beam.gdshader`, `explorer_beacon.gdshader`), `tuning/explorer_stats.gd`, `tuning/deploy_stats.gd`; hooks in `units/unit.gd` (`Unit.explorer`), `order_brain.gd` (holds it still), `unit_look.gd` (`add_explorer`), `pilot_seats.gd` (not inhabitable), `levels/atoll/atoll_level.gd` (test Explorers).

## How it works
- **A type with `UnitStats.explorer`** gets an `Explorer` (`RefCounted`, stepped from `Unit.think`) on `Unit.explorer`. It is a hover flyer on the air layer like the carryall, as slow, with a hold (`cargo.md`) of 40.
- **Deploy (F, `DeployStats`):** clears its orders and sinks over `descent_time` to `hover_fraction` of its `flight_height` above the ground under it (`altitude_override`, eased). It may still be coasting or high up (just left by a pilot): the spot follows it until it has come to rest at the hover height, which from high up takes longer than `descent_time` (it sinks no faster than its climb rate). Then the beam shoots up from the top of the hull (`beam_time`) and the bubble unfurls from the top down (`bubble_time`). The base area opens when the descent ends. Then it unloads: one unit every `unload_interval`, on a sunflower spread over `unload_spread` of the base area (snapped to walkable cells; flyers leave at the hull's height). A ground unit with no walkable ground near its spot stays aboard. States: `FLYING`, `DESCENDING`, `RAISING`, `UNLOADING`, `DEPLOYED`, `PACKING`, `CLIMBING`.
- **Pack up:** F again (once the bubble is raising or up), or any order that would move it (it is then carried out once it flies): the bubble folds (`pack_time`), it climbs back to cruise (`climb_time`) and flies on. An order during the descent turns it straight round. Unloaded units stay. F does nothing while it sinks, folds or climbs (`AbilityStats.can_use`).
- **Piloted:** with hover controls (`flight_model.md`) while flying; it can't be entered while deploying, deployed or packing up, and F does not deploy from the cockpit.
- **Held still:** while `anchored()` (any state but `FLYING`) the `OrderBrain` returns no velocity, and other flyers' separation doesn't push it (they still make way for it).
- **Bubble and base area:** a sphere of `bubble_radius` whose centre is `bubble_lift` above the ground where it deployed, so the hull fits inside; the ground it covers is a circle of `ExplorerStats.base_radius()`. `Explorer.is_base()`, `covers(point)`, `base_center()`, signal `base_changed(open)`; `Explorer.base_at(tree, team, point)` finds a team's open base area at a point (group `base_areas`). Nothing uses it yet; the bubble blocks no shots or units.
- **Look (`ExplorerLook`, view only):** the type's model is the Space Kit's `craft_cargoB` at `model_scale` 22 (about 33 by 55 m, 20 m tall: its bay would hold four carryalls). Lights hang on the hull's surface (the model vertex farthest in a set direction). `searchlight_count` searchlights under the hull wander over the ground below on slow sums of sines (each keeps to its own side), each a `SpotLight3D` with no distance fall-off and no shadow plus a faint additive cone; they fade out while it is deployed. Beacons: orange blinkers on top, bottom and corners, white double-flash strobes at the wingtips, nose and tail (camera-facing glow quads). The beam and bubble are in the team colour; the bubble's front glows as it unfurls.
- **F in the RTS view:** `OrderControl` sends `Order.ability` for the selection's main units (`rts_controls.md`).
- **Test Explorers:** `BattlefieldStats.test_explorers` per team on the atoll, each carrying 20 troopers, 4 IFVs, a tank and a VTOL.

## Settled
- The hold is one shared volume (`cargo.md`); the HUD shows a card per type aboard.
- Deployed height is a share of the cruise height above the ground, not of the terrain-following altitude, so it is the same over hills.

## Tried and passed on

## Known issues
- Units unloaded from it are not loaded back: no walking in, no carryalls docking with it, not built by production yet.
- Flyers unloaded snap to their cruise height at once (the autopilot's spawn snap) instead of climbing out.
- Deploying over open sea leaves ground units aboard if no land is within the walkable search of their spots.
- The searchlight pools only read at night (no night `LightStats` preset yet); in daylight only the cones show faintly.
- The team plate under it is the usual square, 44 m wide; it reads heavy from the ground.
