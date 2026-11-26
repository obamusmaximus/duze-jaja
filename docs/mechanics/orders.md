# Orders

How players and AI change the game. Design: `GAME_DESIGN.md` ("Multiplayer and simulation"). Tunables: `OrderStats` (`tuning/order_default.tres`, Units tab). How units carry orders out (movement, fighting): `pathing.md`, `combat.md`. The clicks that make orders: `rts_controls.md`.

**Scripts:** `orders/map_marker.gd`, `map_markers.gd`, `orders/order.gd`, `command_issuer.gd`, `formation.gd`, `order_queue.gd`, `pilot_input.gd`.

## How it works
- **`Order`** is plain data: `kind` (move, attack, attack-move, stop), issuing `team`, `unit_ids`, `target_position` or `target_unit_id`, `queued`. Never node references, so it can go over the network and into saves. Build one with `Order.move/attack/attack_move/stop()`.
- **`CommandIssuer.issue(order)`** is the only way in (views, AI, later the network). It keeps only the issuing team's units (refuses the order if none are left, or if an attack target is missing, friendly or unknown to the team, `vision.md`), spreads move and attack-move into a **group move** (`Formation.slots`; flyers and ground units form up apart, and flyers' slots are kept inside the map), and gives each unit its own copy (`for_unit`): replacing its queue, or appended when `queued` (a **waypoint**). Stop clears queues. Emits `issued` and the probe event `order` (kind, target, unit count).
- **Map markers (10c-4):** `Order.place_marker(team, kind, point)` and `Order.clear_marker(team, id)` carry no units; the issuer hands them to `MapMarkers` (group `map_markers`, `issuer.markers`), a plain-data board per team of `MapMarker` (id, kind, team, position). Kinds: attack, guard, gather, scout (placeholders: they change no unit's behaviour yet; the AI commander and squad jobs will read them) and LZ (one per team, a new one replaces it). Over `OrderStats.max_markers` the oldest goes.
- **Group move (`Formation`):** a loose block around the clicked point, rows across the travel direction (group centre to the point), spaced by the largest unit diameter times `formation_spacing`. The units nearest the goal take the front row, sorted left to right in each row, so paths cross little.
- **Inhabit and leave:** `Order.inhabit(team, unit_id)` and `Order.leave(team)` take and free the team's seat (`PilotSeats`, `units.md`, "Inhabiting"). Refused for another team's unit, one that can't be inhabited, a second seat, or leaving with none. **An inhabited unit takes no other unit orders** (it is dropped from them like another team's unit; the rest of a group still goes).
- **Land:** `Order.land` sends flyers to a pad that takes them (airfields, mothership helipads and carryall pads); for the flown unit it toggles the seat autopilot (`airfield.md`).
- **The control channel:** the inhabited unit's controls are a stream, not orders. A `PilotInput` (team, unit id, world `aim` direction, `stick` axes, `air_brake`, `ability` held) goes every tick through `CommandIssuer.pilot()`, which accepts it only from the team seated in that unit and copies it, made safe, into the unit's `PilotBrain`. The last one received holds until the next. It doesn't emit `issued` or a probe event. The sender should run before the unit loop (`UnitRegistry` has physics priority -100) or its input lands a tick late.
- **`OrderQueue`** (each unit) is the plain list of its orders, the first active; the unit's `OrderBrain` works through it (`combat.md`, "Behaviour by order") and calls `finish()` when an order is done.

## Settled

## Tried and passed on

## Known issues
- Force-fire (Ctrl+click) isn't built.
- Formation slots that land on blocked ground snap to the nearest walkable cell, so two units can share a spot (the crowd arrival rule settles them).
