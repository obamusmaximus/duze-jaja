# Units and teams

Units as simulation objects: identity, parts, movement. Design: `GAME_DESIGN.md` ("Views", "Multiplayer and simulation"). Tunables: `UnitStats` (`tuning/unit_default.tres`, Units tab). Orders: `orders.md`.

**Scripts:** `debug/benchmark/benchmark.gd` (standing benchmark), `units/unit.gd` (+ `unit.tscn`), `unit_registry.gd`, `unit_brain.gd`, `order_brain.gd`, `unit_look.gd`. Movement, navigator and the spatial hash: `pathing.md`. Health, weapon, targeting: `combat.md`.

## How it works
- **`Unit`** (`CharacterBody3D`, layer 2, masks 1 and 3: units never collide with each other, see `pathing.md`) only holds its parts (look, movement, navigator, order queue, brain, targeting, weapon, health) and identity: `id`, `team`, `stats`, `alive`. It has no `_physics_process`: the registry calls `think(delta)` (targeting, `movement.decide`, weapon) and `movement.integrate`. A **unit type** is a `UnitStats` `.tres`: units sharing one are the same type. Groups: `units`, `team_<n>`. Signals: `died`, `selected_changed`. `center()` is the body's middle (screen projection, later aiming).
- **`UnitRegistry`** (the level's `Units` node) is the parent of every unit. It gives each a stable **unit id** (from 1, never reused in a match), looks living units up by id (`get_unit`) and by place (`units_near`), and hands units the match services (`map`, `paths`, `shots`). The level calls `setup(map, paths, shots)` once the map is built, which registers the units placed as its children in child order; spawners use `add(unit)` with `team` set first. Registering calls `Unit.setup(id, registry)`, which wires the parts.
- **The tick:** `UnitRegistry._physics_process` is the one loop. Half the units think each tick (by id parity) with twice the delta; every unit integrates (turns and moves by what it last decided) every tick, so physics interpolation stays smooth. `Unit.full_rate` makes a unit think every tick (for the inhabited unit later). Timers and cooldowns just see the doubled delta.
- **Kinematic movement:** ground units are moved by setting their position: height from `MapGrid.surface_height` (blended between cell centres), a move into a blocked cell is refused and slides along it, and a unit standing in a cell that became blocked is moved to the nearest walkable one on its next rest check. The `CharacterBody3D` and its shape stay for queries only. `UnitMovement.physical = true` brings back `move_and_slide` with gravity for direct control (not wired to anything yet).
- **Ids, not nodes:** `Selection` and `ControlGroups` hold unit ids (`Selection.units` resolves them); `UnitTargeting.in_range`/`in_sight`, `Weapon.target` and the attack-move engaged target store ids behind properties that resolve through `Unit.registry`.
- **Brain:** `UnitMovement` asks its **brain** each tick for a velocity (`wanted_velocity(delta)`) and, while standing, a facing (`wanted_facing()`). `OrderBrain` (behaviour by order, `combat.md`) drives units now; `set_brain()` swaps in another (direct control later).
- **Look** (`UnitLook`, visual only): the type's `model` (UnitStats "Look") over a flat team-colour base plate, or with no model a placeholder hull cylinder on the plate with a livery nose showing the facing (colours from `WorldMaterials`); plus the selection ring. Models: `props.md`. Built from `radius`, `height` and rebuilt on `changed`, as is the collision shape (local to each unit).
- **Sandbox:** six team 0 units and four team 1 units under `Units`, plus a Hornet (flyer) per team.
- **Flyers** (`UnitStats` "Flight": `flying`, `flight_height`, `flight_terrain_follow`, `flight_min_clearance`, `flight_climb_rate`): no gravity and no walls (collision mask 0). Each tick `UnitMovement._fly` climbs or descends toward `altitude_for(ground)`: `max(ground + min clearance, flight_height + terrain_follow × ground)`, where ground is `MapGrid.ground_height` (the cell's height, at least sea level). Terrain lifts a flyer less than it lifts the ground, so it sits closer to hills than to the sea. Flyers take a straight path (`UnitNavigator` skips the grid), separate only from other flyers, and show their team plate and ring on the ground beneath (`UnitLook.set_hover`).
- **Anti-air:** `UnitStats.anti_air` (Combat). `Unit.can_attack(other)` is the one rule: an enemy, and in the air only if anti-air. Targeting, attack orders (refused for ground units, the rest of a selection still goes) and the attack brain all use it. Units that aren't anti-air never pick a flyer. (In first person, most weapons will hit air; not built.)

## Settled

## Tried and passed on

## Known issues
- `sight_range` is only a notice range for attack-move; there is no fog of war.
- Flyers collide with nothing (mask 0; they are kinematic now too), so they pass over walls, buildings and the debug wall. No air collision layer yet; the physics layers in `project.godot` are unchanged.
