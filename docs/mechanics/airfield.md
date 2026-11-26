# Airfields and pads

Where fighters and VTOLs land to repair, on the island airfields and the mothership's helipads; carryalls use the mothership's own pads the same way. Design: `GAME_DESIGN.md` ("Airfields and the mothership's pads"). Build order: `docs/plans/match_flow.md` steps 1 and 2. Tunables: `AirfieldStats` (`tuning/airfield_default.tres`: repair, holding point, layout) and `PadStats` (`tuning/pad_default.tres`: landing and takeoff), both on the Units tab; where each airfield stands is `BattlefieldStats.airfield_west` / `airfield_east` (Map tab, read at level load).

**Scripts:** `bases/pad.gd`, `airfield.gd`, `deck_airfield.gd`, `airfield_look.gd`, `units/landing.gd`; the pieces it plugs into: `units/flight_autopilot.gd` (`set_vtol`, `hold`, `sink_rate`), `units/order_brain.gd` (`LAND`), `units/pilot_seats.gd` (autopilot), `orders/command_issuer.gd` and `order.gd`, `map/air_layer.gd` (platforms), `picking/ground_pick.gd` (`airfield_under`), `orders/order_control.gd`, `player/rts_player.gd`, `views/cockpit/hud/helmet_autopilot.gd`, `levels/atoll/atoll_level.gd`.

## How it works
- **`Pad`** is data: deck position, facing, hover point, and a reservation (one unit id). Its owner places it and hands it out. A pad up on a deck also has a **gate**.
- **`Airfield`** (group `airfields`, one per team on the atoll, `airfield_id` from 1): a deck standing `deck_lift` over the highest ground under it, six pads in two rows facing each other, a hangar behind each. `request_pad` is first come, first served; a craft with no pad keeps its place in the line. A unit that leaves the match is released. It can't be damaged.
- **Mothership pads (`DeckAirfield`, an `Airfield`):** per ship, one for the carryall pads (`for_carryalls`) and one for the helipads, on the model's `CarryallPad*` and `HeliPad*` markers (`MothershipStats`: counts, `gate_margin`, `pad_pick_margin`, and a `PadStats` for each, `tuning/pad_carryall.tres` and `pad_default.tres`). No platform, grid footprint or hangars. Each pad's gate is beyond the hull's atoll side at hover height: a craft climbs on the way to it (CLIMB_IN), slides in level over the deck, and after takeoff slides out to it (EXIT) before dropping. Placed at level load only. `Airfield.serves(unit)` says which craft a field takes; `Airfield.nearest_for` is the one "nearest with room" rule (land orders and a carryall's return).
- **Lights:** pads, decks and motherships carry lamps and light pools (`lamps.md`).
- **In the world** (ground airfields): the deck is a **platform** of the `AirLayer`, so autopilot, hover and jet flight, crashes and ground marks all treat it as ground. Its whole footprint is blocked on the map grid. Hangars are solid on the Building layer (a flown craft bumps them); the deck has no collision, and clicks find it by `ray_distance`.
- **Who can land:** every flyer but the Explorer (`Unit.landing`, a `Landing`; a newly built Explorer has one only to leave its mothership pad, `explorer.md`): carryalls on carryall pads, the rest on helipads.
- **`Order.land(team, ids, airfield_id)`:** with id 0 each unit gets the nearest own airfield with a pad to spare (spread over them within one order), else the nearest, to wait at. Enemy airfields and units that can't land are refused.
- **Landing (`Landing.Phase`):** WAITING over `Airfield.holding_point` while all pads are taken (fixed wings orbit it) → APPROACH → ALIGN (slides over the pad at the hover point) → DESCEND (fast, easing off at the deck) → DOWN. A fixed wing switches to hovering flight at its braking distance plus `wing_brake_margin` (`FlightAutopilot.set_vtol`) and back after takeoff.
- **On the pad:** repairs at `repair_rate`, holds its fire. The land order ends at full health (so a queued waypoint waits for the repair); it stays down with no orders, and Stop keeps it there. Any other order makes it take off first: straight up to the hover point, then the pad is free and the order starts. A new order on the way in drops the pad at once (from ALIGN on, after the climb).
- **RTS view:** with a flyer selected, a left or right click on an own airfield lands it (other selected units move to the click); `order_seek_airfield` (H) sends the selection to the nearest. Alt queues.
- **First person:** H sends `Order.land` for the flown unit, which toggles the **seat autopilot** (`PilotSeats.engage_autopilot` / `release_autopilot`): the unit flies by its orders while the seat stays the player's, and the helmet HUD shows only the autopilot's state, hull and the key. H again hands the controls back: at once in open flight, else after takeoff, and for the fighter once it has reached its minimum speed. Inhabiting a craft that is landing or on a pad goes through the same takeoff. Leaving (J) on autopilot lets it carry on.

## Measured
Headless on the atoll (`--fixed-fps 60`): reservation, six down with a seventh waiting and taking a freed pad, full repair, takeoff, and the cockpit hand-overs all pass.

## Settled

## Tried and passed on

## Known issues
- All craft land VTOL-style; no runways.
- A craft on a pad still counts as a flyer: only anti-air weapons can hit it.
- A pilot can set a hover craft on the deck by hand, but it doesn't repair or reserve a pad.
- A flyer on autopilot passes through hangars (it approaches from above them).
- A craft coming from under or behind the mothership climbs through the hull on its way to a gate (the autopilot ignores it), and a hand-flown one can hit it.
- The deck pads don't follow a mothership moved by live tuning.
- The airfields aren't on the minimap or bird's-eye view.
- Placeholder art. The layout and spot are read at level load only.
