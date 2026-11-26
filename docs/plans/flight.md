# Build plan: flying units, inhabiting, first-person flight

The order for making aircraft a core part of the game: flyers in the RTS view on an **air layer**, a **brain switch** that lets the player **inhabit** a selected unit (J), a **first-person flight model** with mouse-aim controls and a helmet-style flight HUD, and the **unit ability** key (F) every unit type gets. Design is in `GAME_DESIGN.md` ("Flight", "Unit abilities", "Views"); this file is only the build order. It follows `docs/plans/battlefield.md`.

**Work top to bottom, one step per branch and one session per step** (sub-steps like 1a and 1b are separate sessions), following `docs/performance.md` and the groundwork's rules: simulation apart from views, orders as the only way in, maps change, tunables in `tuning/`, a headless check per step, a hand-off for a playtest. Tick a step when it lands, update its mechanic doc and `STATUS.md`, and move `docs/plans/roadmap.md` on to the next step. Everything is built and tested on the battlefield level (`levels/atoll/`).

## Decided (details in `GAME_DESIGN.md`)
- **First-person flight is a main source of fun**, and the home of many later mechanics. Its feel gets the most iteration time.
- **The feel sits between Ace Combat and a sim:** arcade controls on top of our own simple aerodynamics (speed, angle of attack, lift, drag, gravity, stall). Planes can be crashed, though not easily: there's a learning curve.
- **Two flight models, one state.** RTS and AI flyers use a cheap, always-safe **autopilot model** on the air layer. Only an inhabited flyer runs the full **flight model**. Both share position, velocity and orientation, so the hand-over in either direction never jumps. The full model's wider envelope (tighter turns near the stall, flying low, precise runs) is the reward for flying in person.
- **Our own physics**, stepped on the simulation tick: no `RigidBody3D`, no Jolt, no addon. Deterministic, tunable in `FlightStats`, ready for server authority and client-side prediction.
- **First person means the cockpit, always.** No chase or trailing camera.
- **Controls:** the plane steers toward a mouse reticle (mouse aim, no yoke or stick simulation). WASD is a secondary direct control. **B** is the air brake. No throttle for now (fixed thrust per type). **J** inhabits the selected unit and leaves it again. **F** fires the unit's ability.
- **Every unit type has an F ability**, from basic infantry to the biggest units (`GAME_DESIGN.md`, "Unit abilities").
- **The flight model is for jets and VTOLs**, all aircraft except carryalls. Carryalls (big flying ships) get their own simpler hover-ship controls later.

## Still open (decide when the step comes up)
- **A crash in first person** (proposal: the unit is destroyed, a real loss, and the player drops back to the RTS view; an eject may come later).
- **Leaving the cockpit for another view** while inhabiting (V, B): allowed as a peek, or J first? (Built in step 2 as J first: V and B do nothing in first person.)
- **The army while the player is in first person:** the friendly AI commander isn't built. Until it is, the rest of the army keeps its last orders.
- **The WASD mapping** (built in 3b-1 as W/S pitch, A/D roll, with a pitch swap in the tuning panel): confirm in the feel pass, or move A/D to yaw.

## Key bindings to watch
- **B** is already `toggle_war_table`. The air brake is a new action `air_brake`, also on B; only the active view's controls read their actions, so the war table must ignore B while a unit is inhabited (and the flight controls ignore it otherwise).
- **WASD** pans the RTS camera; the camera's input is off while inhabiting.
- **J** and **F** are free. New actions: `inhabit`, `unit_ability`, `air_brake`, plus the pitch and roll actions for WASD and a free-look hold. Add them to the keybind page (`KeybindPage`).

## 1. Air layer (RTS flyers)
Flyers already exist (`units.md`, "Flyers"; carryalls in `carryall.md`): they hold a height over the ground and fly straight. This step makes the air a proper layer of the map for RTS play, still flat (x and z) in the RTS view. No 3D control yet.

### 1a. The layer in the simulation  [x]
- **An air layer in the map model:** flyers move on it, never pathfind, and are never refused for land regions or water (a move order over the sea is valid for a flyer). Map bounds still apply.
- **Cruise heights by type**, with the existing terrain following and minimum clearance; flyers of different heights don't separate from each other.
- **The autopilot model:** a cheap kinematic flight on the layer with a speed band and a turn rate (fixed-wing types fly arcs, can't stop, and orbit a point when idle; VTOL types slow, stop and hover). This is the "simple model" the full flight model hands over to and from later, so it keeps a real velocity and orientation.
- **Two test types** as `UnitStats` variants with placeholder models: a fighter (fast, fixed wing, fragile) and a VTOL (slower, hovers). Bank and pitch are shown on the model from the turn (look only).
- **Headless check:** flyers reach orders over land and sea, fighters orbit when idle, VTOLs stop, nothing is refused that should go through.

### 1b. Flyers in the RTS view  [x]
- **Picking flyers in the air:** clicks and box select hit the flyer's body at its height, and also its plate and ring on the ground.
- **Reading height:** a line from the flyer to its ground plate, and the ground shadow.
- **Orders:** move, attack, attack-move and stop for flyers; flyers attacking ground targets fly attack passes (fighters) or hover and fire (VTOLs). Order markers on the ground under the order point.
- **Selection panel and icons** for the two test types.
- **Done when:** a mixed selection of ground units and flyers handles naturally in the RTS view.

## 2. Inhabit: the brain switch (J)
Select one own unit in the RTS view (or the bird's-eye view) and press J to take it over; J again leaves it. Built first for flyers, but nothing in it is flyer-only.

### 2a. Simulation side  [x]
- **A control channel:** while inhabited, the unit's brain is a `PilotBrain` fed by a per-tick control state (aim point or direction, WASD axes, air brake, ability) from the player. It reaches the simulation the same way orders do (through `CommandIssuer`, team-checked), as a stream instead of one-off orders, so the server can own it later. Built as `PilotInput`, sent with `CommandIssuer.pilot()`, held by the unit's `PilotBrain`; seats in `PilotSeats` (`orders.md`, `units.md`, "Inhabiting").
- **Inhabit and leave** as orders (`Order.inhabit`, `Order.leave`); one inhabited unit per player; the unit runs at the full rate (`Unit.full_rate`) while inhabited; its queued orders are cleared on entry and the autopilot takes over on leave.
- **Death or crash while inhabited** ends it (the view is told by signal).
- **Placeholder flying:** in this step the inhabited flyer is still flown by the autopilot model, steered toward the control state's aim on the air layer, so step 2 can be tested before the flight model exists.
- **Headless check:** inhabit, steer, leave, inhabit a dying unit, refusal for enemy units.

### 2b. The first-person view  [x]
- **Cockpit camera** on a mount point per unit type (a node in the unit scene), at real eye height; mouse captured; a free-look hold.
- **The switch:** J flies the camera into the cockpit with a short transition (like `ViewTransition`), swaps the RTS input and HUD off and an empty flight HUD on, and back again on leave or death (to the RTS view, centred on where the unit was).
- **Input gating:** RTS camera, selection and order controls are off while inhabited; the war-table and bird's-eye keys do nothing (see "Still open").
- **Done when:** the player can jump in and out of either test flyer from the RTS view and steer it with the mouse.

## 3. First-person flight
The full flight model, the controls and the helmet HUD. The longest feel iteration in the plan: split as below, and split further if a sub-step runs long.

### 3a. Flight model  [x]
- **`FlightModel`** (simulation, our own integration on the tick) and **`FlightStats`** (`tuning/`, a Flight tab or a group on `UnitStats`; listed in `TuningPanel.TABS`). State: position, velocity, orientation, angular rates.
- **Aerodynamics, kept cheap:** fixed thrust per type; lift from speed squared and angle of attack up to a stall angle, falling off past it; drag growing with speed squared and with angle of attack (hard turns bleed speed); gravity (climbs cost speed, dives give it back); a soft, recoverable stall; sideslip pulled back toward the nose so it never feels slippery.
- **Air brake (B):** extra drag while held.
- **Crashes:** hitting the heightmap (a sample per tick against the airframe's lowest point), the water, props and buildings (a shape cast), or other flyers. A crash destroys the unit (see "Still open").
- **The hand-over** from the autopilot model on inhabit and back on leave, with the same state.
- **VTOL:** the same model with its own `FlightStats` (slower, more drag, no stall below a speed it hovers at through thrust). Its full hover mode is a later ability, not part of this step.
- **Headless check:** level flight holds height at cruise, a full pull-up stalls and recovers, a dive into terrain crashes, the hand-over keeps velocity.

### 3b-1. Controls  [x]
- **Mouse aim:** the mouse moves an aim reticle around the view sphere (independent of the nose); a controller turns pitch, roll and yaw to bring the nose onto it, limited by the model (it can stall the plane if asked to; that's the learning curve). Tunable gains per type.
- **WASD** as a secondary direct control that overrides the mouse while held (W/S pitch, A/D roll), and free look that holds the reticle.
- **A feel pass with the user** over the atoll. Expect several rounds.

### 3b-2. Cockpit feel  [x]
- Field of view widening with speed, a light camera shake with speed and in a stall, sound from `Sfx` (engine, wind, stall warning; the engine and wind loops need `Sfx` to run more than its one ambient loop, with live pitch and volume).
- **A feel pass with the user.**

### 3c. Flight HUD (helmet display)  [x]
A dynamic head-up display in the style of a real HUD or an F-35 helmet visor: thin lines in one HUD colour from `UiTokens`, drawn in screen space from projected 3D directions so the markings sit on the world.
- **Horizon line and pitch ladder**, rolling with the plane.
- **Flight path marker** (where the plane is actually going) and **boresight** (where the nose points); the gap between them shows the angle of attack.
- **Angle-of-attack indexer** with the stall angle marked, and a stall warning.
- **Mouse-aim reticle.**
- **Speed and altitude tapes, heading tape**, a ground-proximity warning (pull up), an air brake indicator.
- If it runs long: split into 3c-1 (horizon, ladder, markers, reticle) and 3c-2 (tapes and warnings).
- **Done when:** the user can fly by the HUD alone and reads a stall coming before it happens.

## 4. Unit abilities (F)
The framework only: the abilities themselves come with each unit type. Split in two sessions.

### 4a. Framework, cockpit F and the test ability  [x]
- **An ability per unit type:** `UnitStats.ability` names an `AbilityStats` resource (cooldown, charges, duration); a unit runs it as a part (`UnitAbility`).
- **Triggered by an order** (`Order.ability`, through `CommandIssuer`), and by F while inhabited (through the control channel).
- **A test ability** on the test fighter (`BoostStats`: a short boost).

### 4b. F in the RTS view and the HUD  [x]
- (F on the selection's main type in the RTS view landed early with the Explorer, `explorer.md`; the button and HUD remain.)
- F on the selection in the RTS view, and a command-grid button (built as a command cell in the selection panel; the empty command grid stays out of the layouts). Targeted abilities take a point or a unit after F, like attack-move (the targeting kind goes on `AbilityStats` when this is built).
- **Shown in the HUD:** ready, cooling down, charges, in the selection panel and in the flight HUD.
- **Done when:** F works from both views with cooldowns shown, and a new unit type adds an ability with a `.tres` and one script.

## After this plan
Candidates for the next plan, in no fixed order:
- **The aircraft roster and their abilities:** the fighter's prism ray that links with a second fighter into a strafing run (wingmen), the VTOL's hover mode, an artillery VTOL that lands and deploys as artillery.
- **First-person weapons** for aircraft (most weapons hit air in first person).
- **Wingmen:** an inhabited flyer leading an AI flight in formation.
- **Throttle**, more of the sim (energy, G-limits) if the feel pass asks for it.
- **The friendly AI commander** running the army while the player flies.
- **Inhabiting ground units** and carryalls (their own controls).
- **Client-side prediction** for the inhabited unit when networking starts.
