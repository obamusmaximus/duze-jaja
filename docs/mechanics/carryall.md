# Carryalls

The flyer that carries a squad from the mothership to the map. Design: `GAME_DESIGN.md` ("Carryalls"). Build order: `docs/plans/battlefield.md` step 9. Tunables: `CarryallStats` (`tuning/carryall_default.tres`, Units tab), the usual flight group of `UnitStats` (`tuning/unit_carryall.tres`), `EconomyStats.takeoff_refund`.

**Scripts:** `units/carryall.gd` (the behaviour), `economy/carryall_fleet.gd` (the list), `tuning/carryall_stats.gd`; the pieces it plugs into: `units/order_brain.gd` (`DELIVER`), `economy/production.gd`, `bases/mothership.gd` (`pad_position`, `side_point`), `units/unit_movement.gd` (`altitude_override`), `orders/order.gd` and `command_issuer.gd`.

## How it works
- **A carryall is a `Unit`** whose type has `UnitStats.carryall` (and a `cargo` hold); `Unit.carryall` is its `Carryall` (a `RefCounted` stepped from `Unit.think`). It's a flyer: in the air it moves only in x and z at its cruise height (`flight_height`); flying it in 3D comes with first-person piloting, as a brain swap.
- **Comes free with a squad:** when a squad's job reaches the front of a production line, `Production` asks `CarryallFleet.spawn_on_pad` for a carryall on a free pad of the team's mothership (the job waits while all pads are taken, by carryalls that haven't left). The line then builds the squad's units one by one, each added to the hold as a `CargoEntry` (with its squad id) when it finishes. Carryall state is `LOADING` meanwhile; when the last unit is in, it sits on the pad as `IDLE` with its squad aboard.
- **Taking off interrupts the queue:** any order to a docked carryall makes it leave. If its line was still building, the job stops, the units built so far stay aboard as the squad, and `takeoff_refund` of the price of the units not built is paid back. The line moves on to its next job (with a new carryall). Probe event `takeoff`. Cancelling a started job scraps the hold (refund `cancel_refund` of the whole price); the carryall stays empty on its pad. A carryall shot down mid-build takes the job with it.
- **Leaving a pad:** the pad is on the deck, above cruise height, so the carryall first flies level to a point `exit_margin` beyond the hull's side (toward the atoll), then drops to cruise height. Same for every order. (Mechanism: `UnitMovement.altitude_override`, a fixed height that replaces the usual altitude; `OrderBrain` asks `Carryall.leave_velocity` until the carryall is clear.)
- **Strategy commands (10c-5):** the `CommandsModule` lists `CarryallFleet.snapshot` (id and state; a click selects the carryall). SET LZ places the LZ map marker (`orders.md`) and sends selected loaded carryalls to deliver there. EXFIL NEAREST sends `closest_idle` (empty) to the selection's centre with a plain move order: it hovers there; loading units aboard (pick-up) and a real exfil are not built.
- **Deliver order** (`Order.deliver(team, ids, point)`, through `CommandIssuer`; refused for carryalls with an empty hold or a point with no land near): fly to the point (moved to walkable ground), descend to `landed_clearance`, put the units down one every `unload_interval` on a ring round the body (snapped to walkable cells, same ids as before for units that were live, health kept, joined to their squad through `SquadRegistry.attach`), wait `liftoff_delay`, climb to cruise, then fly back. Only the landing mode exists; `Order.DeliveryMode.PARADROP` falls back to it.
- **Return:** after a delivery the carryall queues its own move to a point `home_margin` beside its mothership's hull and hovers there. It never lands on a pad on its own.
- **Players:** in the RTS view a move click with only loaded carryalls selected sends a `deliver`, anything else a move.
- **The list:** `CarryallFleet` (group `carryalls`) holds every carryall. `snapshot(team)` returns `{id, position, state}` per carryall (the coordinates are for the strategy view and the commander, never shown to the player); `closest_idle(team, point)` is the exfil pick (state `IDLE`, empty hold). States (`Carryall.State`): `IDLE`, `LOADING` (on a pad, being filled), `DELIVERING`, `RETURNING`, `FOLLOWING` (any other order). It's derived from the order queue, so nothing can get out of step.
- **Side gunners:** the first `side_gunners` infantry in the hold with a weapon fire it at the nearest ground enemy in range (never at flyers), from the carryall's centre; no infantry aboard means no guns, and nothing fires while it sits on the pad.
- **Lost carryall:** its cargo and aboard squad are gone (`SquadRegistry.disband`).

## Settled
- A squad rides exactly one carryall (a squad bigger than one hold is refused by `Production.queue`); `EconomyStats.squad_carryalls` is unused until that changes.
- Takeoff refund is of the unbuilt units only.

## Tried and passed on

## Known issues
- Not built: para-drop; picking units up again (landing on a landing zone, `Carryall` taking live units into the hold as data) and the exfil order that would use `closest_idle`; side-gunner mount points on the model (they fire from the centre); thruster and rotor sound. No AI sends carryalls yet, and there's no strategy view to read the list.
- A landing next to cliffs isn't checked for room (the body is 14 m wide); only the point's cell must be walkable.
- Unchecked by eye: the carryall on its pad, the exit and the landing in the running game (headless tests only).
