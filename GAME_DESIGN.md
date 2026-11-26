# GAME DESIGN (working outline)

**Optional reading.** Not needed at the start of a session; `CLAUDE.md` and `STATUS.md` are enough for coding work. Open this when discussing game design, level structure or progression. **This file holds decisions** (a few older sections still carry a marked leaning). Ideas being mulled over, parked ideas and open questions live in `docs/brainstorm.md`; lessons from other games in `docs/prior_art.md`. Design discussions update these docs every turn. No tunable values belong here (name the parameter, the value lives in `tuning/`).

_Last updated: 2026-11-26_

## Vision
A top-down 3D real-time strategy game built, to start with, along the lines of Red Alert 3 and C&C3: Tiberium Wars: their camera, their control scheme, army-and-base play.

## Decided
- **Reference games: Red Alert 3 and C&C3: Tiberium Wars.** When a detail isn't settled here, do what they do, and note it here once it's built.
- **Army and base scale** in the command views, not hero or squad play (first-person players lead at most a squad, below, "Roles").
- **Camera: free, in the RA3 / C&C3 style** (below).
- **Control scheme: the RA3 / C&C3 left-click scheme** (below).
- **Maps change during a match** (below): this rules out anything that assumes a fixed map.
- **Three views of one match** (below): the RTS view, a whole-map strategy view, and first-person in any unit.
- **Multiplayer is required** (below, "Multiplayer and simulation").
- **About 100 units at most in one battle** or one spot on the map. The whole map may hold more, spread out.
- **Pathing on our own grid** (below).
- **AI commanders are layered and hand-authored** (below). No LLM or learned layer: out of scope.
- **Single player can pause.** A slow-time control exists as a dev tool from the start, and may become a mechanic.
- **Setting: mothership warfare over islands** (below, "A typical match"). Battlefield 2142's Titan mode is a main inspiration.
- **Roles split command** between a strategist, company commanders and first-person players (below, "Roles").
- **Squads are the tactical unit** and **carryalls deliver them** (below, "Squads", "Carryalls").
- **Tilt-shift is part of the look** of the strategy view (below, "Views").
- **First-person flight is a main source of fun** (below, "Flight").
- **Every unit type has an ability on F** (below, "Unit abilities").
- **Player and AI parity** (below): a player is one unit with better decisions, not better information or stats.
- **Fog of war by detection:** sensor against signature, height and terrain (below, "Fog of war").
- **Night is the default on the atoll** (below, "Time of day").
- **Operations** are the commander's planning tool and the way first-person players join the action (below).
- **Airfields and the mothership's pads:** each team has one airfield (six helipads) on its island's plateau, near its mothership; the mothership has four carryall pads, one Explorer pad (the Explorer is built there) and six helipads (`docs/plans/match_flow.md`, steps 1 and 2).
- **Squads are command groups**, not a core mechanic (below, "Squads"); **a player leads their squad** with a ping wheel (below, "Roles").
- **Matches last about 30 minutes**, with room to come back (below, "Match pacing").

## A typical match (Decided unless marked)
The reference level is the battlefield level (`levels/atoll/`, built by `docs/plans/battlefield.md`): an atoll and islands in open sea, a mothership per side far out. The green island was its first draft.
- **Each side's main base is a hovering mothership**, standing off from the islands. Its distance sets how long reinforcements take to arrive, so map layout is mostly a question of travel times; the map size is picked on a scale reference level. Squads are produced aboard and flown in by carryall. It's where the commander "is".
- **Hovering** is mostly for the look now, but it's what later lets the mothership drop naval units onto the water, split off hovering forward bases, and relocate itself (as Titans do in BF2142). Its position is game state from the start.
- **No land link between mothership and island.** Everything reaches the island by air or sea, and so will the eventual mothership assault.
- **The mothership in each view:** a simple base object in the command views; a detailed, futuristic, multifunctional space in first person (air units launched from internal catapults, carryalls loading in hangars, ships dropped from below). The interior is a view: the simulation only knows where and when a unit appears.
- **Forward bases:** the mothership can detach two pieces of itself that fly quickly to a point on the map and become hovering forward bases, as huge as the mothership.
- **Scale is emphasised:** the mothership should look like it could host a whole force (within reason).
- **The island battle is over capture points** (radar arrays, launch platforms). Capturing one gives static defences and a forward spawn point.
- **Win condition (for now): tickets.** Holding points earns tickets; the first side to reach the target wins.
- **Later:** a mothership assault, in the style of Battlefield 2142's Titan mode (holding points lets you take the fight to the enemy mothership), possibly including infiltrating it in first person. So the mothership should become a unit with separate parts (hangars, production bays, carryall pads, forward-base pieces) that each have their own health, rather than one health bar.
- **Every unit can capture a point.** (Capture rules, zone and bubble are being worked out: `docs/brainstorm.md`.)
- **Maps will be joined by land** eventually (bridges, a new map, or naval ferries); the current atoll's two islands are not.
- **Snowballing is a known risk.** Points are not the economy (yet) for that reason, and the defences and forward spawn they give must not make a held point too hard to retake.

## Economy (Leaning: flat income, no harvesting)
- **Both sides get the same flat income per minute.** No resource harvesting and no economy micro. The skill is in how the income is spent: which units go into which squads, and later how much goes into forward bases, to suit the commander's strategy and the battlefield's needs. Think Clash Royale more than C&C.
- Open: a bank cap, and whether unspent income carries over.

## Squads (Decided: a command group; the rest is open, `docs/brainstorm.md`)
- **The unit is the core of the game; a squad is a command and control group** of separate units. In the RTS view each unit can still be micro'd on its own, or taken over in first person.
- **Shared engagement and awareness:** when one member detects or engages an enemy, the whole squad knows it and engages. (No lone unit fighting a tank formation because only one tank was in its range.)
- A squad usually has one job: scouting, patrol, guard duty, a hail-mary covert operation. A big battle over a control point is rarely just one squad. What else a squad is stays open: build nothing more on it yet.
- **Fully custom, with presets:** the commander composes a squad from unit types, or starts from a preset (fireteam, anti-air, motorized division, covert insertion, and so on). The rule is one squad per carryall; a less granular strategy may call for bigger single squads.
- Squads are produced on the mothership in several parallel production lines, paid from the income.
- Squads are also the natural unit the strategist hands to company commanders ("Roles") and the AI's squad layer ("Commander AI").

## Carryalls (Decided)
- **Big air transports** that carry squads from the mothership to the islands.
- **Cargo:** infantry slots and machinery slots (twice as many infantry slots as machinery ones; the counts are tunables). An IFV takes half the machinery slots, a tank-type unit all of them.
- **Deploy (F)** is how it sets its load down: it lands where it is, unloads and flies itself back to a mothership pad. A move order only moves it. Both it and the Explorer can use their deploy while flown in first person.
- **Para-drop** everything it carries anywhere; it **must land to pick units up**.
- **Two carried units can act as side gunners**, firing from the carryall.
- **A player can pilot it** (first person); otherwise an autopilot (not an AI infantry unit) carries out RTS-view orders.
- **Cargo is stored as data** (type, health, squad), not as units riding along; dropped or unloaded units come back as themselves.
- Open: whether its cargo dies when it's shot down, and whether units can be shot while descending.

## Roles (Decided: compartmentalized command)
In multiplayer one side can be several players, each in one role:
1. **Commander (strategist):** for now one commander runs both the strategy view and the RTS view. (Company commanders, a rank below who carry out single operations, are parked in `docs/brainstorm.md`.)
2. **First-person players:** may inhabit **any unit of their team** at any time, including on joining a match in progress. Most units are already carrying out an order (often an idle guard order, which few players will pick). An operations menu lists every running operation; a player joins any role in one, from the carryall pilot to the smallest ground unit.

**Player and AI parity (Decided).** Most seats in a match are AI, so:
- A player is one unit with **better decisions, not better information or stats**. Their edge is aim (an AI's accuracy falls off with range, a good player's doesn't), using cover, dodging, and improvising. No player-only information (no spotting key) and no player-only actions: everything a player can do, the unit's brain can do too, if worse.
- **Balance check:** a player-controlled unit always beats one AI unit of its type and usually doesn't beat two. An army that would win as AI also wins against players.
- Players shine where many decisions are taken on the fly: covert operations, flying, difficult micro taken off the commander's hands.
- **A whole match can be played with only AI units** and the commander loses no real feature.

**The game is unforgiving to lone players (Decided).** A rogue player can't do much outside the strategy: a jet flown alone into enemy territory gets shot down, a single infantry unit can't fight an army. The sandbox allows cool plays, but they come from playing inside the commander's strategy.

**Grunts (Decided):** the basic rifle infantry is called a **grunt** (the `trooper` type now). Bullet fodder, never meant to need a player.

**A player leads their squad (Decided).** A player inhabiting a unit in a squad becomes its squad leader and orders the other members with a **ping wheel** (in the style of Apex Legends' pings): middle mouse places a marker, dragging opens a wheel to pick the task (rally here, attack that, escort this, follow me). Pings are ordinary orders through `CommandIssuer`, limited to the player's own squad. Commanding a few grunts is what makes one player feel important on a big battlefield. A squad with no player has no squad leader orders: it follows the commander's orders (later a company commander's), as any AI squad does.

What this means for the build:
- **Every role can be a player or the AI.** The AI commander's layers line up with the roles (strategy layer, managers and squads, single unit brains), so empty roles and single player are covered by the same AI.
- **Ordering rights sit below the team:** a unit belongs to a team and is assigned to a controller (a player or an AI). `CommandIssuer`'s team check becomes "may this controller order this unit".

## Fog of war (Decided)
On a to-scale map information is crucial, so the fog is strict and scouting is a core job.
- **Detection:** every unit type has a **sensor** and a **signature**. An observer detects a target when its sensor against the target's signature covers the distance, with a clear line of sight over the heightmap; height helps the observer. Big units (tanks on a ridge, the Explorer) are seen from far, infantry only up close. Mountains and later trees are the hiding places.
- **The fog closes quickly** once nothing detects an area, so detection has to be kept up: scout and radar units and emplacements, scouting and patrol routes, a balance of scouts against fighting units. Regular ground units see little.
- **The Explorer sees a large area** (shown by its searchlights; carryalls get searchlights later).
- **Cloak:** some units are invisible to sight and found only by radar or a scan. **Firing breaks cloak.**
- **The commander has a short radar scan.**
- **Who knows what (awareness):** the commander sees the team's vision. A single unit knows only what it detects itself, plus what its squad knows, plus what the base it's linked to (a deployed Explorer, an outpost) detects. It reacts only to what it knows.
- **The first-person view draws what its unit knows**, the same as its AI twin would react to. No thick haze: undetected units simply aren't there, night hides the edges (dark shapes far away are plausibly unseen), and detection is quick to gain and slightly slower to lose, so units fade rather than pop.
- **Coverage shows on the map** (RTS and strategy views): unwatched ground is dimmed or tinted with a faint wireframe grid over the terrain, with line-of-sight shadows behind ridges.
- **Last known** (commander views only): big units, such as the Explorer and carryalls, leave a wireframe ghost of themselves where last seen. Other units' last-known positions show as a heatmap on the unwatched terrain. Heat and its crosses fade over about three minutes, ghosts over about a minute and a half; a mark clears early when its spot is revealed again with the unit gone, or when the unit is spotted elsewhere.
- **Bases see:** each team's airfields and motherships have sensors, and a deployed Explorer sees farther than a flying one. A unit is linked to a base (and shares its detection) while it is inside the base area.
- **No spotting and no "lights off" stance.** Sneaking is a choice of route, not a mechanic.

## Stances (Decided)
RTS-style stances decide what a unit does with what it knows (guard, hold ground, return fire, aggressive; the exact set follows RA3). Units stationed at an outpost are on guard: once the outpost detects an attacking force they take formation and fire, but don't leave it. The commander can still micro.

## Time of day (Decided)
Fixed per match and per map. **The atoll is a night map by default,** not a difficulty setting (moonlight, a blue sky with stars rather than black, no night vision). It needn't look entirely arcade-bright: units read plenty clearly, and a darker night gives lights something to stand out against. It asks for lighting design and many visible lights: searchlights, navigation lights on aircraft, base lights.
**Lamps:** aircraft wingtips are aviation's red (port) and green (starboard), with a white tail light and strobe; they show heading, not team, which the units already show plainly.
**The moon is low,** so the terrain casts long shadows that read from the bird's-eye view.
**Light never changes what anyone knows:** darkness, moon shadows and lamps neither hide nor reveal; only detection does.

## Operations (Decided)
The commander's tool for planned actions, and how first-person players find something worth doing.
- **An operation is an ordered list of phases**, each with markers and an order: go here, then proceed there, sneak round here, scout here, attack here. A richer version of RA3's queued (shift) orders.
- **Forces:** units already on the battlefield, assigned to it, or a **new strike team** launched from the mothership, which may include carryalls, jets and other units.
- **AI units carry it out**; first-person players join any role through the operations menu (above, "Roles").

## Match pacing (Decided)
- **Target match length: about 30 minutes**, longer between evenly matched commanders. Long enough that a side can bounce back, re-plan and win back momentum, rather than an early edge deciding the match; not so long that commanding becomes a chore.
- **A 30-second loop for every role** (after Halo's designers): each half-minute has a beat of action, a beat of repositioning or recovering, a change of tactic, and some downtime, so nothing is on full intensity all the time. Both the first-person and the commander's play are designed against it.
- **The commander delegates micro to the AI** (unit and squad behaviour), so their job is attention: hold the main front lines and, when nothing there is urgent, spend thirty seconds to a minute on an operation in the RTS view. One person can fill both the strategist and the company commander role.

## Changing maps (Decided)
Parts of the map can appear and disappear, walls can block the way, and elevation can change, all during a match.
- **Pathing must update locally and cheaply.** A change rebuilds only the area it touches, units whose path crosses it re-path, and nothing assumes a map baked once at load.
- **Terrain is game data, not a static mesh.** Height and passability live in a map model that the game changes, and the terrain mesh, collision and pathing all rebuild from it in chunks. This model is also what building placement and fog of war read.
- Units standing on ground that vanishes or rises need defined outcomes (fall, die, get pushed out); decide when the first such feature is built.

## Views (Decided: three views of one match)
In one match the commander switches freely between:
1. **RTS view:** the camera and controls below. A tactical, company-commander view, for micro.
2. **Strategy view (Decided): a live bird's-eye view** of the real map under a tilt-shift, for big-picture command and unit distribution (the war table model it replaces was dropped). Its HUD overlay builds squads, assigns landing zones, places map markers allies can see, and sets general strategy outlines (the guidelines, below).
3. **First-person:** inhabit any own unit on the map and control it directly.

What this means for the build:
- **The match is independent of any view.** Units, orders, pathing and combat run the same whatever is being watched. A view is just a camera, an input scheme and a HUD on top, and switching views never changes game state. Nothing in gameplay code may read the RTS camera.
- **One way to command.** Every view issues orders through the same `CommandIssuer` (the AI uses it too).
- **Units carry two levels of detail:** a strategy-view symbol and a full model that holds up at first-person distance.
- **An inhabited unit** swaps its order-following brain for player input and keeps everything else (stats, weapon, health, team). It still moves through the same world rules, so the movement code must also support direct control.
- The match keeps running in every view. **While the player is in first person, a friendly AI commander runs the rest of their army, following the guidelines (Leitlinien) the player set in the strategy view** (below, "Commander AI").

## Multiplayer and simulation (Decided: multiplayer; leaning: server-authoritative)
**Why most RTS games use lockstep:** every machine runs the identical simulation and only the players' orders are sent, so the network traffic doesn't grow with unit count (it was built for hundreds of units over dial-up), and replays are just the order log. The costs: the simulation must be bit-for-bit deterministic on every machine (no physics engine, careful floats, a fixed tick), every order waits out a delay before it runs, a single divergence (desync) breaks the game and is painful to debug, joining a game in progress is hard, and every client holds the full state, so map hacks are easy.

**Why server-authoritative fits us better:**
- **First-person mode needs it.** Lockstep's built-in delay feels fine for RTS clicks and terrible for direct control. Client-side prediction for the inhabited unit is a client-server technique.
- **About 100 units per battle** is small enough to sync state over a modern connection, especially when each client only receives what it can see (which also stops map hacks).
- **Physics and floats are fine:** only the server's simulation counts; clients interpolate what it sends.
- Godot's built-in multiplayer (RPCs, `MultiplayerSynchronizer`) is built around one authority, and the server can be a hosting player or a headless export.

**Rules from now on, even before networking exists:**
- The simulation (units, orders, pathing, combat, map changes) runs on a fixed tick in `_physics_process` and never reads views, cameras, the mouse or the HUD, so it can run headless on a server.
- Players and AI change the game only by sending **orders** (plain data) through `CommandIssuer`. Views send orders; they never touch units directly.
- Game state lives in a few plain values per unit and per map change, so it can be sent over the network and saved.
- Effects that are only for show (projectile trails, selection rings, death effects) sit apart from the simulation.
- **The unit simulation ticks at half the physics rate** (the inhabited unit and projectiles every tick), and views interpolate. Rules and reasons: `docs/performance.md`.

## Pathing (Decided: our own grid)
The map model holds a grid of cells (height, passability, cost). Single paths use the engine's `AStarGrid2D` (cells can be blocked and reweighted at runtime); big group moves to one point can use flow fields; units steer around each other locally. A map change updates its cells, and units whose path crosses them re-path. Not Godot's navmesh: it is baked, handles changing maps poorly, and would be a second map model to keep in sync. Later: unit sizes (clearance), and whether anything needs two levels (bridges over paths).
- **Flyers never pathfind:** they fly straight over the terrain.
- **Ground moves stay on their land mass.** A ground unit ordered to a point it can't reach by land (another island) ignores the order; amphibious units are the exception, and crossing water is the carryalls' job. Pathing is therefore always local to one island.
- **The strategy view rarely micro-manages:** it sets squads, landing zones and outlines; unit-level moves come from the RTS commander or the AI. Long searches across the whole map shouldn't exist.

## Commander AI (Decided: layered and hand-authored)
One AI commander design serves both the enemy and the player's own delegate while they're in first person.
- **Strategy layer:** chooses goals by scoring them (utility AI). For the friendly commander, the player's **guidelines (Leitlinien)** from the strategy view are its goals and limits.
- **Managers:** economy, production and army, turning goals into work.
- **Squads:** groups of units carrying out tactics (attack, defend, retreat) with simple state machines.
- **Influence maps:** threat and control grids built from the map grid, read by every layer.
- Orders only through `CommandIssuer`, like a player. Difficulty comes from reaction time and decision quality before resource cheats.

## Camera (Decided)
A perspective camera that orbits a focus point on the ground. Tunables: `CameraStats` (`tuning/camera_default.tres`).
- **Free rotation** around the focus point, with a reset back to `default_yaw` (north up). Because the view can turn, every model and building must read from all sides, and the minimap needs a view cone showing where the camera faces.
- **Wide zoom**, with the **pitch tied to the zoom**: flatter (`pitch_near`) when close, steeper (`pitch_far`) when far. Zoomed in is for watching the action; zoomed out is for commanding.
- **Pan** by keys, the screen edge and a held-button drag, faster when zoomed out (`pan_scales_with_zoom`). The focus point rides the ground height smoothly.
- **Jumps:** double-tapping a control group's number centres on it; a key jumps to the latest alert; clicking the minimap moves the camera there.
- **Lopsided view:** a tilted camera sees further up the screen than down it. Rotation lets the player fix that themselves, so maps don't need to work around it.

## Flight (Decided)
Build order: `docs/plans/flight.md`.
- **First-person flight is a main source of fun** and where many later mechanics live, so it gets real feel work.
- **Between Ace Combat and a sim:** arcade controls on our own simple aerodynamics (speed, angle of attack, lift, drag, gravity, stall). Planes can crash, though not easily: there's a learning curve.
- **Two models:** RTS and AI flyers fly a cheap, always-safe autopilot model on the air layer of the map; an inhabited flyer runs the full flight model. The full model's wider envelope is the reward for flying in person.
- **Always from the cockpit:** no chase camera. A dynamic helmet-style HUD (horizon, pitch ladder, flight path marker, angle of attack).
- **Controls:** the plane steers toward a mouse reticle (mouse aim); WASD is a secondary direct control; B is the air brake; no throttle for now. J inhabits the selected unit and leaves it.
- **All aircraft but carryalls** use the flight model. Carryalls are big flying ships with their own simpler controls.
- **Roster ideas:** a VTOL; a fast, fragile fighter whose prism ray links with a second fighter for a deadly strafing run; a VTOL that turns into artillery when landed.

## Unit abilities (Decided)
- **Every unit type has an ability, a gimmick, on F**, from the most basic infantry to the biggest units. It works on the selection in the RTS view and on the inhabited unit in first person. Design each unit type around it.

## Controls (Decided: the RA3 / C&C3 left-click scheme)
Left-click selects and right-click gives orders (the StarCraft scheme, changed from RA3 left-click orders); clicking empty ground clears the selection. RA3 and C&C3 also offered a right-click-orders scheme as an option; we may add that later as a setting.

| Input | Does |
|---|---|
| Left-click a unit | Select it (replaces the selection) |
| Left-drag | Box select own units |
| Shift + left-click / drag | Add to or remove from the selection |
| Double-click a unit | Select all own units of that type on screen |
| Left-click ground / enemy (with a selection) | Move there / attack it (the cursor shows which) |
| Right-click | Order: move, attack an enemy (attack-move when armed) |
| Right-hold + pull | RTS: fly the view toward the pull, faster the farther (C&C style). Strategy views: drag-pan the map |
| Middle-drag | Rotate the camera |
| Mouse wheel | Zoom |
| Arrow keys, screen edge | Pan |
| Ctrl + number / number / number twice | Make a control group / select it / centre the camera on it |
| Ctrl + left-click | Force-fire at a spot or unit |
| Alt + left-click | Queue a waypoint |
| Attack-move key, then left-click | Attack-move |
| Stop key | Stop |
| Space | Jump to the latest alert |
| Camera-reset key | Reset yaw and zoom |

The hotkeys in this table follow how we remember RA3 and C&C3; the exact keys and the less common ones (scatter, select all of a type across the map, reverse move, formation move) still need checking against those games' manuals before they're bound. Any key is just an Input Map action, so it's cheap to change.

**Production (leaning: the C&C model):** construction and unit production are queued from a sidebar, not by selecting the building, and new structures are placed near existing ones. This shapes the HUD layout, but it isn't part of the groundwork.

## Open questions and parked ideas
In `docs/brainstorm.md`.
