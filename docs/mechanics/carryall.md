# Carryalls

The flyer that carries a squad from the mothership to the map. Design: `GAME_DESIGN.md` ("Carryalls"). Build order: `docs/plans/battlefield.md` step 9. Tunables: `CarryallStats` (`tuning/carryall_default.tres`, Units tab), the usual flight group of `UnitStats` (`tuning/unit_carryall.tres`), `EconomyStats.takeoff_refund`.

**Scripts:** `units/carryall.gd` (the behaviour), `economy/carryall_fleet.gd` (the list), `tuning/carryall_stats.gd`; the pieces it plugs into: `units/landing.gd` and `bases/deck_airfield.gd` (its pads, `airfield.md`), `units/order_brain.gd` (`DELIVER`), `economy/production.gd`, `tuning/deploy_stats.gd` (`ability_deploy_carryall.tres`), `orders/order.gd` and `command_issuer.gd`.

## How it works
- **A carryall is a `Unit`** whose type has `UnitStats.carryall` (and a `cargo` hold); `Unit.carryall` is its `Carryall` (a `RefCounted` stepped from `Unit.think`). It's a flyer: on the autopilot it moves only in x and z at its cruise height (`flight_height`). It uses pads through the same `Landing` as fighters and VTOLs (`airfield.md`), on the mothership's four carryall pads only: left or right click on them, or H, from the RTS view or the cockpit.
- **Piloted** (hover controls, `flight_model.md`): flown freely in 3D. On or coming onto a pad, the autopilot takes it out first and then hands over. Taking the controls drops a delivery and marks squads already set down as deployed. The side gunners keep firing. After leaving, it hovers.
- **A squad's carryall:** when a squad's job reaches the front of a production line, `Production` asks `CarryallFleet.claim_on_pad`: an empty carryall idle on a pad is reused, else a new one (free) appears on a free pad; with neither, the job waits. The line then builds the squad's units one by one into its hold as `CargoEntry` data (with the squad id). State is `LOADING` meanwhile; then it sits on the pad as `IDLE` with its squad aboard.
- **Taking off interrupts the queue:** any order to a docked carryall makes it leave. If its line was still building, the job stops, the units built so far stay aboard as the squad, and `takeoff_refund` of the price of the units not built is paid back. The line moves on to its next job. Probe event `takeoff`. Cancelling a started job scraps the hold (refund `cancel_refund` of the whole price); the carryall stays empty on its pad. A carryall shot down mid-build takes the job with it.
- **Moving** is a plain move: it flies there and hovers, keeping its cargo.
- **Deploy (F, `DeployStats`):** lands where it is, unloads and returns to a pad. It's a `deliver` order at the spot under it that replaces the other orders. F works from the RTS view (every selected carryall that can) and from the cockpit; there the autopilot takes the seat, flies the whole thing with the player riding along, and H takes the controls back at any point. Refused (`Carryall.can_deploy`) with an empty hold, on a pad, while already delivering, or with no walkable ground within `deploy_reach`.
- **Deliver order** (`Order.deliver(team, ids, point)`, through `CommandIssuer`; refused for carryalls with an empty hold or a point with no land near): fly to the point (moved to walkable ground), descend to `landed_clearance`, put the units down one every `unload_interval` on a ring round the body (snapped to walkable cells, same ids as before for units that were live, health kept, joined to their squad through `SquadRegistry.attach`), wait `liftoff_delay`, climb to cruise, then fly back. Only the landing mode exists; `Order.DeliveryMode.PARADROP` falls back to it.
- **Return:** after unloading, the carryall appends its own `land` order (flagged `returning`) for the nearest own carryall pads with room, so queued waypoints are flown first. With all pads taken it waits at the holding point beyond the gates.
- **Strategy commands (10c-5):** the `CommandsModule` lists `CarryallFleet.snapshot` (id and state; a click selects the carryall). SET LZ places the LZ map marker (`orders.md`) and sends selected loaded carryalls a `deliver` there (the one order that delivers somewhere else). EXFIL NEAREST sends `closest_idle` (empty) to the selection's centre with a plain move order: it hovers there; loading units aboard (pick-up) and a real exfil are not built.
- **Starting carryalls:** `BattlefieldStats.test_carryalls` per team hover over their island (`carryalls_west` / `carryalls_east`) at load, full of troopers (`CarryallFleet.spawn_hovering`).
- **Side gunners:** the first `side_gunners` infantry in the hold with a weapon fire it at the nearest ground enemy in range (never at flyers), from the carryall's centre; no infantry aboard means no guns, and nothing fires while it is on or over a pad.
- **Lost carryall:** its cargo and aboard squad are gone (`SquadRegistry.disband`).

## Settled
- A squad rides exactly one carryall (a squad bigger than one hold is refused by `Production.queue`); `EconomyStats.squad_carryalls` is unused until that changes.
- Takeoff refund is of the unbuilt units only.

## Tried and passed on

## Known issues
- Not built: para-drop; picking units up again (landing on a landing zone, `Carryall` taking live units into the hold as data) and the exfil order that would use `closest_idle`; side-gunner mount points on the model (they fire from the centre); thruster and rotor sound. No AI sends carryalls yet, and there's no strategy view to read the list.
- A carryall set down by an Explorer (`explorer.md`) isn't in the `CarryallFleet` list; it still returns to the pads after a delivery.
- A landing next to cliffs isn't checked for room (the body is 14 m wide); only the point's cell must be walkable.
- Unchecked by eye: the landing to unload, and the cockpit deploy (headless tests only).
