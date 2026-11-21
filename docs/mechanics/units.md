# Units and teams

Units as simulation objects: identity, parts, movement. Design: `GAME_DESIGN.md` ("Views", "Multiplayer and simulation"). Tunables: `UnitStats` (`tuning/unit_default.tres`, Units tab). Orders: `orders.md`.

**Scripts:** `units/unit.gd` (+ `unit.tscn`), `unit_registry.gd`, `unit_brain.gd`, `order_brain.gd`, `unit_look.gd`. Movement, navigator and the spatial hash: `pathing.md`. Health, weapon, targeting: `combat.md`.

## How it works
- **`Unit`** (`CharacterBody3D`, layer 2, masks 1 and 3: units never collide with each other, see `pathing.md`) only holds its parts (look, movement, navigator, order queue, brain, targeting, weapon, health) and identity: `id`, `team`, `stats`, `alive`. Each tick it runs targeting, movement (which asks the brain), then the weapon. A **unit type** is a `UnitStats` `.tres`: units sharing one are the same type. Groups: `units`, `team_<n>`. Signals: `died`, `selected_changed`. `center()` is the body's middle (screen projection, later aiming).
- **`UnitRegistry`** (the level's `Units` node) is the parent of every unit. It gives each a stable **unit id** (from 1, never reused in a match), looks living units up by id (`get_unit`) and by place (`units_near`), and hands units the match services (`map`, `paths`, `shots`). The level calls `setup(map, paths, shots)` once the map is built, which registers the units placed as its children in child order; spawners use `add(unit)` with `team` set first. Registering calls `Unit.setup(id, registry)`, which wires the parts.
- **Brain:** `UnitMovement` asks its **brain** each tick for a velocity (`wanted_velocity(delta)`) and, while standing, a facing (`wanted_facing()`). `OrderBrain` (behaviour by order, `combat.md`) drives units now; `set_brain()` swaps in another (direct control later).
- **Look** (`UnitLook`, visual only): placeholder cylinder in the team colour, a nose showing the facing, the selection ring. Built from `radius`, `height` and rebuilt on `changed`, as is the collision shape (local to each unit).
- **Sandbox:** six team 0 units and four team 1 units under `Units`.

## Settled

## Tried and passed on

## Known issues
- `sight_range` is only a notice range for attack-move; there is no fog of war.
