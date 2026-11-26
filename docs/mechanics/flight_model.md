# Flight model (first person)

How an inhabited flyer flies: two control types, **jet** and **hover**. Design: `GAME_DESIGN.md` ("Flight"); build order: `docs/plans/flight.md`. RTS and AI flyers use the autopilot instead (`units.md`, "Flyers"); the cockpit and the player's controls are in `cockpit.md`. Tunables, both on the Flight tab, one `.tres` per craft: jet `FlightStats` (`UnitStats.flight_model`), hover `HoverStats` (`UnitStats.hover_flight`; `tuning/hover_vtol.tres`, `hover_carryall.tres`, `hover_explorer.tres`).

**Scripts:** `units/pilot_model.gd` (what both share), `hover_model.gd`, `units/flight_model.gd` (jet), `flight_controls.gd`, `flight_steering.gd`, `flight_crash.gd`, `pilot_flight.gd`, `tuning/flight_mode_stats.gd`.

## How it works
- **Which type:** a unit with `hover_flight` starts in a hover (VTOL, carryall, Explorer); one without is a jet (fighter; no stats at all: `flight_default.tres`). A type with both can **switch** (the VTOL's F, `FlightModeStats`, `tuning/ability_flight_mode_vtol.tres`; only from the cockpit). Position, velocity and attitude carry over. A flight always starts in the hover.
- **Hover** (`HoverModel`): WASD asks for a speed over the ground relative to the heading (`strafe_share`, `reverse_share`), Space and Shift for a climb rate. Speed is gained at `acceleration` and shed at `braking` (keys let go or reversed), easing into the target by `settle`, so heavy craft drift further after W is let go. The mouse stick turns the heading (`yaw_rate`) and tilts the nose (`pitch_limit_deg`; flying forward stays level); `turn_response` is the weight of a turn. It leans into acceleration and banks into turns, on top of the steered attitude; the cockpit camera leans with it.
- **Hover contact** (`PilotFlight`): it can't go below `ground_gap` over the highest ground or sea across its footprint, so holding Shift sets it down. Ground, buildings and flyers met slower than `crash_speed` only stop it (it slides along solids; a rising face stops it); faster destroys it.
- **Jet transition** (`hover_speed` above 0, the VTOL): switching from a slow hover, the engine carries the weight (no stall, full control, the climb follows the nose, the air brake cuts thrust) and fades out from `hover_speed` to one and a half times it, of speed along the nose. Once past that it is over for good: it flies and stalls like any jet.
- **`PilotFlight`** (made by `UnitMovement.start_flight`, from `PilotSeats`) is the one piece that touches the unit. Each tick it steps the control type in use on the `PilotInput` (the jet through steering and `FlightControls`), puts the result on the unit and handles contact. Our own integration: no physics bodies.
- **Both models** are plain `PilotModel` state with no nodes and no world reads, so a server or client prediction can run them. Views read the shared part (position, velocity, basis, `stall_load()`, `hover_share()`, `top_speed()`, `neutral_aim()`) through `Unit.pilot_flight().model`, and the jet's extras through `.jet`.
- **The rest of this list is the jet** unless it says otherwise.
- **Thrust and drag:** fixed thrust along the nose. Drag from speed squared (set so level flight tops out at `cruise_speed`), from angle of attack (hard turns bleed speed), from the stall and from the air brake. Drag never reverses motion. Gravity pays for climbs and repays dives.
- **Lift:** speed squared times angle of attack; at the stall angle it holds the weight at `stall_speed`. The wing has an **incidence** (worked out from stall and cruise speed) so that at cruise the nose points along the flight path.
- **Stall:** past the stall angle lift falls to `post_stall_lift`, drag rises and the nose drops toward the flight path. Easing off recovers it. A tail slide swings the nose round the same way.
- **Handling:** turn rates follow the controls with a lag and weaken below `full_control_speed`. With the pitch let go, the airframe settles to the angle of attack that **holds its flight path** (a dive stays a dive). Sideslip swings the nose in, and `side_grip` turns drift back along the nose without losing speed.
- **Aim steering** (`FlightSteering.steer`): the bank is chosen from where the wing has to push, which is the wanted turn (`steer_turn_response`) plus holding the weight, so small corrections bank shallow and only hard turns go near the vertical. Far off the aim it pulls once rolled in; close to it pitch and rudder point the nose and the wings level by themselves. A little below the nose it pushes instead of rolling inverted. A hover turns flat. Controls ease off by the turn rate already there (`steer_damping`). The nose is held above the aim by the trim angle of attack, so the **flight path** follows the aim. It asks for whatever the aim needs, so a hard pull can stall a slow aircraft; with only a small correction left, it unloads a stalled wing so it recovers.
- **Stick** (`FlightSteering.fly_stick`): while any of WASD is held the aim is ignored: W/S pitch, A/D roll, no rudder, nothing levels the wings. What the view does with the aim meanwhile: `cockpit.md`.
- **Boost:** `FlightModel.thrust_boost` scales the thrust; `PilotFlight` copies it from the unit each tick, where a running ability sets it (`units.md`, "Abilities"), and uses the ability on a press of the pilot's key.
- **Attitude on screen:** the unit node still only yaws (picking, shapes), turning after the nose at a limited rate so loops don't flip it; the airframe node carries the whole rest of the orientation, and the cockpit mount with it.
- **Jet crashes** (`FlightCrash`; a hover uses its parts, see above): ground and sea (heights under the lowest point of a flattened-ball airframe and under the nose), buildings, props and walls (ball cast, World and Building layers), other flyers (both are destroyed). `Unit.crash(cause)` is the ordinary death, so the seat ends as for any death; the playtest log's `death` event gets `crash`. What already overlapped at takeover doesn't count until it has been left.
- **Hand-over:** in, the model starts from the autopilot's velocity and orientation. Out, `FlightAutopilot.take_over` gets the model's; the autopilot eases the climb or dive out and holds off its slow-to-climb braking for a moment.
- **Map edge:** positions are clamped and the outward velocity dropped.

## Measured
`PilotFlight.step` is about 36 µs a tick (headless, M1); only inhabited units run it. Headless checks: aim changes from 3 to 170 degrees settle on both types without leaving a 2 degree cone again (30 degrees in about 1.5 s, a reversal in 4 to 6 s); holds height at cruise (fighter and VTOL); a held pull stalls and aiming level recovers it; from top speed, letting go of W stops the VTOL, carryall and Explorer in order of weight; the VTOL switches to jet from a standstill and back without crashing; all three crash causes; neither hand-over jumps.

## Settled

## Tried and passed on
- Choosing the bank from the aim's direction alone, ignoring the weight: a 30 degree turn rolled past vertical.
- Lift with no wing incidence: the flight path sat below a level nose at cruise, so aiming at the horizon sank.

## Known issues
- The hover numbers have not had a feel pass.
- A hover slides along buildings by dropping one axis at a time, so it can feel sticky on a slanted face.
- An aim well below the nose rolls inverted and pulls through, losing a lot of height (`steer_push_angle_deg` sets from where).
- The gains have not had the feel pass yet.
- Crashes have no effects of their own beyond the unit's death burst.
- Pinned against the map edge while aimed off it.
- Flyers on autopilot don't avoid the inhabited one beyond the usual separation push.
