# Cockpit (first-person view)

The view of the unit the player inhabits. Design: `GAME_DESIGN.md` ("Flight", "Views"); build order: `docs/plans/flight.md`. The simulation side (seats, the control stream, who can be inhabited) is in `units.md`, "Inhabiting". Tunables: `CockpitStats` (`tuning/cockpit_default.tres`, Camera tab) and each type's `UnitStats.cockpit_offset`.

**Scripts:** `views/cockpit/cockpit_view.gd`, `pilot_controls.gd`, `cockpit_aim_mark.gd`; `views/view_switcher.gd` (`hand_over`, `take_back`), `views/view_transition.gd`; `units/unit_look.gd` (cockpit mount, hidden airframe). Built by `AtollLevel._build_war_table` (atoll only).

## How it works
- **View only.** `CockpitView` changes the game only through orders (`inhabit`, `leave`) and `CommandIssuer.pilot()`.
- **J (`inhabit`)** takes the one selected unit from the RTS or bird's-eye view, or leaves. It does nothing on the war table or during a V flight. More or fewer than one selected unit, or a refused order, plays the error cue.
- **Everything follows the seat signals,** so J, death and removal end the same way, and an order issued by anything else opens the view too. States: off, entering, in, leaving. J while leaving does nothing.
- **The switch** is its own `ViewTransition`, from an **anchor camera** (a still copy of whatever is on screen, with its environment) to the moving cockpit camera, or on the way out to the RTS camera. So it never snaps, from the bird's-eye view or when interrupted. Out lands in the RTS view centred on the ground under the unit, keeping the RTS yaw.
- **`ViewSwitcher.hand_over()`** turns every rig and `RtsPlayer` off, reports the view as RTS (the strategy controls close), ignores V and B until `take_back()`, and keeps the far sea up for the horizon. Camera, selection, control groups, orders and health bars are off with it; half-made gestures and an armed attack-move are dropped.
- **Camera:** at the unit's **cockpit mount** (`Unit.cockpit_mount()`, a node on the airframe at `cockpit_offset`), posed each frame from its interpolated transform, so it pitches and banks with the plane. The `Sfx` listener moves onto it. Its own airframe, plate, ring and height line are hidden from `hide_airframe_blend` on; the ground shadow stays as a height cue.
- **HUD:** `Hud.Mode.FLIGHT` shows `ui/hud/layouts/flight.tres`, which is empty until step 3c. The only mark is a placeholder ring at the aim (`CockpitAimMark`).
- **Controls (`PilotControls`):** the mouse is captured (freed while paused; `CameraInput` leaves a captured mouse alone) and its screen motion turns a world-direction **aim**, kept within `aim_max_off_nose` of the nose's heading and `aim_pitch_limit` of level. While **free look** is held it turns the head instead and the aim holds; on release the head eases back. A `PilotInput` goes out every physics tick.
- **Actions:** `inhabit` (J), `air_brake` (B, shared with the war table's key, which is ignored here), `free_look` (C or middle mouse), `unit_ability` (F), `pilot_pitch_up/down`, `pilot_roll_left/right` (WASD). Stick and ability are sent but do nothing yet.

## Settled

## Tried and passed on

## Known issues
- Placeholder flying ignores the aim's pitch: the ring moves up and down but the autopilot keeps its own height.
- There is no cockpit interior: the view is bare.
- A fixed wing aimed off the map is pinned against the edge (`units.md`).
- Leaving lands on the RTS rig's old ground height until its ground follow catches up (a small settle).
- Frame time in the cockpit isn't measured on the target machine; the view to the horizon draws far more than the RTS view's patch of ground.
