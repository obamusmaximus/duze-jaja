# Orders

How players and AI change the game. Design: `GAME_DESIGN.md` ("Multiplayer and simulation"). Tunables: `OrderStats` (`tuning/order_default.tres`, Units tab). How units carry orders out (movement, fighting): `pathing.md`, `combat.md`. The clicks that make orders: `rts_controls.md`.

**Scripts:** `orders/order.gd`, `command_issuer.gd`, `formation.gd`, `order_queue.gd`.

## How it works
- **`Order`** is plain data: `kind` (move, attack, attack-move, stop), issuing `team`, `unit_ids`, `target_position` or `target_unit_id`, `queued`. Never node references, so it can go over the network and into saves. Build one with `Order.move/attack/attack_move/stop()`.
- **`CommandIssuer.issue(order)`** is the only way in (views, AI, later the network). It keeps only the issuing team's units (refuses the order if none are left, or if an attack target is missing or friendly), spreads move and attack-move into a **group move** (`Formation.slots`), and gives each unit its own copy (`for_unit`): replacing its queue, or appended when `queued` (a **waypoint**). Stop clears queues. Emits `issued` and the probe event `order` (kind, target, unit count).
- **Group move (`Formation`):** a loose block around the clicked point, rows across the travel direction (group centre to the point), spaced by the largest unit diameter times `formation_spacing`. The units nearest the goal take the front row, sorted left to right in each row, so paths cross little.
- **`OrderQueue`** (each unit) is the plain list of its orders, the first active; the unit's `OrderBrain` works through it (`combat.md`, "Behaviour by order") and calls `finish()` when an order is done.

## Settled

## Tried and passed on

## Known issues
- Force-fire (Ctrl+click) isn't built.
- Formation slots that land on blocked ground snap to the nearest walkable cell, so two units can share a spot (the crowd arrival rule settles them).
